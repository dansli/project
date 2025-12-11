replace into dw.dwd_ns_transaction_sale_tax_detail
select 
   a.transaction_id as transaction_id
  ,a.transaction_line_id as transaction_line_id
  ,a.transaction_number as transaction_number
  ,a.transaction_date as transaction_date
  ,date_format(a.transaction_date, 'yyyy-MM') as transaction_month
  ,date_format(a.transaction_date, 'yyyy') as transaction_year
  ,a.transaction_type as transaction_type
  ,a.transaction_recordtype as transaction_recordtype
  ,a.transaction_abbrevtype as transaction_abbrevtype
  ,a.transaction_sale_type as transaction_sale_type
  ,a.transaction_budget_type as transaction_budget_type
  ,a.transaction_taxtype as transaction_taxtype
  ,a.transaction_status as transaction_status
  ,a.transaction_billing_status as transaction_billing_status
  ,a.transaction_line_itemtype as transaction_line_itemtype
  ,a.transaction_source_type as transaction_source_type
  ,transaction_line_isclosed as transaction_line_isclosed
  ,a.subsidiary_id as subsidiary_id  
  ,a.entity_id as entity_id
  ,a.sale_country_id as sale_country_id
  ,a.transaction_code as transaction_code
  ,a.currency_id as currency_id
  ,a.item_id as item_id
  ,c.direct_quotation as direct_quotation
  ,c.direct_quotation_premon as direct_quotation_premon
  ,a.product_qty as product_qty
  ,a.product_invtpart_qty as product_invtpart_qty
  ,a.transaction_amount as transaction_amount
  ,a.transaction_amount / direct_quotation as transaction_amount_cny
  ,a.tax_amount as tax_amount
  ,a.tax_amount / c.direct_quotation as tax_amount_cny
  ,a.transaction_amount_excl_tax as transaction_amount_excl_tax
  ,transaction_amount_excl_tax + tax_amount as transaction_amount_incl_tax
  ,a.transaction_amount_excl_tax / c.direct_quotation as transaction_amount_excl_tax_cny
  ,(a.transaction_amount_excl_tax + a.tax_amount) / c.direct_quotation as transaction_amount_incl_tax_cny
  ,a.location_id as location_id
  ,if(a.transaction_update_datetime > a.transaction_line_update_datetime, a.transaction_update_datetime, a.transaction_line_update_datetime) as transaction_update_datetime
  ,a.transaction_amount / direct_quotation_premon as transaction_amount_cny_fin
  ,a.tax_amount / c.direct_quotation_premon as tax_amount_cny_fin
  ,a.transaction_amount_excl_tax / c.direct_quotation_premon as transaction_amount_excl_tax_cny_fin
  ,(a.transaction_amount_excl_tax + a.tax_amount) / c.direct_quotation_premon as transaction_amount_incl_tax_cny_fin
  ,transaction_exchange_rate
  ,transaction_amount * transaction_exchange_rate as transaction_amount_subs_currency
  ,tax_amount * transaction_exchange_rate as tax_amount_subs_currency
  ,transaction_amount_excl_tax * transaction_exchange_rate as transaction_amount_excl_tax_subs_currency
  ,(a.transaction_amount_excl_tax + a.tax_amount) * transaction_exchange_rate as transaction_amount_incl_tax_subs_currency
from
(select a.*, nvl(b.transaction_taxtype, '无税率无税金') as transaction_taxtype, b.tax_rate, b.tax_rate_adj
  ,case when b.transaction_taxtype in('有税率有税金','无税率有税金') and nvl(a.transaction_total_amount,0)<>0 then (a.transaction_amount/a.transaction_total_amount)*b.tax_amount
               when b.transaction_taxtype in('有税率无税金') then a.transaction_amount*b.tax_rate_adj
               else 0 end as tax_amount
  ,if( b.transaction_taxtype = '有税率无税金' , a.transaction_amount * (1 - b.tax_rate_adj), a.transaction_amount) as transaction_amount_excl_tax
  from dw.dwd_ns_transaction_sale_detail as a
  left join dw.dwd_ns_transaction_tax_detail as b on a.transaction_id = b.transaction_id) as a
left join dw.dwd_currency_exchange_rate_full_records as c 
    on a.currency_id = c.basecurrency and a.transaction_date = c.effective_date and c.transactioncurrency = 12
where if(a.transaction_update_datetime > a.transaction_line_update_datetime, a.transaction_update_datetime, a.transaction_line_update_datetime) > date_sub(current_date, ${update_days})
or transaction_date > date_sub(current_date, ${update_days})