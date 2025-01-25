# Блок: Оптимизация медленных запросов

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

## 2. Добавление пользователя root
```bash
sudo -u postgres psql -c "CREATE USER root WITH SUPERUSER PASSWORD 'root_password';"
```

## 3. Создание базы данных task12
```bash
sudo -u postgres psql -c "CREATE DATABASE task12;"
```

## 4. Создание таблицы pgsql
```bash
sudo -u postgres psql -d task12 << EOF
CREATE TABLE pgsql (
    id INT PRIMARY KEY,
    name TEXT NOT NULL
);
EOF
```

## 5. Заполнение таблицы данными
```bash
sudo -u postgres psql -d task12 -c "INSERT INTO pgsql SELECT n, md5(random()::text) FROM generate_series(1, 100000) AS foo(n);"
```

## 6-7. Получение плана выполнения и сохранение стоимости
```bash
# Получение плана выполнения
sudo -u postgres psql -d task12 -c "EXPLAIN SELECT * FROM pgsql;" > /tmp/explain_output.txt

# Извлечение нужной строки и сохранение в файл
grep "cost=" /tmp/explain_output.txt | sed -E 's/.*cost=([0-9.]+)\.\.([0-9.]+).*rows=([0-9]+).*width=([0-9]+).*/cost=\1..\2 rows=\3 width=\4/' > /tmp/cost_preview.txt
sudo mv /tmp/cost_preview.txt /opt/cost_preview.txt
```

## 8-9. ANALYZE и повторный EXPLAIN
```bash
# Выполнение ANALYZE
sudo -u postgres psql -d task12 -c "ANALYZE pgsql;"

# Повторное получение плана выполнения
sudo -u postgres psql -d task12 -c "EXPLAIN SELECT * FROM pgsql;" > /tmp/explain_output_after.txt

# Извлечение нужной строки и сохранение в файл
grep "cost=" /tmp/explain_output_after.txt | sed -E 's/.*cost=([0-9.]+)\.\.([0-9.]+).*rows=([0-9]+).*width=([0-9]+).*/cost=\1..\2 rows=\3 width=\4/' > /tmp/cost.txt
sudo mv /tmp/cost.txt /opt/cost.txt
```

## 10. Анализ запроса с диапазоном
```bash
sudo -u postgres psql -d task12 -c "EXPLAIN ANALYZE SELECT * FROM pgsql WHERE id >= 10 and id < 20;" > /tmp/explain_cost.txt
sudo mv /tmp/explain_cost.txt /opt/explain_cost.txt
```

## 11. Анализ запроса с искусственным сбоем планировщика
```bash
sudo -u postgres psql -d task12 -c "EXPLAIN SELECT * FROM pgsql WHERE upper(id::text)::int < 20;" > /tmp/expression.txt
sudo mv /tmp/expression.txt /opt/expression.txt
```

## 12. Создание таблицы success_practice
```bash
sudo -u postgres psql -d task12 << EOF
CREATE TABLE success_practice (
    id INT,
    description TEXT,
    pgsql_id INT REFERENCES pgsql(id)
);
EOF
```

## 13. Заполнение таблицы success_practice
```bash
sudo -u postgres psql -d task12 -c "INSERT INTO success_practice (id, description, pgsql_id) SELECT n, md5(n::text), random()*99999+1 FROM generate_series(1,200000) AS foo(n);"
```

## 14. Анализ запроса соединения без индекса
```bash
sudo -u postgres psql -d task12 -c "EXPLAIN ANALYZE SELECT * FROM pgsql p INNER JOIN success_practice sp ON p.id = sp.pgsql_id WHERE sp.pgsql_id = 1000;" > /tmp/join_result.txt

# Извлечение времени выполнения
sudo grep "Execution Time:" /tmp/join_result.txt | awk '{print $3}' > /tmp/execution_without_index.txt
sudo mv /tmp/execution_without_index.txt /opt/execution_without_index.txt
```

## 15. Создание индекса
```bash
sudo -u postgres psql -d task12 -c "CREATE INDEX ON success_practice (pgsql_id);"
```

## 16. Анализ запроса соединения с индексом
```bash
sudo -u postgres psql -d task12 -c "EXPLAIN ANALYZE SELECT * FROM pgsql p INNER JOIN success_practice sp ON p.id = sp.pgsql_id WHERE sp.pgsql_id = 1000;" > /tmp/join_result_with_index.txt

# Извлечение времени выполнения
sudo grep "Execution Time:" /tmp/join_result_with_index.txt | awk '{print $3}' > /tmp/execution_with_index.txt
sudo mv /tmp/execution_with_index.txt /opt/execution_with_index.txt
```

## Дополнительные проверки

```bash
# Проверка созданных таблиц
sudo -u postgres psql -d task12 -c "\dt"

# Проверка индексов
sudo -u postgres psql -d task12 -c "\di"

# Проверка содержимого файлов
echo "=== Cost Preview ===" && cat /opt/cost_preview.txt
echo "=== Cost After ANALYZE ===" && cat /opt/cost.txt
echo "=== Execution Time Without Index ===" && cat /opt/execution_without_index.txt
echo "=== Execution Time With Index ===" && cat /opt/execution_with_index.txt
``` 