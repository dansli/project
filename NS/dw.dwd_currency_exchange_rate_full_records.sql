replace into dw.dwd_currency_exchange_rate_full_records
with exchange_rate_full_days as (   
 select
     zdate,
     basecurrency,
     transactioncurrency
 from ns.zcaldate as a -- 使用zcaldate避免某个货币的汇率正好缺少月最后一天的数据
 left join
 (   select
         basecurrency,
         transactioncurrency,
         min(effective_date) as min_effectivedate,
         max(effective_date) as max_effectivedate
     from dw.dwd_currency_exchange_rate_records
     group by basecurrency, transactioncurrency
     ) as b on 1 = 1
where zdate >= min_effectivedate
AND zdate <= max_effectivedate
and zdate > date_sub(current_date, ${update_days})
),

exchange_rate_full_days_records as (   
 select
    a.zdate as effective_date,
    a.basecurrency as basecurrency,
    a.transactioncurrency as transactioncurrency,
    b.direct_quotation as direct_quotation,
    b.direct_quotation_include_manual as direct_quotation_include_manual
from exchange_rate_full_days as a
left join dw.dwd_currency_exchange_rate_records as b
    on a.basecurrency = b.basecurrency
    and a.transactioncurrency = b.transactioncurrency
    and a.zdate = b.effective_date
),

exchange_rate_full_lastday_records as (
select
effective_date,
basecurrency,
transactioncurrency,
direct_quotation,
direct_quotation_include_manual
from exchange_rate_full_days_records
where effective_date = last_day(effective_date) -- 取每个月的最后一天
 )   

select
    a.effective_date as effective_date,
    a.basecurrency as basecurrency,
    a.transactioncurrency as transactioncurrency,
    coalesce(a.direct_quotation, b.direct_quotation) as direct_quotation,
    coalesce(a.direct_quotation_include_manual, b.direct_quotation_include_manual) as direct_quotation_include_manual,
    coalesce(b.direct_quotation,a.direct_quotation) as direct_quotation_premon
 from exchange_rate_full_days_records as a
 left join exchange_rate_full_lastday_records as b 
    on a.basecurrency = b.basecurrency
    and a.transactioncurrency = b.transactioncurrency
    and date_format(a.effective_date, 'yyyy-MM') = date_format(b.effective_date + interval 1 month, 'yyyy-MM')