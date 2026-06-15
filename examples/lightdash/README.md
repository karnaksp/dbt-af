# Lightdash

Lightdash используется как готовый BI-слой поверх dbt-мартов.

В этом стенде роли разделены так:

- Airflow запускает dbt-модели.
- dbt строит mart-таблицы в warehouse.
- Lightdash читает dbt-проект и показывает explores/дашборды поверх моделей.
- MinIO дает локальное S3-совместимое хранилище, которое требуется Lightdash для self-host запуска.

## Запуск

```bash
cd examples
POSTGRES_HOST_PORT=15432 \
AIRFLOW_WEBSERVER_HOST_PORT=18080 \
ANALYTICS_DASHBOARD_HOST_PORT=18083 \
docker compose up -d analytics-dashboard
```

Открыть:

```text
http://localhost:18083
```

MinIO console:

```text
http://localhost:19001
```

Локальные учетные данные MinIO по умолчанию:

- login: `minioadmin`
- password: `minioadmin`

## Подключение проекта

В UI Lightdash создать проект по локальному dbt-проекту:

- dbt project dir: `/opt/dbt-af/dags`
- profiles dir: `/opt/dbt-af/dags`
- target: `investment_signals`
- warehouse: Postgres `investment-signals`

Эти же значения уже передаются в контейнер:

- `DBT_PROJECT_DIR=/opt/dbt-af/dags`
- `DBT_PROFILES_DIR=/opt/dbt-af/dags`
- `DBT_TARGET=investment_signals`

Переменные подключения уже передаются в контейнер:

- `INVESTMENT_SIGNALS_POSTGRES_HOST`
- `INVESTMENT_SIGNALS_POSTGRES_PORT`
- `INVESTMENT_SIGNALS_POSTGRES_DB`
- `INVESTMENT_SIGNALS_POSTGRES_USER`
- `INVESTMENT_SIGNALS_POSTGRES_PASSWORD`

Переменные локального S3-хранилища:

- `S3_ENDPOINT=http://minio:9000`
- `S3_PUBLIC_ENDPOINT=http://localhost:19000`
- `S3_BUCKET=lightdash`
- `S3_REGION=us-east-1`
- `S3_FORCE_PATH_STYLE=true`

## Как добавлять аналитику

1. Добавить dbt-модель в `examples/dags/<service_name>/dbt/models`.
2. Описать модель и колонки в `schema.yml`.
3. Добавить Lightdash metadata в dbt `schema.yml`: описания колонок, измерения и метрики.
4. Запустить dbt build.
5. Обновить проект в Lightdash.
