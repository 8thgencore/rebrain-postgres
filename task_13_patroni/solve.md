# Блок: Настройка отказоустойчивого кластера PostgreSQL с Patroni

## 0. Настройка hostname и /etc/hosts

```bash
# На сервере patroni-1
hostnamectl set-hostname pg-node-1 --static

# На сервере patroni-2
hostnamectl set-hostname pg-node-2 --static

# На сервере patroni-3
hostnamectl set-hostname pg-node-3 --static

# На сервере etcd-1
hostnamectl set-hostname etcd-node-1 --static   

# На сервере etcd-2
hostnamectl set-hostname etcd-node-2 --static

# На сервере etcd-3
hostnamectl set-hostname etcd-node-3 --static

# На сервере HAProxy
hostnamectl set-hostname haproxy --static
```

Добавьте следующие записи в `/etc/hosts` на всех серверах:

```bash
tee -a /etc/hosts << EOF
# PostgreSQL nodes
192.168.1.11 pg-node-1
192.168.1.12 pg-node-2
192.168.1.13 pg-node-3

# ETCD nodes
192.168.1.21 etcd-node-1
192.168.1.22 etcd-node-2
192.168.1.23 etcd-node-3

# HAProxy
192.168.1.30 haproxy
EOF
```

Проверка настроек:
```bash
# Проверка hostname
hostname

# Проверка разрешения имен
ping -c 1 pg-node-1
ping -c 1 pg-node-2
ping -c 1 pg-node-3
ping -c 1 etcd-node-1
ping -c 1 etcd-node-2
ping -c 1 etcd-node-3
ping -c 1 haproxy
```

## 1. Установка ETCD на серверах etcd-1, etcd-2, etcd-3

```bash
# Создание директории
mkdir -p /task13
chmod -R 777 /task13/

# Создание скрипта установки
nano /tmp/etcd_installer.sh

# Выполнение скрипта
chmod +x /tmp/etcd_installer.sh
/tmp/etcd_installer.sh

# Копирование бинарных файлов в /usr/local/bin
cp /task13/etcd/etcd* /usr/local/bin
```

## 2. Настройка ETCD

```bash
# Создание конфигурационного файла для etcd-1 (аналогично для etcd-2 и etcd-3)
mkdir -p /etc/etcd
nano /etc/etcd/etcd.yml

# Замена IP адресов в файле etcd.yml
sed -i 's/etcd-node-1/10.129.0.34/g; s/etcd-node-2/10.129.0.35/g; s/etcd-node-3/10.129.0.36/g' /etc/etcd/etcd.yml
```

## 3. Настройка пользователя и сервиса ETCD

```bash
# Создание пользователя и группы
useradd -r -s /sbin/nologin etcd
mkdir -p /task13/etcd/{data-dir,wal-dir}
chown -R etcd:etcd /task13/etcd/
chown -R etcd:etcd /etc/etcd/

# Создание systemd сервиса
tee -a /etc/systemd/system/etcd.service << EOF
# TODO: содержимое файла etcd.service
EOF

# Запуск сервиса
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
```

## 4. Проверка кластера ETCD

```bash
# Проверка статуса кластера
/task13/etcd/etcdctl endpoint status --write-out=table
/task13/etcd/etcdctl endpoint health --write-out=table
/task13/etcd/etcdctl member list --write-out=table
```

## 5. Установка PostgreSQL 13 на серверах patroni-1, patroni-2, patroni-3

```bash
# Добавление репозитория PostgreSQL
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Обновление и установка PostgreSQL
sudo apt update
sudo apt install -y postgresql-13

# Остановка PostgreSQL если запущен
sudo systemctl stop postgresql@13-main
```

## 6. Установка зависимостей Patroni

```bash
# Установка зависимостей
sudo apt install -y python3-pip python3-dev libpq-dev gcc
pip3 install --upgrade setuptools pip
pip3 install psycopg2-binary
```

## 7. Установка и настройка Patroni

```bash
# Установка Patroni
pip3 install patroni[etcd]

# Создание директорий
mkdir -p /task13/patroni /etc/patroni

# Создание конфигурации Patroni
cat > /etc/patroni/patroni.yml << EOF
# TODO: содержимое файла patroni.yml
EOF

# Копирование patroni в /usr/local/bin
sudo cp $(which patroni) /usr/local/bin/
```

## 8. Настройка сервиса Patroni

```bash
# Установка прав
chown -R postgres:postgres /task13/patroni/
chown -R postgres:postgres /etc/patroni/

# Создание systemd сервиса
cat > /etc/systemd/system/patroni.service << EOF
# TODO: содержимое файла patroni.service
EOF

# Запуск сервиса
systemctl daemon-reload
systemctl enable patroni
systemctl start patroni
```

## 9. Проверка работы кластера PostgreSQL

```bash
# Запуск PostgreSQL
sudo systemctl start postgresql

# Проверка статуса кластера
patronictl -c /etc/patroni/patroni.yml list

# Создание тестовой таблицы на лидере
sudo -u postgres psql -d postgres << EOF
CREATE TABLE test (id SERIAL Primary Key NOT NULL, info TEXT);
INSERT INTO test (info) VALUES ('Hello'),('From'),('Patroni'),('Leader');
EOF

# Проверка репликации на реплике
sudo -u postgres psql -d postgres -c "SELECT * FROM test;"
```

## 10. Установка и настройка HAProxy

```bash
# Установка HAProxy
sudo apt install -y haproxy

# Настройка конфигурации
cat > /etc/haproxy/haproxy.cfg << EOF
# TODO: содержимое файла haproxy.cfg
EOF

# Запуск HAProxy
systemctl enable haproxy
systemctl start haproxy
```

## 11. Проверка работы HAProxy

```bash
# Проверка подключения через HAProxy
psql -h 10.129.0.11 -d postgres -U root -W -c "select inet_server_addr();"
```

## 12. Тестирование отказоустойчивости

```bash
# Остановка лидера
systemctl stop patroni

# Проверка переключения
patronictl -c /etc/patroni/patroni.yml list

# Проверка нового лидера
psql -h haproxy -p 5432 -d postgres -U root -W -c "select inet_server_addr();"
```

## Дополнительные проверки

```bash
# Проверка логов
journalctl -u patroni -n 100
journalctl -u etcd -n 100
journalctl -u haproxy -n 100

# Проверка статусов сервисов
systemctl status patroni
systemctl status etcd
systemctl status haproxy

# Проверка доступности HAProxy статистики
curl http://haproxy:32700
``` 