# Блок 06: Репликация PostgreSQL

## 1. Установка PostgreSQL 13

Выполните на обоих серверах (master и slave):

```bash
# Добавление репозитория PostgreSQL
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Установка PostgreSQL
sudo yum install -y postgresql13-server postgresql13

# Инициализация кластера
sudo /usr/pgsql-13/bin/postgresql-13-setup initdb

# Запуск и включение автозапуска
sudo systemctl enable postgresql-13
sudo systemctl start postgresql-13
```

## 2. Настройка имен хостов

```bash
# На master сервере
sudo hostnamectl set-hostname master

# На slave сервере
sudo hostnamectl set-hostname slave
```

## 3. Настройка Master сервера

### Настройка pg_hba.conf
```bash
sudo nano /var/lib/pgsql/13/data/pg_hba.conf
```

Добавьте строку:
```
host    replication     postgres        0.0.0.0/0               trust
```

### Настройка postgresql.conf
```bash
sudo nano /var/lib/pgsql/13/data/postgresql.conf
```

Измените следующие параметры:
```
listen_addresses = '*'
wal_level = replica
max_wal_senders = 2
wal_keep_size = 32MB  # В PostgreSQL 13 заменяет wal_keep_segments
archive_mode = on
hot_standby = on
logging_collector = on
log_directory = '/var/log'
log_filename = 'postgresql.log'
```

### Создание файла для логов
```bash
sudo touch /var/log/postgresql.log
sudo chown postgres:postgres /var/log/postgresql.log
```

## 4. Настройка Slave сервера

### Остановка PostgreSQL
```bash
sudo systemctl stop postgresql-13
```

### Создание базовой копии
```bash
sudo -i -u postgres
pg_basebackup -h master -U postgres -D /var/lib/pgsql/13/backups/ -Fp -Xs -P -R

# Проверка конфигурации
cat ~/13/backups/postgresql.auto.conf

# Перемещение данных
mv /var/lib/pgsql/13/data/ /var/lib/pgsql/13/data_orig
mv /var/lib/pgsql/13/backups/ /var/lib/pgsql/13/data/
```

### Настройка postgresql.conf на slave
```bash
sudo nano /var/lib/pgsql/13/data/postgresql.conf
```

Добавьте параметры:
```
listen_addresses = '*'
logging_collector = on
log_directory = '/var/log'
log_filename = 'postgresql.log'
```

### Создание файла для логов
```bash
sudo touch /var/log/postgresql.log
sudo chown postgres:postgres /var/log/postgresql.log
```

## 5. Запуск репликации

### Перезапуск серверов
```bash
# На master
sudo systemctl restart postgresql-13

# На slave
sudo systemctl start postgresql-13
```

### Проверка статуса репликации
```bash
# На master
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"
```

## 6. Восстановление базы данных

### На master сервере:
```bash
# Скачивание файлов
cd /opt
sudo wget https://files.rebrainme.com/workshops/postgresql/task06/schema.sql
sudo wget https://files.rebrainme.com/workshops/postgresql/task06/data.sql

# Установка прав
sudo chown postgres:postgres /opt/*.sql

# Временно отключаем синхронную репликацию
sudo -u postgres psql -c "ALTER SYSTEM SET synchronous_standby_names TO '';"
sudo systemctl restart postgresql-13

# Восстановление
sudo -u postgres psql -f /opt/schema.sql
sudo -u postgres psql -f /opt/data.sql

# Возвращаем синхронную репликацию
sudo -u postgres psql -c "ALTER SYSTEM SET synchronous_standby_names TO 'slave';"
sudo systemctl restart postgresql-13
```

## 7. Проверка репликации

### На slave сервере:

Проверка наличия базы данных, схемы и роли
```bash
sudo -u postgres psql -c "\l" | grep car_portal
sudo -u postgres psql -c "\du" | grep car_portal_app
sudo -u postgres psql -d car_portal -c "\dn" | grep car_portal_app
```

Проверка таблиц в схеме
```bash
sudo -u postgres psql -d car_portal -c "SET search_path to car_portal_app; SELECT schemaname, tablename, tableowner FROM pg_tables WHERE schemaname = 'car_portal_app';"
```

Все команды должны показать одинаковые результаты на обоих серверах, что подтверждает успешную репликацию.
