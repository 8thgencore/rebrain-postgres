# Блок: Настройка менеджера соединений pgbouncer

## 1-19. Установка и настройка PostgreSQL, Prometheus, Grafana
[Эти шаги аналогичны предыдущему заданию, поэтому пропущены для краткости]

## 20. Установка и настройка pgbouncer
```bash
# Установка pgbouncer
sudo apt install -y pgbouncer

# Получение MD5 хеша пароля для PostgreSQL
sudo -u postgres psql -c "SELECT usename, passwd FROM pg_shadow WHERE usename = 'rebrain_monitoring';" -t -A
```

# Создание файла с пользователями
```bash
sudo tee /etc/pgbouncer/userlist.txt << EOF
"rebrain_monitoring" "пароль_из_предыдущей_команды"
EOF
```

# Перезапуск PostgreSQL
sudo systemctl restart postgresql

# Настройка конфигурации pgbouncer
sudo nano /etc/pgbouncer/pgbouncer.ini
```

```ini
[databases]
rebrain_courses_db = host=127.0.0.1 port=5432 dbname=rebrain_courses_db user=rebrain_monitoring password=monitoring_password

[pgbouncer]
listen_port = 6432
listen_addr = *
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 30
```

```bash
# Создание директории для логов
sudo mkdir -p /var/log/postgresql
sudo chown postgres:postgres /var/log/postgresql

# Установка прав на файлы конфигурации
sudo chown postgres:postgres /etc/pgbouncer/pgbouncer.ini
sudo chown postgres:postgres /etc/pgbouncer/userlist.txt
sudo chmod 640 /etc/pgbouncer/pgbouncer.ini
sudo chmod 640 /etc/pgbouncer/userlist.txt

# Перезапуск сервисов
sudo systemctl restart postgresql
sudo systemctl restart pgbouncer

# Проверка статуса и порта
sudo systemctl status pgbouncer
ss -tunlp | grep 6432

# Проверка подключения через pgbouncer
PGPASSWORD=monitoring_password psql -U rebrain_monitoring -h localhost -p 6432 -d rebrain_courses_db -c "\conninfo"
```

## 21. Нагрузочный тест без pgbouncer
```bash
# Тест напрямую через PostgreSQL (порт 5432)
pgbench -U rebrain_monitoring -h localhost -p 5432 -d rebrain_courses_db -c 900 -j 5 -T 180
```

## 22. Нагрузочный тест с pgbouncer
```bash
# Тест через pgbouncer (порт 6432)
pgbench -U rebrain_monitoring -h localhost -p 6432 -d rebrain_courses_db -c 900 -j 5 -T 180
```
## 23. Анализ результатов

После проведения тестов проверьте в Grafana:

1. Dashboard node_exporter (1860):
   - Нагрузку на CPU
   - Использование памяти
   - Сетевую активность

2. Dashboard postgres_exporter (9628):
   - Количество активных соединений
   - Количество транзакций в секунду (TPS)
   - Время выполнения запросов

Ожидаемые результаты:
- С pgbouncer:
  - Меньшая нагрузка на CPU
  - Количество соединений не превышает default_pool_size (30)
  - Более высокий TPS

- Без pgbouncer:
  - Более высокая нагрузка на CPU
  - Большее количество соединений
  - Более низкий TPS

