#!/bin/bash
echo ">>> Installing Utilities..."
apt-get update && apt-get install -y unzip wget curl software-properties-common

echo ">>> Installing Grafana..."
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
apt-get update && apt-get install -y grafana
systemctl enable --now grafana-server

echo ">>> Installing Loki..."
LOKI_VERSION="3.6.2"
wget -q https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
mv loki-linux-amd64 /usr/local/bin/loki
chmod a+x /usr/local/bin/loki

mkdir -p /etc/loki
cat <<EOF > /etc/loki/config.yaml
auth_enabled: false

limits_config:
  allow_structured_metadata: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9097
common:
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory
schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h
EOF

cat <<EOF > /etc/systemd/system/loki.service
[Unit]
Description=Loki service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/loki -config.file /etc/loki/config.yaml

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now loki

echo ">>> Installing Tempo..."
TEMPO_VERSION="2.9.0"
wget -q https://github.com/grafana/tempo/releases/download/v${TEMPO_VERSION}/tempo_${TEMPO_VERSION}_linux_amd64.tar.gz
tar -xzf tempo_${TEMPO_VERSION}_linux_amd64.tar.gz
mv tempo /usr/local/bin/tempo
chmod a+x /usr/local/bin/tempo

mkdir -p /etc/tempo
cat <<EOF > /etc/tempo/config.yaml
server:
  http_listen_port: 3200

distributor:
  receivers:
    jaeger:
      protocols:
        thrift_http:
        grpc:
        thrift_binary:
        thrift_compact:
    otlp:
      protocols:
        http:
        grpc:

ingester:
  trace_idle_period: 10s
  max_block_bytes: 1_000_000
  max_block_duration: 5m

compactor:
  compaction:
    compaction_window: 1h
    max_block_bytes: 100_000_000
    block_retention: 1h
    compacted_block_retention: 10m

storage:
  trace:
    backend: local
    local:
      path: /tmp/tempo/blocks
    wal:
      path: /tmp/tempo/wal
EOF

cat <<EOF > /etc/systemd/system/tempo.service
[Unit]
Description=Tempo service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/tempo -config.file /etc/tempo/config.yaml

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now tempo