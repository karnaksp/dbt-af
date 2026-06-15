with effectiveness as (
    select * from {{ ref('svc_investment_signals.mart_signal_effectiveness') }}
),

instruments as (
    select * from {{ ref('svc_investment_signals.stg.instruments') }}
)

select
    effectiveness.instrument_id,
    instruments.ticker,
    instruments.asset_class,
    effectiveness.signal_type,
    count(*) as signals_cnt,
    round(avg(effectiveness.score), 4) as avg_score,
    round(avg(effectiveness.signed_return_1h_pct), 4) as avg_signed_return_1h_pct,
    round(avg(effectiveness.signed_return_1d_pct), 4) as avg_signed_return_1d_pct,
    round(
        sum(case when effectiveness.is_directionally_correct_1h then 1 else 0 end)::numeric
        / nullif(count(*), 0),
        4
    ) as hit_rate_1h,
    round(
        sum(case when effectiveness.signal_quality_bucket = 'useful' then 1 else 0 end)::numeric
        / nullif(count(*), 0),
        4
    ) as useful_signal_ratio,
    case
        when count(*) < 2 then 'мало_наблюдений'
        when avg(effectiveness.signed_return_1h_pct) >= 0.7
            and sum(case when effectiveness.is_directionally_correct_1h then 1 else 0 end)::numeric / nullif(count(*), 0) >= 0.75
            then 'сильный'
        when avg(effectiveness.signed_return_1h_pct) > 0
            and sum(case when effectiveness.is_directionally_correct_1h then 1 else 0 end)::numeric / nullif(count(*), 0) >= 0.5
            then 'рабочий'
        else 'слабый'
    end as reliability_grade
from effectiveness
left join instruments
    on effectiveness.instrument_id = instruments.instrument_id
group by
    effectiveness.instrument_id,
    instruments.ticker,
    instruments.asset_class,
    effectiveness.signal_type
