# LABELS: dag, airflow (нужно для Airflow dag-processor)
import pendulum

from dbt_af.conf import Config, DbtDefaultTargetsConfig, DbtProjectConfig
from dbt_af.dags import compile_dbt_af_dags


config = Config(
    dbt_project=DbtProjectConfig(
        dbt_project_name='investment_signals_live',
        dbt_project_path='/opt/airflow/dags',
        dbt_models_path='/opt/airflow/dags/investment_signals_live/dbt/models',
        dbt_profiles_path='/opt/airflow/dags',
        dbt_target_path='/opt/airflow/dags/target',
        dbt_log_path='/opt/airflow/dags/logs',
        dbt_schema='investment_signals_analytics',
    ),
    dbt_default_targets=DbtDefaultTargetsConfig(default_target='investment_signals'),
    dag_start_date=pendulum.yesterday(),
    dry_run=False,
)

dags = compile_dbt_af_dags(
    manifest_path='/opt/airflow/dags/target/manifest.json',
    config=config,
    etl_service_name='investment_signals_live',
)

for dag_name, dag in dags.items():
    globals()[dag_name] = dag
