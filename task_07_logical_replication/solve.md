# Блок: Логическая репликация PostgreSQL

## 1. Установка PostgreSQL 11 на обоих серверах

```bash
# Добавление репозитория PostgreSQL
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg

# Обновление списка пакетов
sudo apt update

# Установка PostgreSQL 11
sudo apt install -y postgresql-11
```

## 2. Настройка Publisher (Издатель)

### Создание роли car_portal_app
```bash
sudo -u postgres psql -c "CREATE ROLE car_portal_app WITH LOGIN PASSWORD 'password';"
```
CREATE ROLE car_portal_app; ALTER ROLE car_portal_app REPLICATION LOGIN ; CREATE PUBLICATION car_portal FOR ALL TABLES;

### Настройка pg_hba.conf
```bash
sudo nano /etc/postgresql/11/main/pg_hba.conf
```

Добавьте строку:
```
host    all             car_portal_app    0.0.0.0/0               trust
```

### Настройка postgresql.conf
```bash
sudo nano /etc/postgresql/11/main/postgresql.conf
```

Измените параметры:
```
listen_addresses = '*'
wal_level = logical
```

### Перезапуск PostgreSQL
```bash
sudo systemctl restart postgresql@11-main
```

### Восстановление данных
```bash
# Скачивание файлов
cd /opt
sudo wget https://files.rebrainme.com/workshops/postgresql/task07/schema.sql
sudo wget https://files.rebrainme.com/workshops/postgresql/task07/data.sql

# Установка прав
sudo chown postgres:postgres /opt/*.sql

# Восстановление схемы
sudo -u postgres psql -f /opt/schema.sql

# Восстановление данных
sudo -u postgres psql -f /opt/data.sql
```

### Добавление прав репликации
```bash
sudo -u postgres psql -c "ALTER ROLE car_portal_app WITH REPLICATION;"
```

### Создание публикации
```bash
sudo -u postgres psql -d car_portal -c "CREATE PUBLICATION car_portal_pub FOR ALL TABLES;"
```

## 3. Настройка Subscriber (Подписчик)

### Создание роли
```bash
sudo -u postgres psql -c "CREATE ROLE car_portal_app WITH LOGIN PASSWORD 'password';"
```

### Настройка pg_hba.conf
```bash
sudo nano /etc/postgresql/11/main/pg_hba.conf
```

Добавьте строку:
```
host    all             car_portal_app    0.0.0.0/0               trust
```

### Настройка postgresql.conf
```bash
sudo nano /etc/postgresql/11/main/postgresql.conf
```

Измените параметры:
```
listen_addresses = '*'
```

### Перезапуск PostgreSQL
```bash
sudo systemctl restart postgresql@11-main
```

### Копирование и восстановление схемы
```bash
# Копирование schema.sql с publisher
scp publisher:/opt/schema.sql /opt/

# Восстановление схемы
sudo -u postgres psql -f /opt/schema.sql
```

### Создание подписки
```bash
sudo -u postgres psql -d car_portal -c "CREATE SUBSCRIPTION car_portal 
    CONNECTION 'host=publisher port=5432 dbname=car_portal user=car_portal_app'
    PUBLICATION car_portal_pub;"
```

## 4. Проверка репликации

### На Publisher добавляем тестовую запись
```bash
sudo -u postgres psql -d car_portal -c "INSERT INTO car_portal_app.account (first_name, last_name, email, password) VALUES ('Rebrain', 'me', 'info@rebrainme.com', md5('info@rebrainme.com'));"
```

### Проверка на Subscriber
```bash
sudo -u postgres psql -d car_portal -c "SELECT * FROM car_portal_app.account WHERE email = 'info@rebrainme.com';"
```
