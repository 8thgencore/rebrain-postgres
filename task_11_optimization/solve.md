# Блок: Оптимизация PostgreSQL

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

## 3. Установка pgbench
```bash
sudo yum install -y postgresql13-contrib

# Добавление pgbench в PATH
sudo cp /usr/pgsql-13/bin/pgbench /usr/bin/
```

## 4. Создание базы данных pgbench
```bash
sudo -u postgres createdb pgbench
```

## 5. Инициализация таблиц pgbench
```bash
sudo -u postgres pgbench --initialize --scale=100 pgbench
```

## 6-7. Тестирование с базовыми настройками
```bash
# Скачивание тестового скрипта
cd /opt
sudo wget https://files.rebrainme.com/workshops/postgresql/task11/task11.sql

# Установка прав на скрипт
sudo chmod 644 /opt/task11.sql

# Запуск базового теста
sudo -u postgres pgbench -t 1000 -c 15 -f /opt/task11.sql -n pgbench > /tmp/result_1.txt
sudo mv /tmp/result_1.txt /opt/result_1.txt
```

## 8-9. Отключение fsync и перезапуск
```bash
# Отключение fsync
sudo -u postgres psql << EOF
ALTER SYSTEM RESET ALL;
ALTER SYSTEM SET fsync to off;
EOF

# Перезапуск PostgreSQL
sudo systemctl restart postgresql-13
```

## 10-11. Второй тест и сохранение результата
```bash
sudo -u postgres pgbench -t 1000 -c 15 -f /opt/task11.sql -n pgbench > /tmp/result_2.txt
sudo mv /tmp/result_2.txt /opt/result_2.txt
```

## 12-13. Настройка synchronous_commit и commit_delay
```bash
# Установка параметров
sudo -u postgres psql << EOF
ALTER SYSTEM RESET ALL;
ALTER SYSTEM SET synchronous_commit to off;
ALTER SYSTEM SET commit_delay to 100000;
EOF

# Перезапуск PostgreSQL
sudo systemctl restart postgresql-13
```

## 14-15. Третий тест и сохранение результата
```bash
sudo -u postgres pgbench -t 1000 -c 15 -f /opt/task11.sql -n pgbench > /tmp/result_3.txt
sudo mv /tmp/result_3.txt /opt/result_3.txt
```

## 16-18. Оптимизация параметров памяти
```bash
# Настройка параметров в postgresql.conf
sudo nano /var/lib/pgsql/13/data/postgresql.conf

# Изменение следующих строк:
max_connections = 32
shared_buffers = '256MB'
work_mem = '16MB'
```

## 19. Перезапуск PostgreSQL
```bash
sudo systemctl restart postgresql-13
```

## 20. Анализ запроса с сортировкой
```bash
sudo -u postgres psql -d pgbench -c "EXPLAIN ANALYZE SELECT n FROM generate_series(1,5) as foo(n) order by n;"
```

## 21. Установка random_page_cost
```bash
sudo -u postgres psql << EOF
ALTER SYSTEM SET random_page_cost = 4.0;
EOF

sudo systemctl restart postgresql-13
```

## Дополнительные проверки

```bash
# Проверка текущих настроек
sudo -u postgres psql -c "SHOW ALL;"

# Проверка статуса PostgreSQL
sudo systemctl status postgresql-13

# Просмотр логов
sudo tail -f /var/lib/pgsql/13/data/log/postgresql-*.log
```

## Анализ результатов

Для сравнения результатов тестов можно использовать:
```bash
echo "=== Базовый тест ===" && cat /opt/result_1.txt
echo "=== Тест без fsync ===" && cat /opt/result_2.txt
echo "=== Тест с измененным synchronous_commit и commit_delay ===" && cat /opt/result_3.txt
``` 