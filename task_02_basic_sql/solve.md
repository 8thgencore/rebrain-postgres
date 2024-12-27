# Блок 02: Basic SQL

1. Установите 14-ую версию PostgreSQL из официального репозитория postgresql на VM с OS Ubuntu (sources.list уже настроен, добавлять репозитории не нужно).
```bash
sudo apt update
sudo apt install postgresql-14
```

2. Добавьте в PostgreSQL пользователя root с правами SUPERUSER.
```sql
CREATE USER root WITH SUPERUSER PASSWORD 'your_password';
```

3. Создайте базу данных "rebrain_courses_db".
```sql
CREATE DATABASE rebrain_courses_db;
```

4. Для работы с базой данных создайте пользователя "rebrain_admin".
```sql
CREATE USER rebrain_admin WITH PASSWORD 'your_password';
```

5. Выдайте все права пользователю "rebrain_admin" на базу данных "rebrain_courses_db".
```sql
GRANT ALL PRIVILEGES ON DATABASE rebrain_courses_db TO rebrain_admin;
```

6. C помощью утилиты psql, подключитесь к базе данных "rebrain_courses_db".
```bash
psql -U rebrain_admin -d rebrain_courses_db
```

7. Руководствуясь инструкцией к заданию, убедитесь, что таблица №1 и таблица №3 верно связаны по Foreign Key. Исправьте ошибку, если она есть.
```sql
ALTER TABLE users__courses 
DROP CONSTRAINT fk_course_id;

ALTER TABLE users__courses
ADD CONSTRAINT fk_course_id 
FOREIGN KEY (course_id) REFERENCES courses(course_id);
```

8. Руководствуясь инструкцией к заданию, убедитесь, что таблица №2 и таблица №3 верно связаны по Foreign Key. Исправьте ошибку, если она есть.
```sql
-- Ошибка уже исправлена в шаге 7
```

9. Внесите информацию о новом пользователе в таблицу №1:
```sql
INSERT INTO users (username, email, mobile_phone, firstname, lastname, city, is_curator)
VALUES ('vladon', 'Vladislav.Pirushin@gmail.com', '+79817937545', 'Vladislav', 'Pirushin', NULL, false);
```

10. Внесите информацию о новом курсе "Postgresql" в таблицу №2:
```sql
INSERT INTO courses (coursename, tasks_count, price)
VALUES ('Postgresql', 14, 7900);
```

11. Внесите в таблицу №3 данные о том, что пользователь с номером мобильного телефона "+79991916526" купил практикум "Devops":
```sql
INSERT INTO users__courses (user_id, course_id)
SELECT u.user_id, c.course_id
FROM users u, courses c
WHERE u.mobile_phone = '+79991916526'
AND c.coursename = 'Devops';
```

12. Получите все данные из таблицы №2 с информацией о курсах:
```sql
\copy (SELECT * FROM courses) TO '/tmp/answers/table2_courses_data' WITH CSV HEADER;
```

13. Получите из таблицы №1 список имен пользователей (username) и их мобильных номеров (mobile_phone):
```sql
\copy (SELECT username, mobile_phone FROM users) TO '/tmp/answers/table1_usernames_and_phones' WITH CSV HEADER;
```

14. Удалите все данные из таблицы №1, связанные с именем пользователя "yodajedi":
```sql
DELETE FROM users WHERE username = 'yodajedi';
```

15. Обновите данные цены практикума в таблице №2 для практикума "Postgresql". Новая цена: 10000 руб:
```sql
UPDATE courses SET price = 10000 WHERE coursename = 'Postgresql';
```

16. Обновите данные пользователя "Vladislav Pirushin" в таблице №1 указав, что он теперь является куратором:
```sql
UPDATE users 
SET is_curator = true 
WHERE firstname = 'Vladislav' AND lastname = 'Pirushin';
```

17. Используя LEFT OUTER JOIN получите всю информацию (SELECT *) из таблицы №2 и таблицы №3:
```sql
\copy (
    SELECT * 
    FROM courses c 
    LEFT OUTER JOIN users__courses uc 
    ON c.course_id = uc.course_id
) TO '/tmp/answers/LEFT_OUTER_JOIN' WITH CSV HEADER;
```

18. Используя RIGHT OUTER JOIN получите всю информацию (SELECT *) из таблицы №1 и таблицы №3:
```sql
\copy (
    SELECT * 
    FROM users u 
    RIGHT OUTER JOIN users__courses uc 
    ON u.user_id = uc.user_id
) TO '/tmp/answers/RIGHT_OUTER_JOIN' WITH CSV HEADER;
```

19. Сделайте бэкап базы данных командой:
```bash
pg_dump -U root rebrain_courses_db > rebrain_courses_db.sql
```

20. Сохраните файл бэкапа базы данных rebrain_courses_db.sql.bqp к себе на компьютер для выполнения следующих заданий.
```bash
scp user@server:rebrain_courses_db.sql.bqp /path/to/local/directory/
```
