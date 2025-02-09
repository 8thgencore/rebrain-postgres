# Финальное задание: Отказоустойчивый кластер PostgreSQL

## 1. Подготовка серверов

### 1.1 Настройка hostname и /etc/hosts

```bash
# PostgreSQL nodes
hostnamectl set-hostname pg-node-1 --static  # Leader
hostnamectl set-hostname pg-node-2 --static  # Sync replica
hostnamectl set-hostname pg-node-3 --static  # Async replica
hostnamectl set-hostname pg-node-4 --static  # Reserved replica

# ETCD nodes
hostnamectl set-hostname etcd-node-1 --static
hostnamectl set-hostname etcd-node-2 --static
hostnamectl set-hostname etcd-node-3 --static

# HAProxy
hostnamectl set-hostname haproxy --static

# PgBouncer nodes
hostnamectl set-hostname pgbouncer-1 --static
hostnamectl set-hostname pgbouncer-2 --static
```

На всех серверах добавить в /etc/hosts:
```bash
tee -a /etc/hosts << EOF
# PostgreSQL nodes
10.129.0.11 pg-node-1
10.129.0.12 pg-node-2
10.129.0.13 pg-node-3
10.129.0.14 pg-node-4

# ETCD nodes
10.129.0.21 etcd-node-1
10.129.0.22 etcd-node-2
10.129.0.23 etcd-node-3

# HAProxy
10.129.0.30 haproxy

# PgBouncer nodes
10.129.0.41 pgbouncer-1
10.129.0.42 pgbouncer-2
EOF
```

## 2. Настройка ETCD кластера

На каждом ETCD сервере:

```bash
# Установка ETCD
mkdir -p /task
chmod -R 777 /task/
wget https://github.com/etcd-io/etcd/releases/download/v3.5.18/etcd-v3.5.18-linux-amd64.tar.gz
tar xvf etcd-v3.5.18-linux-amd64.tar.gz
cp etcd-v3.5.18-linux-amd64/etcd* /usr/local/bin/
```

#### Конфигурация ETCD
[etcd.yml](etcd.yml)
```bash
nano /etc/etcd/etcd.yml
```

```bash
# Создание пользователя и группы
useradd -r -s /sbin/nologin etcd
mkdir -p /task/etcd/{data-dir,wal-dir}
chown -R etcd:etcd /task/etcd/
chown -R etcd:etcd /etc/etcd/

# Создание systemd сервиса
tee -a /etc/systemd/system/etcd.service << EOF
[Unit] 
Description=etcd key-value store 
Documentation=https://github.com/coreos/etcd 
After=network.target 
 
[Service] 
User=etcd 
Type=notify 
ExecStart=etcd --config-file /etc/etcd/etcd.yml
Restart=always
RestartSec=10s 
LimitNOFILE=40000 

[Install] 
WantedBy=multi-user.target
EOF

# Запуск сервиса
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
```

```bash
# Проверка статуса кластера
etcdctl endpoint status --write-out=table
etcdctl endpoint health --write-out=table
etcdctl member list --write-out=table
```

## 3. Настройка PostgreSQL и Patroni

На каждом PostgreSQL сервере:

```bash
# Установка PostgreSQL
sudo apt update
sudo apt install -y postgresql

# Остановка и отключение стандартного сервиса
sudo systemctl stop postgresql
sudo systemctl disable postgresql

# Создание директории pgpass и настройка прав
mkdir -p /var/lib/postgresql
touch /var/lib/postgresql/pgpass
chown postgres:postgres /var/lib/postgresql/pgpass
chmod 600 /var/lib/postgresql/pgpass

# Установка Patroni
sudo apt install -y python3-pip python3-dev libpq-dev
pip3 install --upgrade pip
pip3 install psycopg2-binary
pip3 install patroni[etcd]

# Создание и настройка прав на директории
mkdir -p /task/patroni/pgdata /etc/patroni
mkdir -p /task/patroni/wal_archive
mkdir -p /var/log/postgresql
mkdir -p /var/run/postgresql

# Установка правильного владельца
chown -R postgres:postgres /task
chown -R postgres:postgres /etc/patroni
chown postgres:postgres /var/log/postgresql
chown postgres:postgres /var/run/postgresql

# Установка правильных прав
chmod 700 /task/patroni/pgdata
chmod 700 /task/patroni/wal_archive
chmod 600 /etc/patroni/patroni.yml

# Копирование конфигурации
nano /etc/patroni/patroni.yml

# Для каждой ноды нужно раскомментировать соответствующие теги
# и изменить параметры name, connect_address в конфигурации

#### Конфигурация Patroni  
[patroni.yml](patroni.yml)

```bash
# Создание systemd сервиса
sudo tee /etc/systemd/system/patroni.service << EOF
[Unit]
Description=Patroni needs to orchestrate a high-availability PostgreSQL
Documentation=https://patroni.readthedocs.io/en/latest/
After=syslog.target network.target

[Service]
User=postgres
Group=postgres
Type=simple
ExecStart=/usr/local/bin/patroni /etc/patroni/patroni.yml
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

# Запуск сервиса
systemctl daemon-reload
systemctl enable patroni
systemctl restart patroni
```

```bash
# Проверка статуса кластера
patronictl -c /etc/patroni/patroni.yml list
```

```bash
# Создание базы данных и пользователя
sudo -u postgres psql -h localhost -c "CREATE DATABASE rebrain_courses_db;"
sudo -u postgres psql -h localhost -c "CREATE USER rebrain_admin WITH PASSWORD 'rebrain_admin_password';"
sudo -u postgres psql -h localhost -c "GRANT ALL PRIVILEGES ON DATABASE rebrain_courses_db TO rebrain_admin;"
```

## 4. Настройка PgBouncer

На обоих серверах pgbouncer:

```bash
# Установка
sudo apt install -y pgbouncer postgresql-client

# Пользователи для PgBouncer
sudo bash -c 'echo "\"rebrain_admin\" \"md5$(echo -n "rebrain_admin_password" | md5sum | cut -d" " -f1)\"" >> /etc/pgbouncer/userlist.txt'

# Конфигурация
nano /etc/pgbouncer/pgbouncer.ini

# Создание необходимых директорий
sudo mkdir -p /var/log/postgresql
sudo mkdir -p /var/run/postgresql

# Установка правильных прав
sudo chown -R postgres:postgres /var/log/postgresql
sudo chown -R postgres:postgres /var/run/postgresql
sudo chown -R postgres:postgres /etc/pgbouncer
sudo chmod 755 /etc/pgbouncer
sudo chmod 644 /etc/pgbouncer/pgbouncer.ini
sudo chmod 640 /etc/pgbouncer/userlist.txt

# Перезапуск сервиса
sudo systemctl restart pgbouncer

# Просмотр логов
sudo tail -f /var/log/postgresql/pgbouncer.log

# Проверка подключения через pgbouncer
PGPASSWORD=rebrain_admin_password psql -U rebrain_admin -h localhost -p 6432 -d rebrain_courses_db -c "\conninfo"
```

## 5. Настройка HAProxy

```bash
# Установка
sudo apt install -y haproxy
```

#### Конфигурация
[haproxy.cfg](haproxy.cfg)

```bash
# Запуск HAProxy
systemctl enable haproxy
systemctl restart haproxy

# Проверка подключения через HAProxy
psql -h haproxy -d postgres -U rebrain_admin -W -c "select inet_server_addr();"
```

## 6. Настройка мониторинга

На сервере HAProxy:

```bash
# Установка Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.49.1/prometheus-2.49.1.linux-amd64.tar.gz
tar xvf prometheus-2.49.1.linux-amd64.tar.gz

# Создание пользователя и директорий
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Копирование файлов
sudo cp prometheus-2.49.1.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.49.1.linux-amd64/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
```     

#### Конфигурация
[prometheus.yml](prometheus.yml)

```bash
# Конфигурация Prometheus
nano /etc/prometheus/prometheus.yml

# Создание systemd сервиса для Prometheus
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

# Запуск Prometheus
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
```

#### Установка node_exporter
```bash
# Установка node_exporter на всех серверах
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xvf node_exporter-1.8.2.linux-amd64.tar.gz
sudo cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin
sudo useradd --no-create-home --shell /bin/false node_exporter
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Создание systemd сервиса для node_exporter
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
```

#### Установка postgres_exporter
```bash
# Установка postgres_exporter на PostgreSQL серверах
cd /tmp
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v0.16.0/postgres_exporter-0.16.0.linux-amd64.tar.gz
tar xvf postgres_exporter-0.16.0.linux-amd64.tar.gz
sudo cp postgres_exporter-0.16.0.linux-amd64/postgres_exporter /usr/local/bin
sudo useradd --no-create-home --shell /bin/false postgres_exporter
sudo chown postgres_exporter:postgres_exporter /usr/local/bin/postgres_exporter

# Создание пользователя для мониторинга в PostgreSQL
sudo -u postgres psql -h localhost -c "CREATE USER rebrain_monitoring WITH SUPERUSER PASSWORD 'monitoring_password';"

# Настройка окружения для postgres_exporter
sudo tee /etc/default/prometheus-postgres-exporter << EOF
DATA_SOURCE_NAME="postgresql://rebrain_monitoring:monitoring_password@localhost:5432/postgres?sslmode=disable"
EOF

# Создание systemd сервиса для postgres_exporter
sudo tee /etc/systemd/system/prometheus-postgres-exporter.service << EOF
[Unit]
Description=Prometheus Postgres Exporter
After=network.target

[Service]
User=postgres_exporter
Group=postgres_exporter
Type=simple
EnvironmentFile=/etc/default/prometheus-postgres-exporter
ExecStart=/usr/local/bin/postgres_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start prometheus-postgres-exporter
sudo systemctl enable prometheus-postgres-exporter
```

#### Установка Grafana
```bash
# Установка Grafana
sudo apt-get install -y adduser libfontconfig1 musl
wget https://dl.grafana.com/oss/release/grafana_10.4.0_amd64.deb
sudo dpkg -i grafana_10.4.0_amd64.deb

# Запуск Grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

### Настройка Grafana

1. Откройте Grafana (http://haproxy:3000)
2. Войдите с credentials admin/admin
3. Добавьте Prometheus как источник данных:
   - URL: http://localhost:9090
   - Save & Test

4. Импортируйте дашборды:
   - Node Exporter Full (ID: 1860)
   - PostgreSQL Database (ID: 9628)
   - HAProxy Servers (ID: 12693)

### Метрики для мониторинга

1. Системные метрики (node_exporter):
   - CPU, RAM, Disk I/O
   - Network traffic
   - System load

2. PostgreSQL метрики:
   - Connections
   - Transactions/sec
   - Cache hit ratio
   - Replication lag
   - WAL generation
   - Locks
   - Query statistics

3. HAProxy метрики:
   - Frontend/Backend status
   - Session rate
   - Error rate
   - Response time

4. PgBouncer метрики:
   - Active connections
   - Waiting connections
   - Client connections
   - Server connections

## 7. Тестирование

#### Установка pgbench и настройка лимитов
```bash
# Установка pgbench
sudo apt install -y postgresql-client-common postgresql-client

# Увеличение лимита открытых файлов
sudo bash -c 'cat >> /etc/security/limits.conf << EOF
*               soft    nofile          65535
*               hard    nofile          65535
root            soft    nofile          65535
root            hard    nofile          65535
EOF'

# Применение новых лимитов
sudo sysctl -w fs.file-max=65535
sudo sysctl -p

# Проверка новых лимитов
ulimit -n 65535
ulimit -n
```

### 7.1 Средняя нагрузка
```bash
# Инициализация тестовой базы данных
PGPASSWORD=rebrain_admin_password pgbench -i -U rebrain_admin -h haproxy -p 5432 -d rebrain_courses_db

# Тест средней нагрузки
PGPASSWORD=rebrain_admin_password pgbench -U rebrain_admin -h haproxy -p 5432 -d rebrain_courses_db -c 500 -j 5 -T 180
```

### 7.2 Высокая нагрузка
```bash
PGPASSWORD=rebrain_admin_password pgbench -U rebrain_admin -h haproxy -p 5432 -d rebrain_courses_db -c 5000 -j 25 -T 180
```

### 7.3 Высокая нагрузка + убийство мастера
```bash
# В одном терминале
PGPASSWORD=rebrain_admin_password pgbench -U rebrain_admin -h haproxy -p 5432 -d rebrain_courses_db -c 5000 -j 25 -T 180

# В другом терминале через 60 секунд после начала теста
ssh pg-node-1 "sudo systemctl stop patroni"
```
