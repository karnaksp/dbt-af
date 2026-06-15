with candidates as (
    select count(*) as signals_cnt
    from {{ ref('svc_investment_signals.mart_trading_watchlist') }}
    where trading_decision = 'кандидат'
)

select *
from candidates
where signals_cnt = 0
