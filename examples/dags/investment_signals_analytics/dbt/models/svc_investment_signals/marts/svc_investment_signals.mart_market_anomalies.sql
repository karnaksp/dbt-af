with prices as (
    select * from {{ ref('svc_investment_signals.stg.price_ticks') }}
),

with_lag as (
    select
        instrument_id,
        price_ts,
        price,
        volume,
        lag(price) over (partition by instrument_id order by price_ts) as previous_price,
        lag(volume) over (partition by instrument_id order by price_ts) as previous_volume
    from prices
)

select
    instrument_id,
    price_ts,
    price,
    previous_price,
    round((price - previous_price) / nullif(previous_price, 0) * 100, 4) as price_change_pct,
    volume,
    previous_volume,
    round(volume / nullif(previous_volume, 0), 4) as volume_ratio,
    case
        when abs((price - previous_price) / nullif(previous_price, 0) * 100) >= 1.0 then true
        else false
    end as is_price_anomaly,
    case
        when volume / nullif(previous_volume, 0) >= 1.8 then true
        else false
    end as is_volume_anomaly
from with_lag
where previous_price is not null
  and (
    abs((price - previous_price) / nullif(previous_price, 0) * 100) >= 1.0
    or volume / nullif(previous_volume, 0) >= 1.8
  )
