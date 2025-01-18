# Блок: Настройка WAL-E для архивации в AWS S3

## 1. Установка PostgreSQL 13

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

## 2. Восстановление данных

```bash
# Скачивание файлов
cd /opt
sudo wget https://files.rebrainme.com/workshops/postgresql/task08/schema.sql
sudo wget https://files.rebrainme.com/workshops/postgresql/task08/data.sql

# Установка прав
sudo chown postgres:postgres /opt/*.sql

# Восстановление
sudo -u postgres psql -f /opt/schema.sql
sudo -u postgres psql -f /opt/data.sql
```

## 3. Обновление репозитория CentOS 7
```bash
sudo sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo
sudo sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo
sudo sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo

sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
```

## 4. Установка зависимостей

```bash
# Обновление пакетов
sudo yum update -y

# Установка EPEL
sudo yum install epel-release

# Установка Python и необходимых пакетов
sudo yum install -y python3 python3-pip python3-devel lzop pv python36-setuptools
sudo yum install -y gcc gcc-c++ centos-release-scl devtoolset-7
sudo scl enable devtoolset-7 bash
```

## 5. Установка WAL-E и boto

```bash
sudo pip3 install wal-e[aws] boto
```

## 6. Настройка окружения WAL-E

```bash
# Создание каталога для переменных окружения
sudo mkdir -p /etc/wal-e/env
sudo chown -R root:postgres /etc/wal-e
sudo chmod 750 /etc/wal-e

# Создание файлов с переменными окружения
sudo bash -c 'echo "key" > /etc/wal-e/env/AWS_ACCESS_KEY_ID'
sudo bash -c 'echo "access_key" > /etc/wal-e/env/AWS_SECRET_ACCESS_KEY'
sudo bash -c 'echo "https+path://storage.yandexcloud.net" > /etc/wal-e/env/WALE_S3_ENDPOINT'
sudo bash -c 'echo "s3://38*****" > /etc/wal-e/env/WALE_S3_PREFIX'
sudo bash -c 'echo "ru-central1" > /etc/wal-e/env/AWS_REGION'
sudo bash -c 'echo "True" > /etc/wal-e/env/AWS_S3_FORCE_PATH_STYLE'

# Установка правильных прав на файлы
sudo chown -R root:postgres /etc/wal-e/env
sudo chmod 640 /etc/wal-e/env/*
```

## 7. Установка envdir

```bash
sudo pip3 install envdir
```

## 8. Настройка архивации в PostgreSQL

```bash
sudo nano /var/lib/pgsql/13/data/postgresql.conf
```

Добавьте или измените следующие параметры:
```
wal_level = replica
archive_mode = on
archive_command = 'envdir /etc/wal-e/env wal-e wal-push %p'
archive_timeout = 60
```

```bash
# Перезапуск PostgreSQL
sudo systemctl restart postgresql-13
```

## 9. Проверка работоспособности

```bash
# Проверка архивации
sudo -u postgres bash -c '/usr/local/bin/envdir /etc/wal-e/env /usr/local/bin/wal-e backup-list' > /tmp/file

# Проверка содержимого файла
cat /tmp/file
```

## Дополнительные проверки

```bash
# Проверка прав на каталоги
sudo ls -la /etc/wal-e
sudo ls -la /etc/wal-e/env

# Проверка статуса PostgreSQL
sudo systemctl status postgresql-13

# Проверка логов PostgreSQL
sudo tail -f /var/lib/pgsql/13/data/log/postgresql-*.log
```
