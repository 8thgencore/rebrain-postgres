# Блок 05: Разграничение прав доступа

1. Установите postgresql **v13** на предоставленной VM c OS Ubuntu 20.04.
```bash
sudo apt update
sudo apt install postgresql-13
```

2. Добавьте в PostgreSQL пользователя `root` c правами **SUPERUSER**.
```bash
sudo -i -u postgres
psql
```
```sql
CREATE ROLE root WITH SUPERUSER LOGIN PASSWORD 'password';
```

3. Подключитесь к PostgreSQL пользователем `root` с помощью команды: `psql -U root -d postgres`
```bash
psql -U root -d postgres
```

4. Создайте базу данных `rebrain_courses_db`.
```sql
CREATE DATABASE rebrain_courses_db;
```

5. Для работы с базой данных создайте пользователя `rebrain_admin`.
```sql
CREATE ROLE rebrain_admin WITH LOGIN PASSWORD 'admin_password';
```

6. Переместите файл бэкапа базы данных `rebrain_courses_db` из предыдущего задания на сервер и положите в директорию `/tmp/` с именем `rebrain_courses_db.sql.bqp`.
```bash
scp path/to/local/rebrain_courses_db.sql.bqp user@server:/tmp/
```

7. Восстановите данные из бэкапа базы данных из предыдущего задания командой: `psql -U root -d rebrain_courses_db -f /tmp/rebrain_courses_db.sql.bqp`
```bash
psql -U root -d rebrain_courses_db -f /tmp/rebrain_courses_db.sql.bqp
```

8. Выдайте все права пользователю "rebrain_admin" на базу данных "rebrain_courses_db".
```sql
GRANT ALL PRIVILEGES ON DATABASE rebrain_courses_db TO rebrain_admin;
```

9. Создать роль `backup`:
```sql
CREATE ROLE backup;
```

10. Подключитесь пользователем `root` к базе данных `rebrain_courses_db`.

```bash
psql -U root -h 127.0.0.1 -d rebrain_courses_db
```

11. С помощью команды **GRANT USAGE** выдайте права на использование схемы `public` пользователю `rebrain_admin`. Затем, с помощью команды **ALTER DEFAULT PRIVILEGES** выдайте для роли `backup` права `SELECT` на вновь создаваемые таблицы пользователем `rebrain_admin` в схеме `public`.

```sql
GRANT USAGE ON SCHEMA public TO rebrain_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE rebrain_admin IN SCHEMA public GRANT SELECT ON TABLES TO backup;
```

12. Зайдите под пользователем `rebrain_admin` в базу данных `rebrain_courses_db`:
```bash
psql -U rebrain_admin -h 127.0.0.1 rebrain_courses_db
```

13. Cоздайте таблицу `blog` в базе данных `rebrain_courses_db`:
```sql
CREATE TABLE blog(
    id SERIAL PRIMARY KEY NOT NULL,     -- Primary Key
    user_id INT NOT NULL,               -- Foreign Key to table users 
    blog_text TEXT NOT NULL,
    CONSTRAINT fk_user_id
        FOREIGN KEY (user_id) 
            REFERENCES users(user_id)
    );
```

14. Занесите следующие данные в таблицу blog:
```sql
INSERT INTO blog(user_id,blog_text)
VALUES (1,'We are studying at the REBRAIN PostgreSQL Workshop');
```

15. Снова подключитесь пользователем root к базе данных rebrain_courses_db.
```bash
psql -U root -h 127.0.0.1 -d rebrain_courses_db
```

16. Создайте роль `rebrain_group_select_access`.
```sql
CREATE ROLE rebrain_group_select_access;
```

17. С помощью команды **GRANT USAGE** выдайте права на использование схемы `public` пользователю `rebrain_group_select_access`.
```sql
GRANT USAGE ON SCHEMA public TO rebrain_group_select_access;
```

18. Выдайте права для `rebrain_group_select_access` только на `SELECT` из всех таблиц в схеме `public`.
```sql
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rebrain_group_select_access;
```

19. Создайте роль `rebrain_user`.
```sql
CREATE ROLE rebrain_user;
ALTER ROLE rebrain_user WITH LOGIN PASSWORD 'user_password';
```

20. Выдайте для роли `rebrain_user` права роли `rebrain_group_select_access`.
```sql
GRANT rebrain_group_select_access TO rebrain_user;
```

21. Убедитесь, что роль `rebrain_user` может получать все данные из любых таблиц базы данных `rebrain_courses_db` в схеме `public`.
```sql
SELECT * FROM blog;
```

22. Создайте роль `rebrain_portal`.
```sql
CREATE ROLE rebrain_portal;
```

23. Убедитесь, что вы подключены к базе данных `rebrain_courses_db`. Для базы данных `rebrain_courses_db` создайте новую схему `rebrain_portal`.
```sql
CREATE SCHEMA rebrain_portal;
```

24. С помощью команды **GRANT USAGE** выдайте права на использование схемы `rebrain_portal` пользователю `rebrain_portal`.
```sql
GRANT USAGE ON SCHEMA rebrain_portal TO rebrain_portal;
```

25. Выдайте все права на схему `rebrain_portal` для роли `rebrain_portal`.
```sql
GRANT ALL PRIVILEGES ON SCHEMA rebrain_portal TO rebrain_portal;
```

26. Сделайте бекап базы данных `rebrain_courses_db` с помощью команды: `pg_dump -U root rebrain_courses_db > /tmp/rebrain_courses_db_task04.sql.bqp`
```bash
pg_dump -U root rebrain_courses_db > /tmp/rebrain_courses_db_task04.sql.bqp
```
