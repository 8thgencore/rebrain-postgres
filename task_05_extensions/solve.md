# Блок 05: Расширения

1. Установите PostgreSQL **v12** на предоставленной VM с OS Ubuntu.
```bash
sudo apt update
sudo apt install postgresql-12
```

2. Добавьте в PostgreSQL пользователя `root` с правами **SUPERUSER**.
```bash
sudo -i -u postgres
psql
```
```sql
CREATE ROLE root WITH SUPERUSER LOGIN PASSWORD 'password';
```

3. Создайте базу данных `rebrain` и пользователя `extuser`.

Подключитесь к PostgreSQL пользователем `root` с помощью команды:
```bash
psql -U root -d postgres
```

```sql
CREATE DATABASE rebrain;
CREATE ROLE extuser WITH LOGIN PASSWORD 'extuser_password';
```

4. Установите расширение `pg_cron` для PostgreSQL с помощью пакетного менеджера `apt`.
```bash
sudo apt install postgresql-12-cron
```

Активируйте расширение `pg_cron` в базе данных `rebrain`.
```bash
sudo -i -u postgres
psql -d rebrain
```
```sql
CREATE EXTENSION pg_cron;
```

5. Настройте задачу очистки (VACUUM) ежедневно в 2 часа ночи для базы данных `rebrain`. Задачу нужно запускать от имени пользователя `extuser`.
```sql
SELECT cron.schedule(
    'daily_vacuum',
    '0 2 * * *',
    $$VACUUM$$
);
```

6. Проверьте настройку расписания:
```sql
SELECT * FROM cron.job;
```
