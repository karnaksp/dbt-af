# dbt-af Tutorial

## Quick Start
### Prerequisites
1. Running instance of Airflow. There are a few ways to get this. The easiest is to use the Docker Compose to get a local instance running. See [docs](using_docker_compose.md) for more information.
2. Install `dbt-af` if you are not using the Docker Compose method.
    - via pip: `pip install dbt-af[tests,examples]`
3. Build dbt manifest. You can use the provided [script](./dags/build_manifest.sh) to build the manifest.
    ```bash
    cd examples/dags
    ./build_manifest.sh
    ```
4. Add `dbt_dev` and `dbt_sensor_pool` [pools](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/pools.html) to Airflow.
   The Docker Compose demo creates both pools automatically in `airflow-init`.

    - By using Airflow UI ![Airflow Pools](../docs/static/add_new_af_pool.png)
    - By using Airflow CLI:
      `airflow pools set dbt_dev 4 "dev"` and `airflow pools set dbt_sensor_pool 4 "sensor"`

    Start with some small numbers of open slots in pools. 
    If you are using your local machine, a large number of tasks can overflow your machine's resources.

5. To run the local orchestration smoke, use [Running Airflow with Docker](using_docker_compose.md).

## List of Examples
1. [Basic Project](basic_project.md): a single domain, small tests, and a single target.
2. [Advanced Project](advanced_project.md): several domains, medium and large tests, and different targets.
3. [Dependencies management](dependencies_management.md): how to manage dependencies between models in different domains.
4. [Manual scheduling](manual_scheduling.md): domains with manual scheduling.
5. [Maintenance and source freshness](maintenance_and_source_freshness.md): how to manage maintenance tasks and source freshness.
6. [Python Venv Tasks](python_venv_tasks.md): how to run custom dbt models in Python Virtual Environments.
7. [Kubernetes tasks](kubernetes_tasks.md): how to run dbt models in Kubernetes.
8. [Integration with other tools](integration_with_other_tools.md): how to integrate dbt-af with other tools.
9. [\[Preview\] Extras and scripts](extras_and_scripts.md): available extras and scripts.
10. [investment-signals analytics](dags/investment_signals_analytics/README.md): локальный стенд для анализа качества и пользы рыночных сигналов. Поддерживает автономный запуск на seed-данных и связанный запуск поверх Postgres из `investment-signals`.

## Аналитические витрины

В `examples` есть отдельный сервис `analytics-dashboard` на базе Lightdash.
Он читает dbt-проект, использует описания моделей из `schema.yml` и показывает
BI-слой поверх готовых dbt-мартов. Для локального self-host запуска рядом
поднимается MinIO: Lightdash использует его как S3-совместимое хранилище.

Запуск:

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

Первая подключенная витрина:

```text
http://localhost:18083
```

При первом запуске Lightdash попросит создать пользователя и проект.

### Как добавить новую аналитику

1. Добавить dbt-модели в `examples/dags/<service_name>/dbt/models`.
2. Добавить target/source в `examples/dags/profiles.yml`, если нужна новая база.
3. Добавить DAG в `examples/dags`, если модели должны запускаться через Airflow.
4. Описать модели, колонки, измерения и метрики в dbt `schema.yml`.
5. Обновить проект в Lightdash.

Файлы Lightdash:

- `examples/lightdash/README.md` — запуск и подключение проекта;
- `examples/dags/investment_signals_live/dbt/models/.../schema.yml` — описания моделей, измерения и метрики для Lightdash.

Так репозиторий остается универсальным: Airflow оркестрирует dbt, dbt строит
март-таблицы, а Lightdash строит исследуемый BI-слой из dbt `schema.yml`.

### Сигналы T-Invest

Связанный запуск с `investment-signals` обновляет итоговые dbt-таблицы в Postgres
репозитория `investment-signals`, в схеме `investment_signals_analytics`.

```bash
cd ../dbt-af
./examples/run_linked_investment_signals_analytics.sh
```

После этого данные доступны в Lightdash после обновления проекта.

Статический HTML-снапшот можно собрать отдельно:

```bash
python examples/build_investment_signals_dashboard.py
```

По умолчанию файл появится здесь:

```text
outputs/investment_signals_marts_dashboard.html
```

Для просмотра через браузер:

```bash
cd outputs
python -m http.server 18082 --bind 127.0.0.1
```

Открыть:

```text
http://127.0.0.1:18082/investment_signals_marts_dashboard.html
```

Отдельного постоянно работающего контейнера `dbt` в этом сценарии нет. dbt запускается
одноразовой командой внутри compose-образа Airflow, обновляет модели и завершается.
Постоянно работают контейнеры Airflow, Postgres и Redis; Airflow UI доступен на
`http://localhost:18080`.
