select
    instrument_id,
    ticker,
    asset_class,
    exchange,
    currency,
    is_active::boolean as is_active
from {{ ref('svc_investment_signals.raw.instruments') }}
