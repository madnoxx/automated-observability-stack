#!/bin/bash

echo ">>> Installing Docker & Nginx..."
apt update
apt install -y docker.io nginx

systemctl enable --now docker
usermod -aG docker vagrant

docker stop hotrod || true
docker rm hotrod || true

docker run -d --name hotrod \
  -p 8080:8080 \
  -e OTEL_EXPORTER_OTLP_ENDPOINT="http://192.168.56.12:4318" \
  jaegertracing/example-hotrod:latest

echo ">>> Configuring Nginx..."
rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/hotrod <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

ln -sf /etc/nginx/sites-available/hotrod /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx