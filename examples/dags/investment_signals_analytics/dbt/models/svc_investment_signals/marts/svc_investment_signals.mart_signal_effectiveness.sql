with signal_windows as (
    select * from {{ ref('svc_investment_signals.int_signal_price_windows') }}
),

classified as (
    select
        *,
        case
            when signal_type = 'bullish_momentum' then return_1h_pct
            when signal_type = 'bearish_momentum' then -return_1h_pct
        end as signed_return_1h_pct,
        case
            when signal_type = 'bullish_momentum' then return_1d_pct
            when signal_type = 'bearish_momentum' then -return_1d_pct
        end as signed_return_1d_pct,
        case
            when signal_type = 'bullish_momentum' and return_1h_pct > 0 then true
            when signal_type = 'bearish_momentum' and return_1h_pct < 0 then true
            else false
        end as is_directionally_correct_1h,
        case
            when abs(return_1h_pct) >= 0.5 then true
            else false
        end as has_material_1h_move
    from signal_windows
)

select
    signal_id,
    instrument_id,
    signal_ts,
    signal_type,
    score,
    reason,
    price_at_signal,
    price_after_1h,
    price_after_1d,
    return_1h_pct,
    return_1d_pct,
    signed_return_1h_pct,
    signed_return_1d_pct,
    is_directionally_correct_1h,
    has_material_1h_move,
    case
        when is_directionally_correct_1h and has_material_1h_move then 'useful'
        when is_directionally_correct_1h then 'weak_positive'
        else 'noise_or_wrong_direction'
    end as signal_quality_bucket
from classified
