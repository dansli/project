replace into dw.dwd_ns_transaction_sale_detail
select 
tr.id as transaction_id,
tr.tranid as transaction_code,
trl.id as transaction_line_id,
tr.transactionnumber as transaction_number,
tr.type as transaction_type,
to_date(tr.trandate) as transaction_date,
trl.subsidiary as subsidiary_id,
tr.entity as entity_id,
trl.item as item_id,
trl.location as location_id,
tr.currency as currency_id,
tr.exchangeRate as transaction_exchange_rate, -- indirect, = subsidiaryCurrency/TransactionCurrency
tr.custbody_pm_transaction_country as sale_country_id,
tr.recordtype as transaction_recordtype,
tr.abbrevtype as transaction_abbrevtype,
trl.itemtype as transaction_line_itemtype,
if(tr.recordtype in ('creditmemo','returnauthorization'), 1,0) as transaction_sale_type,
if(tr.recordtype in('salesorder','returnauthorization'), 1, 2) as transaction_budget_type,
tr.custbody_pm_src_type as transaction_source_type,
trl.foreignamount * -1 as transaction_amount,
sum(trl.foreignamount * -1) over(partition by tr.tranid,tr.trandate) as transaction_total_amount,
-- 为了兼容原数据处理逻辑
if(trl.itemtype = 'InvtPart', trl.foreignamount * -1, 0) as invtpart_amount,
sum(if(trl.itemtype = 'InvtPart', trl.foreignamount * -1, 0)) over(partition by tr.tranid,tr.trandate) as invtpart_total_amount,
trl.quantity * -1 as product_qty,
if(trl.itemtype = 'InvtPart', trl.quantity * -1, 0) as product_invtpart_qty,
-- trl.ratepercent as ratepercent,
tr.status as transaction_status,
tr.billingstatus as transaction_billing_status,
trl.isclosed as transaction_line_isclosed,
tr.createddate as transaction_created_datetime,
tr.lastmodifieddate as transaction_update_datetime,
trl.linelastmodifieddate as transaction_line_update_datetime
from ns.transactionline as trl
left join ns.transaction as tr on tr.id = trl.transaction
where tr.recordtype in ('invoice', 'creditmemo', 'salesorder', 'returnauthorization')
and trl.itemtype not in ('EndGroup','TaxGroup','TaxItem')
and trl.isinventoryaffecting = 'F'
and trl.iscogs = 'F' -- Cost of Goods Sold
and trl.mainline = 'F' -- transactionLine 表里面  mainline  为T的行，可以理解为body的补充信息，不是真是明细行，如果只要明细行数据，可以把这行排除掉
and (tr.lastmodifieddate > date_sub(current_date, ${update_days}) or trl.linelastmodifieddate > date_sub(current_date, ${update_days}) or trandate > date_sub(current_date, ${update_days}))