select
    event_id,
    event_ts::timestamp as event_ts,
    event_type,
    instrument_id,
    status,
    latency_ms::integer as latency_ms,
    details
from {{ ref('svc_investment_signals.raw.pipeline_events') }}
