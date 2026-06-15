# investment-signals analytics

Локальный аналитический слой поверх данных `investment-signals`.

Пример отвечает на прикладные вопросы, которые возникают после расчета торговых сигналов:

- какие сигналы были полезными, а какие похожи на шум;
- какие типы сигналов исторически надежнее по каждому инструменту;
- какие свежие сигналы можно отправить в ручную проверку, а какие лучше пропустить;
- где в потоке котировок есть аномальные движения цены или объема;
- были ли проблемы загрузки данных перед расчетом сигналов;
- не испорчена ли торговая идея задержкой или ошибкой в пайплайне.

## Что входит в пример

- `raw_prices` - пример тиков/свечей по инструментам;
- `raw_signals` - сигналы, рассчитанные production-пайплайном;
- `raw_pipeline_events` - события загрузки и обработки данных;
- `raw_instruments` - справочник инструментов;
- `staging` - приведение типов и базовая нормализация;
- `intermediate` - привязка сигналов к цене в момент сигнала и после него;
- `marts` - витрины для анализа качества сигналов и состояния пайплайна.

## Режимы запуска

Автономный режим нужен, чтобы быстро проверить dbt-модели без внешних сервисов. Он использует seed-данные из этого репозитория.

Связанный режим нужен для проверки реального сценария: `investment-signals` пишет сигналы в свой Postgres, а `dbt-af` строит аналитические витрины в той же базе.

## Автономный запуск

Из папки `examples`:

```bash
docker compose run --rm airflow-cli bash -lc '
  cd /opt/airflow/dags
  dbt seed --project-dir /opt/airflow/dags --profiles-dir /opt/airflow/dags --target dev
  dbt build --select svc_investment_signals+ --project-dir /opt/airflow/dags --profiles-dir /opt/airflow/dags --target dev
'
```

Затем можно открыть Airflow:

```bash
docker compose up --build
```

Airflow UI: `http://localhost:8080`

Логин/пароль по умолчанию: `airflow` / `airflow`.

## Связанный запуск с investment-signals

Из корня репозитория `dbt-af`:

```bash
./examples/run_linked_investment_signals_analytics.sh
```

Скрипт выполняет полный локальный контур:

- поднимает Postgres из соседнего репозитория `investment-signals`;
- создает `.env` из `.env.example`, если он еще не создан;
- добавляет несколько контрольных сигналов в `public.market_signals`;
- запускает dbt из контейнера `dbt-af` с target `investment_signals`;
- строит live-витрины в схеме `investment_signals_analytics` базы `signal_engine`;
- выводит итоговый список решений из `mart_live_trading_watchlist`.

Если `investment-signals` лежит не рядом с `dbt-af`, путь можно передать явно:

```bash
INVESTMENT_SIGNALS_REPO=/path/to/investment-signals ./examples/run_linked_investment_signals_analytics.sh
```

Подключение dbt к внешнему Postgres настраивается переменными `INVESTMENT_SIGNALS_POSTGRES_HOST`, `INVESTMENT_SIGNALS_POSTGRES_PORT`, `INVESTMENT_SIGNALS_POSTGRES_DB`, `INVESTMENT_SIGNALS_POSTGRES_USER`, `INVESTMENT_SIGNALS_POSTGRES_PASSWORD` и `INVESTMENT_SIGNALS_POSTGRES_SCHEMA`.

## Главные витрины

- `mart_signal_effectiveness` - оценка движения цены после сигнала;
- `mart_signal_quality` - качество и покрытие сигналов;
- `mart_signal_reliability` - надежность типа сигнала по инструменту;
- `mart_trading_watchlist` - список сигналов с решением и причиной;
- `mart_market_anomalies` - сильные движения цены и объема;
- `mart_pipeline_health` - задержки, ошибки и пропуски пайплайна.
- `mart_live_trading_watchlist` - live-список решений поверх `public.market_signals` из `investment-signals`;
- `mart_signal_type_quality` - качество типов live-сигналов по тикеру.

## Быстрый торговый срез

После `dbt build` можно посмотреть итоговый список сигналов:

```bash
docker compose exec -T postgres psql -U airflow -d airflow -c '
  select
    ticker,
    signal_type,
    trading_decision,
    decision_score,
    signed_return_1h_pct,
    pipeline_status,
    decision_reason
  from public."svc_investment_signals.mart_trading_watchlist"
  order by decision_score desc;
'
```

Эта витрина не исполняет сделки автоматически. Она отделяет сильные сигналы от шума и показывает, когда сигнал нужно заблокировать из-за проблем с данными.

В примере есть dbt-тесты, которые проверяют, что итоговый срез содержит как минимум один торговый кандидат и как минимум один сигнал, заблокированный из-за проблемы данных. Это защищает демо от ситуации, когда витрина формально строится, но не показывает разные классы решений.

## Зачем здесь dbt-af

`investment-signals` отвечает за сбор данных и генерацию сигналов.
Этот пример показывает, как поверх тех же данных построить проверяемый аналитический слой:

- dbt хранит SQL-логику и тесты качества;
- dbt-af генерирует Airflow DAG-и для запуска моделей;
- Airflow дает ручной rerun отдельных моделей и расписание пересчета витрин.
