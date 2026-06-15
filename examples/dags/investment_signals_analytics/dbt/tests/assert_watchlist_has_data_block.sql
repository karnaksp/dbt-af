with blocked_signals as (
    select count(*) as signals_cnt
    from {{ ref('svc_investment_signals.mart_trading_watchlist') }}
    where trading_decision = 'заблокировать_из-за_данных'
)

select *
from blocked_signals
where signals_cnt = 0
