# Блок 04: Advanced SQL

1. Установите из официального репозитория postgresql на VM c OS Ubuntu (sources.list уже настроен, добавлять репозитории не нужно).
```bash
sudo apt update
sudo apt install postgresql
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

6. Переместите файл бэкапа базы данных "rebrain_courses_db" из предыдущего задания на сервер и положите в директорию /tmp/ с именем rebrain_courses_db.sql.bqp.
```bash
scp path/to/local/rebrain_courses_db.sql.bqp user@server:/tmp/
```

7. Восстановите данные из бэкапа базы данных из предыдущего задания командой: psql -U root -d rebrain_courses_db -f /tmp/rebrain_courses_db.sql.bqp
```bash
psql -U root -d rebrain_courses_db -f /tmp/rebrain_courses_db.sql.bqp
```

8. C помощью утилиты psql, подключитесь к базе данных "rebrain_courses_db".
```bash
psql -U root -d rebrain_courses_db
```

9. Проверьте наличие данных в таблицах, чтобы понять, что бекап данных прошел успешно.
```sql
\dt -- показать список таблиц
SELECT * FROM table_name LIMIT 5; -- проверить данные
```
10. Посчитайте общую стоимость практикумов компании REBRAIN из таблицы courses с помощью оконной функции sum(price) OVER (), результат сохраните в файл /tmp/answers/devops_old_price (используйте запрос SELECT * FROM ...).
```sql
\copy (
    SELECT SUM(price) AS total_price
    FROM courses
) TO '/tmp/answers/devops_old_price' WITH CSV HEADER;
```


```console
$ cat devops_new_price

course_id,coursename,tasks_count,price,total_price
3,Bash,15,6900,6900
8,Logs,14,7900,14800
9,Postgresql,14,10000,24800
7,Docker,45,30000,54800
1,Kubernetes,70,35000,89800
4,Golang,117,55000,144800
5,Linux,102,65000,209800
2,Highload,130,75000,284800
6,Devops,212,100000,384800
```

11. Обновите данные цены практикума в таблице №2 для практикума "Devops". Новая цена: 100000 руб.
```sql
UPDATE courses SET price = 100000 WHERE name = 'Devops';
```

12. Посчитайте общую стоимость практикумов компании REBRAIN из обновленной таблицы courses с помощью оконной функции sum(price) OVER (ORDER BY price), результат сохраните в файл /tmp/answers/devops_new_price (используйте запрос SELECT * FROM ...).
```sql
\copy (
    SELECT SUM(price) AS total_price
    FROM courses
) TO '/tmp/answers/devops_new_price' WITH CSV HEADER;
```

```console
$ cat devops_old_price

course_id,coursename,tasks_count,price,total_price
1,Kubernetes,70,35000,359800
2,Highload,130,75000,359800
3,Bash,15,6900,359800
4,Golang,117,55000,359800
7,Docker,45,30000,359800
8,Logs,14,7900,359800
9,Postgresql,14,10000,359800
6,Devops,212,75000,359800
5,Linux,102,65000,359800
```


13. Добавьте новую таблицу auditlog с NOT NULL полями:
* id (PrimaryKey)
* user_id (id пользователя, который был создан)
* creation_time (время создания записи о новом пользователе)
* creator (имя пользователя базы данных, с помощью которого производился insert)
```sql
CREATE TABLE auditlog (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    creation_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    creator VARCHAR(50) NOT NULL
);
```
14. Создайте функцию c именем "fnc_auditlog_users_insert", которая логирует в таблицу (записывает в таблицу) auditlog информацию о регистрации нового пользователя на сайте компании REBRAIN.
```sql
CREATE OR REPLACE FUNCTION fnc_auditlog_users_insert() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO auditlog (user_id, creator)
    VALUES (NEW.user_id, SESSION_USER);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

15. Создайте и установите триггер "insert_into_users_trigger" на INSERT данных в таблицу users так, чтобы вызывалась функция c именем "fnc_auditlog_users_insert", которую вы создали выше.
```sql
CREATE TRIGGER insert_into_users_trigger
AFTER INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION fnc_auditlog_users_insert();
```

16. С помощью команды INSERT, добавьте в таблицу "users" 15 новых пользователей. Для каждого нового пользователя делайте отдельный запрос, так чтобы срабатывал установленный триггер.
```sql
INSERT INTO users (username, email, mobile_phone, firstname, lastname, city, is_curator, record_date) VALUES
('user1', 'user1@example.com', '1234567890', 'John', 'Doe', 'New York', true, NOW()),
('user2', 'user2@example.com', '0987654321', 'Jane', 'Smith', 'Los Angeles', false, NOW()),
('user3', 'user3@example.com', '1122334455', 'Alice', 'Johnson', 'Chicago', true, NOW()),
('user4', 'user4@example.com', '5544332211', 'Bob', 'Brown', 'Houston', false, NOW()),
('user5', 'user5@example.com', '6677889900', 'Charlie', 'Davis', 'Phoenix', true, NOW()),
('user6', 'user6@example.com', '0099887766', 'David', 'Miller', 'Philadelphia', false, NOW()),
('user7', 'user7@example.com', '1100223344', 'Eve', 'Wilson', 'San Antonio', true, NOW()),
('user8', 'user8@example.com', '4433221100', 'Frank', 'Moore', 'San Diego', false, NOW()),
('user9', 'user9@example.com', '5566778899', 'Grace', 'Taylor', 'Dallas', true, NOW()),
('user10', 'user10@example.com', '9988776655', 'Hank', 'Anderson', 'San Jose', false, NOW()),
('user11', 'user11@example.com', '1212121212', 'Ivy', 'Thomas', 'Austin', true, NOW()),
('user12', 'user12@example.com', '2121212121', 'Jack', 'Jackson', 'Jacksonville', false, NOW()),
('user13', 'user13@example.com', '3434343434', 'Kara', 'White', 'Fort Worth', true, NOW()),
('user14', 'user14@example.com', '4343434343', 'Leo', 'Harris', 'Columbus', false, NOW()),
('user15', 'user15@example.com', '5656565656', 'Mia', 'Martin', 'Charlotte', true, NOW());
```

17. Создайте представление c именем "get_last_10_records_from_auditlog", которое позволит вывести из таблицы auditlog последних 10 попыток записи в таблицу users за последний день с сортировкой по времени (select * from auditlog limit 10 сортировка по времени).
```sql
CREATE OR REPLACE VIEW get_last_10_records_from_auditlog AS
SELECT * FROM auditlog
WHERE creation_time >= NOW() - INTERVAL '1 day'
ORDER BY creation_time DESC
LIMIT 10;
```

18. Сделайте бекап базы с помощью команды: pg_dump -U root rebrain_courses_db > /tmp/rebrain_courses_db_task03.sql.bqp
```bash
pg_dump -U root rebrain_courses_db > /tmp/rebrain_courses_db_task03.sql.bqp
```