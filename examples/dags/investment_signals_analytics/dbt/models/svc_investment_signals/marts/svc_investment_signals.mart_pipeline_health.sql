with events as (
    select * from {{ ref('svc_investment_signals.stg.pipeline_events') }}
)

select
    date_trunc('hour', event_ts) as event_hour,
    instrument_id,
    count(*) as events_cnt,
    sum(case when status = 'ok' then 1 else 0 end) as ok_events_cnt,
    sum(case when status = 'late' then 1 else 0 end) as late_events_cnt,
    sum(case when status = 'error' then 1 else 0 end) as error_events_cnt,
    max(latency_ms) as max_latency_ms,
    round(avg(latency_ms), 2) as avg_latency_ms,
    case
        when sum(case when status = 'error' then 1 else 0 end) > 0 then 'broken'
        when sum(case when status = 'late' then 1 else 0 end) > 0 then 'degraded'
        else 'healthy'
    end as health_status
from events
group by 1, 2
