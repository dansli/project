create view
  dw.dim_subsidiary as
select
  sub.id as subsidiary_id, -- 主体ID
  sub.name as subsidiary_name, -- 主体名称
  sub.country as subsidiary_country_code, -- 主体国家代码
  sub.currency as subsidiary_currency_id, -- 记账货币代码
  cur.name as subsidiary_currency_name, -- 记账货币名称
  cun.name as subsidiary_country_name, -- 主体国家
from
  ns.subsidiary as sub
  left join ns.currency as cur on sub.currency = cur.id
  left join ns.customrecord_hc_trading_country as cun on sub.country = cun.custrecord_hc_tc_country_code
where
  sub.isinactive = 'F'