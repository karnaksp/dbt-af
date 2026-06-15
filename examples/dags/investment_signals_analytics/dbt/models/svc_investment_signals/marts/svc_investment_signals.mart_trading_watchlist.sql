with effectiveness as (
    select * from {{ ref('svc_investment_signals.mart_signal_effectiveness') }}
),

instruments as (
    select * from {{ ref('svc_investment_signals.stg.instruments') }}
),

reliability as (
    select * from {{ ref('svc_investment_signals.mart_signal_reliability') }}
),

pipeline_health as (
    select * from {{ ref('svc_investment_signals.mart_pipeline_health') }}
),

market_anomalies as (
    select * from {{ ref('svc_investment_signals.mart_market_anomalies') }}
),

signal_context as (
    select
        effectiveness.*,
        instruments.ticker,
        instruments.asset_class,
        reliability.hit_rate_1h,
        reliability.avg_signed_return_1h_pct,
        reliability.reliability_grade,
        coalesce(pipeline_health.health_status, 'healthy') as pipeline_status,
        coalesce(pipeline_health.max_latency_ms, 0) as max_latency_ms,
        max(case when market_anomalies.is_price_anomaly then 1 else 0 end) as has_near_price_anomaly,
        max(case when market_anomalies.is_volume_anomaly then 1 else 0 end) as has_near_volume_anomaly
    from effectiveness
    left join instruments
        on effectiveness.instrument_id = instruments.instrument_id
    left join reliability
        on effectiveness.instrument_id = reliability.instrument_id
        and effectiveness.signal_type = reliability.signal_type
    left join pipeline_health
        on effectiveness.instrument_id = pipeline_health.instrument_id
        and date_trunc('hour', effectiveness.signal_ts) = pipeline_health.event_hour
    left join market_anomalies
        on effectiveness.instrument_id = market_anomalies.instrument_id
        and market_anomalies.price_ts between effectiveness.signal_ts - interval '15 minutes'
            and effectiveness.signal_ts + interval '75 minutes'
    group by
        effectiveness.signal_id,
        effectiveness.instrument_id,
        effectiveness.signal_ts,
        effectiveness.signal_type,
        effectiveness.score,
        effectiveness.reason,
        effectiveness.price_at_signal,
        effectiveness.price_after_1h,
        effectiveness.price_after_1d,
        effectiveness.return_1h_pct,
        effectiveness.return_1d_pct,
        effectiveness.signed_return_1h_pct,
        effectiveness.signed_return_1d_pct,
        effectiveness.is_directionally_correct_1h,
        effectiveness.has_material_1h_move,
        effectiveness.signal_quality_bucket,
        instruments.ticker,
        instruments.asset_class,
        reliability.hit_rate_1h,
        reliability.avg_signed_return_1h_pct,
        reliability.reliability_grade,
        pipeline_health.health_status,
        pipeline_health.max_latency_ms
)

select
    signal_id,
    instrument_id,
    ticker,
    asset_class,
    signal_ts,
    signal_type,
    score,
    reason,
    price_at_signal,
    return_1h_pct,
    return_1d_pct,
    signed_return_1h_pct,
    signed_return_1d_pct,
    signal_quality_bucket,
    hit_rate_1h,
    avg_signed_return_1h_pct,
    reliability_grade,
    pipeline_status,
    max_latency_ms,
    has_near_price_anomaly::boolean as has_near_price_anomaly,
    has_near_volume_anomaly::boolean as has_near_volume_anomaly,
    round(
        (score * 45)
        + (coalesce(hit_rate_1h, 0) * 30)
        + (case when coalesce(avg_signed_return_1h_pct, 0) > 0 then 15 else 0 end)
        + (case when has_near_price_anomaly = 1 or has_near_volume_anomaly = 1 then 10 else 0 end)
        - (case when pipeline_status = 'degraded' then 25 when pipeline_status = 'broken' then 60 else 0 end),
        2
    ) as decision_score,
    case
        when pipeline_status = 'broken' then 'заблокировать_из-за_данных'
        when signal_quality_bucket = 'noise_or_wrong_direction' then 'пропустить'
        when pipeline_status = 'degraded' then 'наблюдать'
        when reliability_grade in ('сильный', 'рабочий')
            and score >= 0.7
            and signed_return_1h_pct > 0
            then 'кандидат'
        else 'наблюдать'
    end as trading_decision,
    case
        when pipeline_status = 'broken' then 'есть ошибка доставки или расчета; сигнал нельзя использовать без перепроверки'
        when signal_quality_bucket = 'noise_or_wrong_direction' then 'движение после сигнала не подтвердило направление'
        when pipeline_status = 'degraded' then 'были задержки загрузки данных; нужен ручной контроль цены'
        when reliability_grade = 'мало_наблюдений' then 'недостаточно истории по такому типу сигнала'
        when reliability_grade in ('сильный', 'рабочий') and signed_return_1h_pct > 0 then 'направление и ближайшее движение подтверждают сигнал'
        else 'сигнал не противоречит данным, но силы подтверждения недостаточно'
    end as decision_reason
from signal_context
