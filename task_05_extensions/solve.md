# Блок 05: Расширения

1. Установите PostgreSQL **v12** на предоставленной VM с OS Ubuntu.

```bash
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list

sudo apt update
sudo apt install postgresql-12 -y
```

2. Добавьте в PostgreSQL пользователя `root` с правами **SUPERUSER**.
```bash
sudo -i -u postgres
psql
```

```sql
CREATE ROLE root WITH SUPERUSER LOGIN PASSWORD 'password';
```

Подключитесь к PostgreSQL пользователем `root` с помощью команды:
```bash
psql -h localhost -U root -d postgres
```

3. Создайте базу данных `rebrain` и пользователя `extuser`.
```sql
CREATE DATABASE rebrain;
CREATE ROLE extuser WITH LOGIN PASSWORD 'extuser_password';
```

4. Установите расширение `pg_cron` для PostgreSQL с помощью пакетного менеджера `apt`.
```bash
sudo apt install postgresql-12-cron -y
```

Откройте конфигурационный файл PostgreSQL:  
```bash
sudo nano /etc/postgresql/12/main/postgresql.conf
```

Добавьте в конец файла следующую строку:
```bash
shared_preload_libraries = 'pg_cron'
cron.database_name = 'rebrain'
```

Перезапустите PostgreSQL:
```bash
sudo pg_ctlcluster 12 main restart
```

Активируйте расширение `pg_cron` в базе данных `rebrain`.
```sql
\c rebrain
CREATE EXTENSION pg_cron;
```

Для пользователя `extuser` предоставьте доступ к схеме `cron`.
```sql
GRANT USAGE ON SCHEMA cron TO extuser;
```

5. Настройте задачу очистки (VACUUM) ежедневно в 2 часа ночи для базы данных `rebrain`. Задачу нужно запускать от имени пользователя `extuser`.
```sql
SELECT cron.schedule(
    '0 2 * * *',
    'VACUUM'
);
```

Проверка настройки расписания
```sql
SELECT * FROM cron.job;
```

Обновление пользователя для задачи
```sql
UPDATE cron.job
SET username = 'extuser'
WHERE jobid = 1;  -- Замените 1 на фактический jobid вашей задачи
```

6. Проверьте настройку расписания:
```sql
SELECT * FROM cron.job;
```
