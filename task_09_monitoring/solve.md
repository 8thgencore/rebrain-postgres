# Блок: Мониторинг PostgreSQL

## 1. Установка PostgreSQL 13
```bash
# Добавление репозитория PostgreSQL
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Обновление и установка
sudo apt update
sudo apt install -y postgresql-13
```

## 2. Добавление пользователя root
```bash
sudo -u postgres psql -c "CREATE USER root WITH SUPERUSER PASSWORD 'root_password';"
```

## 3. Подключение пользователем root
```bash
psql -U root -d postgres -h localhost
```

## 4. Создание базы данных
```bash
sudo -u postgres psql -c "CREATE DATABASE rebrain_courses_db;"
```

## 5. Создание пользователя rebrain_admin
```bash
sudo -u postgres psql -c "CREATE USER rebrain_admin WITH PASSWORD 'admin_password';"
```

## 6. Выдача прав rebrain_admin
```bash
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE rebrain_courses_db TO rebrain_admin;"
```

## 7. Установка prometheus-server
```bash
# Скачивание и установка Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.55.1/prometheus-2.55.1.linux-amd64.tar.gz
tar xvf prometheus-2.55.1.linux-amd64.tar.gz

# Создание пользователя и директорий
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Копирование файлов
sudo cp prometheus-2.55.1.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.55.1.linux-amd64/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

# Создание systemd сервиса
sudo tee /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Запуск сервиса
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

# Проверка статуса и порта
sudo systemctl status prometheus
ss -tunlp | grep 9090
```

Настройка конфигурации для self-monitoring
```bash
sudo nano /etc/prometheus/prometheus.yml
```

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

```bash
sudo systemctl restart prometheus
```

## 8. Установка node_exporter
```bash
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xvf node_exporter-1.8.2.linux-amd64.tar.gz
sudo cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin
sudo useradd --no-create-home --shell /bin/false node_exporter
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Создание systemd сервиса
sudo tee /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Проверка статуса и порта
sudo systemctl status node_exporter
ss -tunlp | grep 9100
```

## 9. Настройка источника данных для prometheus
```bash
sudo nano /etc/prometheus/prometheus.yml
```

Добавление источника данных
```yaml
scrape_configs:
  ...
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
```

```bash
sudo systemctl restart prometheus
```

## 10. Установка Grafana
```bash
# Установка зависимостей
sudo apt-get install -y adduser libfontconfig1 musl

# Скачивание и установка
wget https://dl.grafana.com/oss/release/grafana_11.4.0_amd64.deb
sudo dpkg -i grafana_11.4.0_amd64.deb

# Запуск сервиса
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Проверка статуса и порта
sudo systemctl status grafana-server
ss -tunlp | grep 3000
```

## 11. Подключение prometheus к Grafana
1. Откройте Grafana (http://localhost:3000)
2. Войдите с credentials admin/admin
3. Перейдите в Connections -> Data Sources
4. Добавьте Prometheus как источник данных:
   - URL: http://localhost:9090
   - Save & Test

## 12. Импорт Dashboard 1860
1. В Grafana перейдите в Dashboards -> Import
2. Введите ID 1860
3. Выберите Prometheus как источник данных
4. Нажмите Import

## 13. Проверка node_exporter
1. Откройте импортированный dashboard
2. Убедитесь, что все метрики отображаются корректно
3. Проверьте основные показатели системы

## 14. Установка postgres_exporter
```bash
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v0.16.0/postgres_exporter-0.16.0.linux-amd64.tar.gz
tar xvf postgres_exporter-0.16.0.linux-amd64.tar.gz
sudo cp postgres_exporter-0.16.0.linux-amd64/postgres_exporter /usr/local/bin
sudo useradd --no-create-home --shell /bin/false postgres_exporter
sudo chown postgres_exporter:postgres_exporter /usr/local/bin/postgres_exporter

# Создание systemd сервиса
sudo tee /etc/systemd/system/prometheus-postgres-exporter.service << EOF
[Unit]
Description=Prometheus Postgres Exporter
After=network.target

[Service]
User=postgres_exporter
Group=postgres_exporter
Type=simple
ExecStart=/usr/local/bin/postgres_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start prometheus-postgres-exporter
sudo systemctl enable prometheus-postgres-exporter

# Проверка статуса и порта
sudo systemctl status prometheus-postgres-exporter
ss -tunlp | grep 9187
```

Настройка prometheus
```bash
sudo nano /etc/prometheus/prometheus.yml
```

Добавление источника данных
```yaml
scrape_configs:
  ...
  - job_name: 'postgres_exporter'
    static_configs:
      - targets: ['localhost:9187']
```

```bash
sudo systemctl restart prometheus
```

## 15. Добавление пользователя rebrain_monitoring
```bash
sudo -u postgres psql -c "CREATE USER rebrain_monitoring WITH SUPERUSER PASSWORD 'monitoring_password';"
```

## 16. Настройка окружения для postgres_exporter
```bash
sudo nano /etc/default/prometheus-postgres-exporter
```

```bash
DATA_SOURCE_NAME="postgresql://rebrain_monitoring:monitoring_password@localhost:5432/rebrain_courses_db?sslmode=disable"
```

```bash
sudo systemctl restart prometheus-postgres-exporter
```

## 17. Импорт Dashboard 9628
1. В Grafana перейдите в Dashboards -> Import
2. Введите ID 9628
3. Выберите Prometheus как источник данных
4. Нажмите Import

## 18. Проверка postgres_exporter
1. Откройте dashboard 9628
2. Убедитесь, что все метрики PostgreSQL отображаются корректно

## 19. Инициализация pgbench
```bash
sudo apt install -y postgresql-client-common postgresql-client-13 postgresql-contrib
```

```bash
pgbench -i -U rebrain_monitoring -h localhost -d rebrain_courses_db
```

## 20. Проведение нагрузочного теста
```bash
pgbench -U rebrain_monitoring -h localhost -d rebrain_courses_db -c 50 -j 5 -T 120 -q
```

## 21. Анализ графиков
1. Откройте оба dashboard (1860 и 9628)
2. Проанализируйте изменения метрик во время нагрузочного теста
3. Убедитесь, что нагрузочный тест отражается на графиках
4. Проверьте основные показатели производительности PostgreSQL 
