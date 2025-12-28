# Automated Observability Stack

Полностью автоматизированное развертывание стека наблюдаемости (Observability) на базе **Grafana, Loki, Tempo, Prometheus** с использованием **Vagrant** и **Ansible**.

Проект демонстрирует подход **Infrastructure as Code (IaC)** для мониторинга микросервисного приложения (HotROD), включая сбор метрик, логов и распределенных трассировок с полной корреляцией данных.

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
Вместо запуска агента сбора логов от `root` или отключения AppArmor, реализовано гранулярное управление правами через **ACL (Access Control Lists)**.
*   Пользователю `alloy` выданы права `rx` на директории Docker и `r` на файлы JSON-логов.
*   Это позволяет собирать логи контейнеров без нарушения контура безопасности.

### 2. Универсальные Ansible Роли
Роль `startup_mon01` написана с использованием **гибридной логики**:
*   На реальных VM (Vagrant) она использует **Systemd** для управления сервисами.
*   В тестовой среде (Molecule/Docker) она автоматически переключается на **эмуляцию процессов**, так как в контейнерах отсутствует PID 1.

### 3. Полная корреляция сигналов
Автоматически настроена связность данных в Grafana через Provisioning:
*   **Logs → Traces:** Логи Loki парсятся на лету, ID трассировки превращаются в ссылки на Tempo.
*   **Traces → Logs:** В Tempo настроен поиск логов по Trace ID с учетом **Time Shift** (компенсация задержки буферизации).

### 4. Обход ограничений среды
Решены проблемы совместимости **Windows/Hyper-V/VirtualBox**:
*   Использован паттерн "Bastion Host" (ansible01) для запуска автоматизации внутри Linux-контура.
*   Настроена уникальная схема проброса портов SSH для избежания конфликтов.

## Запуск проекта

Для запуска вам понадобятся **VirtualBox** и **Vagrant**.

### 1. Поднятие инфраструктуры
```bash
vagrant up
```
Vagrant создаст 4 виртуальные машины и настроит сеть.

### 2. Подключение к управляющему узлу
```bash
vagrant ssh ansible01
```

### 3. Запуск автоматизации (Ansible)
Внутри машины ansible01:
```bash
cd /vagrant/monitoring-ansible
ansible-playbook -i hosts.ini playbook.yml
```

### 4. Доступ к сервисам
После успешного развертывания будут доступны следующие интерфейсы:

| Сервис | URL | Credentials | Описание |
|--------|-----|-------------|----------|
| **Grafana** | http://localhost:3000 | `admin` / `admin` | Визуализация и дашборды |
| **Prometheus** | http://localhost:9090 | - | Web UI метрик |
| **HotROD App** | http://localhost:8081 | - | Демо-приложение |

#### Проверка работоспособности:
```bash
curl -s http://localhost:9090/-/healthy && echo "Prometheus OK"
curl -s http://localhost:3000/api/health && echo "Grafana OK"
```

### Тестирование (Molecule)

Роль startup_mon01 покрыта автоматическими тестами.

Внутри ansible01:
```bash
cd /vagrant/monitoring-ansible/roles/startup_mon01
molecule test
```

Тесты поднимают Docker-контейнер, разворачивают роль и проверяют доступность HTTP API сервисов.

## Стек технологий
- IaC: Ansible (Roles, Jinja2 Templates), Vagrant.

- Monitoring: Grafana, Prometheus (Alerting Rules), Loki, Tempo.

- Agent: Grafana Alloy (OpenTelemetry Collector).

- App: Jaeger HotROD (Go microservices).

- Testing: Molecule, Docker.
