delete from ns.zods_saledetail where tran_day>=date_format(CURDATE + interval - 92 day,'yyyyMMdd');
replace ns.zods_saledetail
with t1 as (
  select 
    tr.id transaction_id,
    trl.ID transaction_line_id,
    type netsuite_trans_type,
    tr.trandate tran_date,
    date_format(tr.trandate,'yyyyMM') tran_month,
    date_format(tr.trandate,'yyyy') tran_year,
    trl.subsidiary subsidiary,
    sub.name subsidiary_name,
    cuy.name subsidiary_country,
    custentity_inter_regional_segmentation subsidiary_continent,
    cum.id customer_id,
    cum.entityid customer_code,
    cum.altname customer_name,
    custentity_pm_store_seat customer_city
         ,cum.country_name customer_country
         ,custentity_inter_regional_segmentation customer_continent,categoryname customer_category,categoryname2 customer_2nd_cat_name
         ,customer_3nd_cat_name customer_3nd_cat_name
         ,transactionnumber transaction_number,tr.tranid tran_id,tr.currency currency_id,vii.name currency_name
         ,curr.exchangerate currency_rate,ctr.name sale_country,itm.itemID item_code,itm.displayname item_name
         ,case when trl.itemtype='InvtPart' then trl.quantity*-1 else 0 end as product_count
         ,case when tax.taxline_type in('有税率有税金','无税率有税金') then trl.foreignamount*-1
               when tax.taxline_type in('有税率无税金') then (trl.foreignamount*-1)*(1-tax.ratepercent)
               when tax.taxline_type is null then trl.foreignamount*-1
               else 0
          end as foreign_amount
         ,case when tax.taxline_type in('有税率有税金','无税率有税金') then trl.foreignamount*-1*curr.exchangerate
               when tax.taxline_type in('有税率无税金') then (trl.foreignamount*-1)*(1-tax.ratepercent)*curr.exchangerate
               when tax.taxline_type is null then trl.foreignamount*-1*curr.exchangerate
               else 0
          end as rmb_amount
         ,case when custrecord_bi_budget_amount is not null then 1 else 0 end as is_target
         ,date_format(tr.trandate,'yyyyMMdd') tran_day
         ,case when tax.taxline_type in('有税率有税金','无税率有税金') then trl.foreignamount*-1
               when tax.taxline_type in('有税率无税金') then (trl.foreignamount*-1)*(1-tax.ratepercent)
               when tax.taxline_type is null then trl.foreignamount*-1
               else 0
          end as excl_tax_foreign_amount
         ,case when tax.taxline_type in('有税率有税金','无税率有税金') and nvl(tax.tot_amount,0)<>0 then (trl.foreignamount*-1/tax.tot_amount)*tax.tax_amount
               when tax.taxline_type in('有税率无税金') then (trl.foreignamount*-1)*tax.ratepercent
               when tax.taxline_type is null then 0
               else 0
          end as tax_amount
         ,case when tax.taxline_type in('有税率有税金','无税率有税金') and nvl(tax.tot_amount,0)<>0 then trl.foreignamount*-1 + (trl.foreignamount*-1/tax.tot_amount)*tax_amount
               when tax.taxline_type in('有税率无税金') then trl.foreignamount*-1
               when tax.taxline_type is null then trl.foreignamount*-1
               else 0
          end as incl_tax_foreign_amount
         ,case when tax.taxline_type in('有税率有税金','无税率有税金') then trl.foreignamount*-1*curr.exchangerate
               when tax.taxline_type in('有税率无税金') then (trl.foreignamount*-1)*(1-tax.ratepercent)*curr.exchangerate
               when tax.taxline_type is null then (trl.foreignamount*-1)*curr.exchangerate
               else 0
          end as excl_tax_rmb_amount
         ,case when tax.taxline_type in('有税率有税金','无税率有税金') and nvl(tax.tot_amount,0)<>0 then (trl.foreignamount*-1/tax.tot_amount)*tax_amount*curr.exchangerate
               when tax.taxline_type in('有税率无税金') then (trl.foreignamount*-1)*tax.ratepercent*curr.exchangerate
               when tax.taxline_type is null then 0
               else 0
          end as tax_rmb_amount
         ,case when tax.taxline_type in('有税率有税金','无税率有税金') and nvl(tax.tot_amount,0)<>0 then ((trl.foreignamount*-1 + (trl.foreignamount*-1/tax.tot_amount)*tax_amount))*curr.exchangerate 
               when tax.taxline_type in('有税率无税金') then (trl.foreignamount*-1)*curr.exchangerate
               when tax.taxline_type is null then (trl.foreignamount*-1)*curr.exchangerate
          end as incl_tax_rmb_amount
         ,case when tax.taxline_type is null then '无税率无税金' else tax.taxline_type end as remark
         ,tr.recordtype,tr.billingStatus,tr.status,trl.isclosed,trl.iscogs,trl.isinventoryaffecting,trl.itemtype
         ,case when tr.recordtype in('salesorder','returnauthorization') then 1 when tr.recordtype in('invoice','creditmemo') then 2 end as custrecord_bi_budget_order_type,bgt.custrecord_bi_budget_order_type budget_type
         ,tr.abbrevtype,stu.type_txt,stu.status_txt
         ,case when tr.recordtype in('creditmemo','returnauthorization') then 1 else 0 end as tran_type
  from ns.transactionline trl 
  left join ns.transaction tr on tr.id=trl.TRANSACTION     -- 销售主表及行项目表
  left join ns.Subsidiary sub on sub.id = trl.subsidiary   -- 子公司
  left join ns.ZODS_CUSTOMER cum on cum.id = tr.entity          -- 客户
  left join ns.CUSTOMRECORD_HC_TRADING_COUNTRY ctr on ctr.custrecord_hc_tc_name_en = tr.custbody_pm_transaction_country -- 国家
  left join ns.item gd on trl.item=gd.id -- 商品
  left join ns.location lc on trl.location=lc.id
  left join (select bcurry,id,exchangerate1,exchangerate,zdate from ns.zods_currency) curr on tr.currency=curr.bcurry and date_format(tr.trandate,'yyyyMMdd')=curr.zdate
  left join ns.item itm on trl.item=itm.ID
  left join ns.ZODS_TAXANDTOTSEL tax on tr.trandate=tax.trandate and tr.tranid=tax.tranid
  left join (
    select 
      custrecord_bi_budget_order_type,
      custrecord_bi_budget_month,
      custrecord_bi_budget_customer,
      custrecord_bi_budget_subsidiary,
      SUM(custrecord_bi_budget_amount) as custrecord_bi_budget_amount
    FROM ns.ZODS_BUDGET
    group by 
      custrecord_bi_budget_order_type,
      custrecord_bi_budget_month,
      custrecord_bi_budget_customer,
      custrecord_bi_budget_subsidiary
  ) as bgt 
  on date_format(bgt.custrecord_bi_budget_month, 'yyyy-MM') = date_format(tr.trandate,'yyyy-MM') and bgt.custrecord_bi_budget_customer = tr.entity and trl.subsidiary = bgt.custrecord_bi_budget_subsidiary
                           left join ns.currency vii on vii.id = tr.currency
                           left join ns.zods_trstatus stu on tr.recordtype=stu.abbrevtype and tr.status=stu.status
                           left join ns.CUSTOMRECORD_HC_TRADING_COUNTRY cuy on sub.country=cuy.custrecord_hc_tc_country_code
  where tr.recordtype in ('invoice','creditmemo','salesorder','returnauthorization')
        and trl.itemtype not in ('EndGroup','TaxGroup','TaxItem','Service')
        and trl.isinventoryaffecting = 'F'
        and trl.IsCogs = 'F'
)
select TRANSACTION_ID,TRANSACTION_LINE_ID,NETSUITE_TRANS_TYPE,TRAN_DATE,TRAN_MONTH,TRAN_YEAR,SUBSIDIARY,SUBSIDIARY_NAME,SUBSIDIARY_COUNTRY,SUBSIDIARY_CONTINENT,CUSTOMER_ID
       ,CUSTOMER_CODE,CUSTOMER_NAME,CUSTOMER_CITY,CUSTOMER_COUNTRY,CUSTOMER_CONTINENT,CUSTOMER_CATEGORY,CUSTOMER_2ND_CAT_NAME,CUSTOMER_3ND_CAT_NAME,TRANSACTION_NUMBER
       ,TRAN_ID,CURRENCY_ID,CURRENCY_NAME,CURRENCY_RATE,SALE_COUNTRY,ITEM_CODE,ITEM_NAME,PRODUCT_COUNT,FOREIGN_AMOUNT,RMB_AMOUNT
       ,case when CUSTRECORD_BI_BUDGET_ORDER_TYPE=BUDGET_TYPE then 1 else 0 end as IS_TARGET,TRAN_DAY,EXCL_TAX_FOREIGN_AMOUNT
       ,TAX_AMOUNT,INCL_TAX_FOREIGN_AMOUNT,EXCL_TAX_RMB_AMOUNT,TAX_RMB_AMOUNT,INCL_TAX_RMB_AMOUNT,REMARK,RECORDTYPE,BILLINGSTATUS,STATUS,ISCLOSED,ISCOGS,ISINVENTORYAFFECTING
       ,ITEMTYPE,CUSTRECORD_BI_BUDGET_ORDER_TYPE,BUDGET_TYPE,ABBREVTYPE,TYPE_TXT,STATUS_TXT,TRAN_TYPE
from t1
where tran_day>=date_format(CURDATE + interval - 92 day,'yyyyMMdd');
