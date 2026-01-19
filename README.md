# Automated Observability Stack

![CI Status](https://github.com/madnoxx/automated-observability-stack/actions/workflows/ci.yml/badge.svg)

Полностью автоматизированное развертывание стека наблюдаемости (Observability) на базе **Grafana, Loki, Tempo, Prometheus** с использованием **Vagrant** и **Ansible**.

Проект демонстрирует подход **Infrastructure as Code (IaC)** для полного цикла мониторинга микросервисного приложения (HotROD), включая сбор метрик, логов и распределенных трассировок с полной корреляцией данных.

## Архитектура

Инфраструктура состоит из 4-х виртуальных машин, связанных приватной сетью:

| Хост | Роль | Компоненты | Описание |
| :--- | :--- | :--- | :--- |
| **mon01** | Monitoring Hub | Grafana, Loki, Tempo | Центральный узел визуализации и хранения логов/трейсов. |
| **prom01** | Time Series DB | Prometheus | Хранилище метрик. Настроен прием данных через **Remote Write**. |
| **app01** | Application Node | Docker, Nginx, Alloy | Запускает демо-приложение HotROD. Агент **Grafana Alloy** собирает телеметрию. |
| **ansible01** | Control Node | Ansible, Python | Управляющий узел для запуска плейбуков. |

## Ключевые особенности и решения

### 1. Безопасность и ACL
Вместо запуска агента сбора логов от `root` или отключения AppArmor, применена настройка **ACL (Access Control Lists)**.
*   Пользователю `alloy` выданы права `rx` на директории Docker и `r` на файлы JSON-логов.
*   Это позволяет собирать логи контейнеров без нарушения контура безопасности.

### 2. Универсальные Ansible Роли
Роль `startup_mon01` написана с использованием **гибридной логики**:
*   На реальных VM (Vagrant) она использует **Systemd** для управления сервисами.
*   В тестовой среде (Molecule/Docker) она автоматически переключается на **эмуляцию процессов** (nohup), так как в контейнерах отсутствует PID 1.
*   Это позволило покрыть инфраструктурный код автотестами Molecule.

### 3. Полная корреляция сигналов
Автоматически настроена связность данных в Grafana через Provisioning:
*   **Logs → Traces:** В логах (Loki) автоматически находятся TraceID, превращаясь в ссылки на Tempo.
*   **Traces → Logs:** В трейсах (Tempo) работает кнопка Logs, которая открывает логи конкретного запроса с учетом компенсации временных задержек (Time Shift).

### 4. Обход ограничений среды
Решены проблемы совместимости **Windows/Hyper-V/VirtualBox**:
*   Vagrant поднимает специальную ноду ansible01.
*   Весь деплой происходит внутри изолированного Linux-контура, исключая проблемы с путями, правами и SSH-ключами Windows.

## Запуск проекта

Этот проект поддерживает два режима развертывания: **Shell Scripts** и **Ansible**.

Для запуска вам понадобятся **VirtualBox** и **Vagrant**.

### Option A: Ansible
Этот метод использует Ansible для полной настройки, включая алертинг, дашборды и корреляцию логов.

1. Поднятие инфраструктуры
```bash
vagrant up
```
Vagrant создаст 4 виртуальные машины и настроит сеть.


2. Подготовка SSH ключей (Windows)

Так как Vagrant генерирует новые ключи при каждом создании машин, их необходимо передать на управляющий узел. Выполните эти команды в PowerShell из корня проекта:

```
copy .vagrant\machines\mon01\virtualbox\private_key monitoring-ansible\id_rsa_mon01
copy .vagrant\machines\prom01\virtualbox\private_key monitoring-ansible\id_rsa_prom01
copy .vagrant\machines\app01\virtualbox\private_key monitoring-ansible\id_rsa_app01
```

3. Настройка окружения на управляющем узле

Зайдите на машину ansible01 и обновите ключи (это необходимо для доступа Ansible к другим хостам):

```bash
vagrant ssh ansible01

# Внутри ansible01 выполняем:
cp /vagrant/monitoring-ansible/id_rsa_* ~/.ssh/
chmod 600 ~/.ssh/id_rsa_*
```

4. Запуск автоматизации (Ansible)

Внутри машины ansible01:
```bash
cd /vagrant/monitoring-ansible
ansible-playbook -i hosts.ini playbook.yml
```

### Option B: Shell Scripts
Этот метод разворачивает базовую инфраструктуру с помощью простых bash-скриптов.

1.  **Раскомментируйте скрипты в Vagrantfile:**

Откройте `Vagrantfile` и уберите комментарии со строк `provision "shell"`.

2.  **Запуск:**
```bash
vagrant up --provision
```
*Vagrant автоматически выполнит скрипты `provision/*.sh` при создании машин.*

## Доступ к сервисам
После успешного развертывания будут доступны следующие интерфейсы:

| Сервис | URL | Credentials | Описание |
|--------|-----|-------------|----------|
| **Grafana** | http://localhost:3000 | `admin` / `admin` | Визуализация и дашборды |
| **Prometheus** | http://localhost:9090 | - | Web UI метрик |
| **HotROD App** | http://localhost:8081 | - | Демо-приложение |

### Проверка работоспособности:
```bash
curl -s http://localhost:9090/-/healthy && echo "Prometheus OK"
curl -s http://localhost:3000/api/health && echo "Grafana OK"
```

## Тестирование и CI/CD

### Ручное тестирование (Molecule)

Роль startup_mon01 покрыта автоматическими тестами, которые проверяют корректность установки и запуска сервисов.

Запуск тестов внутри ansible01:
```bash
cd /vagrant/monitoring-ansible/roles/startup_mon01
molecule test
```

### CI Pipeline (GitHub Actions)

Проект использует GitHub Actions для непрерывной интеграции.
При каждом пуше в репозиторий запускается автоматизированный пайплайн, который:

1. Разворачивает чистое тестовое окружение (Ubuntu Latest + Docker).
2. Запускает Molecule тесты для роли startup_mon01.
3. Проверяет идемпотентность и доступность HTTP API сервисов (Loki, Tempo, Grafana).

Статус последнего билда можно увидеть по бейджу в заголовке README.

## Стек технологий
- IaC: Ansible (Roles, Jinja2 Templates).

- Virtualization: Vagrant.

- Visualization: Grafana (Provisioning).

- Logs: Loki (Docker and Systemd logs).

- Traces: Tempo.

- Metrics: Prometheus (Remote Write Receiver, Alerting Rules).
- 
- Agent: Grafana Alloy (OpenTelemetry Collector).

- App: Jaeger HotROD (Go microservices).

- Testing: Molecule, Docker, GitHub Actions.
