select
    instrument_id,
    price_ts::timestamp as price_ts,
    price::numeric(18, 4) as price,
    volume::numeric(18, 2) as volume
from {{ ref('svc_investment_signals.raw.prices') }}
