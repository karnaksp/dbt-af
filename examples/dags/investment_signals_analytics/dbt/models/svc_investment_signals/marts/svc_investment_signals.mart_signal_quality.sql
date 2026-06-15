with signals as (
    select * from {{ ref('svc_investment_signals.stg.signals') }}
),

prices as (
    select * from {{ ref('svc_investment_signals.stg.price_ticks') }}
),

price_bounds as (
    select
        instrument_id,
        min(price_ts) as first_price_ts,
        max(price_ts) as last_price_ts
    from prices
    group by instrument_id
),

instruments as (
    select * from {{ ref('svc_investment_signals.stg.instruments') }}
),

effectiveness as (
    select * from {{ ref('svc_investment_signals.mart_signal_effectiveness') }}
)

select
    signals.instrument_id,
    instruments.ticker,
    instruments.asset_class,
    count(*) as signals_cnt,
    count(distinct signals.signal_type) as signal_types_cnt,
    round(avg(signals.score), 4) as avg_score,
    sum(case when effectiveness.price_at_signal is null then 1 else 0 end) as signals_without_price_cnt,
    sum(case when effectiveness.signal_quality_bucket = 'useful' then 1 else 0 end) as useful_signals_cnt,
    round(
        sum(case when effectiveness.signal_quality_bucket = 'useful' then 1 else 0 end)::numeric
        / nullif(count(*), 0),
        4
    ) as useful_signal_ratio,
    round(avg(effectiveness.signed_return_1h_pct), 4) as avg_signed_return_1h_pct,
    round(avg(effectiveness.signed_return_1d_pct), 4) as avg_signed_return_1d_pct,
    price_bounds.first_price_ts,
    price_bounds.last_price_ts
from signals
left join effectiveness
    on signals.signal_id = effectiveness.signal_id
left join instruments
    on signals.instrument_id = instruments.instrument_id
left join price_bounds
    on signals.instrument_id = price_bounds.instrument_id
group by
    signals.instrument_id,
    instruments.ticker,
    instruments.asset_class,
    price_bounds.first_price_ts,
    price_bounds.last_price_ts
