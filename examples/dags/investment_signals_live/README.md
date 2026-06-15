# investment-signals live analytics

Этот набор моделей читает таблицу `public.market_signals` из Postgres сервиса `investment-signals` и строит аналитические витрины в схеме `investment_signals_analytics`.

## Зачем это нужно

`investment-signals` находит рыночные события и записывает сигналы. Live-модели в `dbt-af` превращают поток сигналов в проверяемый аналитический слой:

- какие сигналы можно брать в ручную проверку;
- какие сигналы сильные, но заблокированы правилом доставки;
- какие типы сигналов дают слишком много шума;
- насколько хорошо работает контроль качества перед доставкой.

## Запуск

Из корня `dbt-af`:

```bash
./examples/run_linked_investment_signals_analytics.sh
```

Скрипт поднимает Postgres из `investment-signals`, добавляет контрольные live-сигналы, запускает dbt target `investment_signals` и печатает итоговую витрину.

## Витрины

- `svc_investment_signals_live.stg_market_signals` - нормализованный слой над `public.market_signals`;
- `svc_investment_signals_live.mart_live_trading_watchlist` - рабочий список сигналов с решением и причиной;
- `svc_investment_signals_live.mart_signal_type_quality` - качество типов сигналов по тикеру.
