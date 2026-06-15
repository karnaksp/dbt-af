select
    signal_id,
    instrument_id,
    signal_ts::timestamp as signal_ts,
    signal_type,
    score::numeric(8, 4) as score,
    reason
from {{ ref('svc_investment_signals.raw.signals') }}
