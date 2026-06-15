#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

docker compose config --quiet

docker compose run --rm --build airflow-cli bash -lc '
  cd /opt/airflow/dags
  dbt clean --no-clean-project-files-only --project-dir /opt/airflow/dags --profiles-dir /opt/airflow/dags --target dev
  dbt deps --debug --project-dir /opt/airflow/dags --profiles-dir /opt/airflow/dags --target dev
  dbt parse --debug --project-dir /opt/airflow/dags --profiles-dir /opt/airflow/dags --target dev
  dbt seed --project-dir /opt/airflow/dags --profiles-dir /opt/airflow/dags --target dev --select svc_investment_signals.raw.instruments svc_investment_signals.raw.prices svc_investment_signals.raw.signals svc_investment_signals.raw.pipeline_events
  dbt build --project-dir /opt/airflow/dags --profiles-dir /opt/airflow/dags --target dev --select svc_investment_signals+
'

docker compose up --force-recreate -d --build

echo "Waiting for Airflow webserver health..."
webserver_ready=false
for _ in {1..60}; do
  if docker compose exec -T airflow-webserver curl --fail --silent http://localhost:8080/health >/dev/null; then
    webserver_ready=true
    break
  fi
  sleep 5
done
if [[ "${webserver_ready}" != "true" ]]; then
  echo "Airflow webserver did not become healthy in time." >&2
  docker compose ps
  exit 1
fi

docker compose exec -T airflow-webserver airflow pools list
docker compose exec -T airflow-webserver airflow dags list | grep -E 'dbt_af_project|investment_signals_analytics|dbt_run_model'
docker compose exec -T airflow-webserver airflow tasks list dbt_af_project_dbt_run_model
docker compose exec -T airflow-webserver airflow tasks list investment_signals_analytics_dbt_run_model

echo "dbt-af orchestration demo smoke passed."
