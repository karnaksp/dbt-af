with signals as (
    select * from {{ ref('svc_investment_signals.stg.signals') }}
),

signal_prices as (
    select
        signals.signal_id,
        signals.instrument_id,
        signals.signal_ts,
        signals.signal_type,
        signals.score,
        signals.reason,
        price_at_signal.price as price_at_signal,
        price_after_1h.price as price_after_1h,
        price_after_1d.price as price_after_1d
    from signals
    left join lateral (
        select price
        from {{ ref('svc_investment_signals.stg.price_ticks') }} prices
        where prices.instrument_id = signals.instrument_id
          and prices.price_ts <= signals.signal_ts
        order by prices.price_ts desc
        limit 1
    ) price_at_signal on true
    left join lateral (
        select price
        from {{ ref('svc_investment_signals.stg.price_ticks') }} prices
        where prices.instrument_id = signals.instrument_id
          and prices.price_ts >= signals.signal_ts + interval '1 hour'
        order by prices.price_ts asc
        limit 1
    ) price_after_1h on true
    left join lateral (
        select price
        from {{ ref('svc_investment_signals.stg.price_ticks') }} prices
        where prices.instrument_id = signals.instrument_id
          and prices.price_ts >= signals.signal_ts + interval '1 day'
        order by prices.price_ts asc
        limit 1
    ) price_after_1d on true
)

select
    *,
    round((price_after_1h - price_at_signal) / nullif(price_at_signal, 0) * 100, 4) as return_1h_pct,
    round((price_after_1d - price_at_signal) / nullif(price_at_signal, 0) * 100, 4) as return_1d_pct
from signal_prices
