with all_sales as (
select 
  sd.tran_date,
  sd.customer_name,
  sd.customer_code,
  cmd.CATEGORYNAME,
  cmd.CATEGORYNAME2,
  cmd.SUBSIDIARY_REGIONAL_SEGMENTATION,
  sd.item_name,
  sd.item_code,
  imd.CUSTITEM_PM_UP_DATE,
  imd.IP_TYPE,
  imd.ZBIGTYPE_TXT,
  imd.ZMIDDLETYPE_TXT,
  imd.ZLITTLETYPE_TXT,
  imd.ZBUSINESS1_TXT,
  imd.ZBUSINESS2_TXT,
  imd.ZBUSINESS3_TXT,
  imd.FIRST_CLASS_NAME_CN,
  imd.SECOND_CLASS_NAME_CN,
  imd.IP_NAME,
  sd.SALE_COUNTRY,
  sum(sd.incl_tax_rmb_amount) as incl_tax_rmb_amount,
  sum(sd.product_count) as product_count
  from 
  (select 
 tran_date,
 customer_name,
 customer_code,
 item_name,
 item_code,
 SALE_COUNTRY,
 incl_tax_rmb_amount,
 product_count
 from ns.dws_oversea_order_v2_detail 
 where CUSTOMER_2ND_CAT_NAME IN ('ROBOshop')
 and is_target = 1
 and CUSTRECORD_BI_BUDGET_ORDER_TYPE = 1
 and item_code is not null
 and tran_date between '${start}' and '${end}'
 and 1=1<parameter> and customer_name in('${customer_name}')</parameter>
 and 1=1<parameter> and item_name in('${item_name}')</parameter>
 and 1=1<parameter> and item_code in('${item_code}')</parameter>
 and 1=1<parameter> and SALE_COUNTRY in('${SALE_COUNTRY}')</parameter>
) as sd
left join 
(select entityid,CATEGORYNAME,CATEGORYNAME2,SUBSIDIARY_REGIONAL_SEGMENTATION from ns.zods_customer) as cmd
on sd.customer_code = cmd.entityid
left join 
(select itemid,CUSTITEM_PM_UP_DATE,IP_TYPE,ZBIGTYPE_TXT,ZMIDDLETYPE_TXT,ZLITTLETYPE_TXT,ZBUSINESS1_TXT,ZBUSINESS2_TXT,ZBUSINESS3_TXT,FIRST_CLASS_NAME_CN,SECOND_CLASS_NAME_CN,IP_NAME from ns.dim_oversea_item) as imd
on sd.item_code = imd.itemid
where 
  1=1<parameter> and SUBSIDIARY_REGIONAL_SEGMENTATION in ('${SUBSIDIARY_REGIONAL_SEGMENTATION}')</parameter>
  and 1=1<parameter> and CATEGORYNAME in ('${CATEGORYNAME}')</parameter>
  and 1=1<parameter> and CATEGORYNAME2 in ('${CATEGORYNAME2}')</parameter>
  and 1=1<parameter> and IP_TYPE in ('${IP_TYPE}')</parameter>
  and 1=1<parameter> and IP_NAME in ('${IP_NAME}')</parameter>
  and 1=1<parameter> and ZBIGTYPE_TXT in ('${ZBIGTYPE_TXT}')</parameter>
  and 1=1<parameter> and ZMIDDLETYPE_TXT in ('${ZMIDDLETYPE_TXT}')</parameter>
  and 1=1<parameter> and ZLITTLETYPE_TXT in ('${ZLITTLETYPE_TXT}')</parameter>
  and 1=1<parameter> and ZBUSINESS1_TXT in ('${ZBUSINESS1_TXT}')</parameter>
  and 1=1<parameter> and ZBUSINESS2_TXT in ('${ZBUSINESS2_TXT}')</parameter>
  and 1=1<parameter> and ZBUSINESS3_TXT in ('${ZBUSINESS3_TXT}')</parameter>
  and 1=1<parameter> and FIRST_CLASS_NAME_CN in ('${FIRST_CLASS_NAME_CN}')</parameter>
  and 1=1<parameter> and SECOND_CLASS_NAME_CN in ('${SECOND_CLASS_NAME_CN}')</parameter>
group by 
  sd.tran_date,
  sd.customer_name,
  sd.customer_code,
  cmd.CATEGORYNAME,
  cmd.CATEGORYNAME2,
  cmd.SUBSIDIARY_REGIONAL_SEGMENTATION,
  sd.item_name,
  sd.item_code,
  imd.CUSTITEM_PM_UP_DATE,
  imd.IP_TYPE,
  imd.ZBIGTYPE_TXT,
  imd.ZMIDDLETYPE_TXT,
  imd.ZLITTLETYPE_TXT,
  imd.ZBUSINESS1_TXT,
  imd.ZBUSINESS2_TXT,
  imd.ZBUSINESS3_TXT,
  imd.FIRST_CLASS_NAME_CN,
  imd.SECOND_CLASS_NAME_CN,
  imd.IP_NAME,
  sd.SALE_COUNTRY
),

  new_item_sales as (
  SELECT 
    tran_date,
    customer_code,
    customer_name,
    item_code,
    item_name,
    sale_country,
    sum(incl_tax_rmb_amount) as incl_tax_rmb_amount_new,
    sum(product_count) as product_count_new
    from all_sales 
    where tran_date between '${start}' and '${end}'
    and CUSTITEM_PM_UP_DATE between '${start}' and '${end}'
  group by 
  	tran_date,
    customer_code,
    customer_name,
    item_code,
    item_name,
  sale_country),

full_sales as (
select 
 sum(incl_tax_rmb_amount) as incl_tax_rmb_amount_full,
 sum(product_count) as product_count_full
 from all_sales),

item_md as (
select 
    itemid,
    CUSTITEM_PM_UP_DATE,
    IP_TYPE,
    ZBIGTYPE_TXT,
    ZMIDDLETYPE_TXT,
    ZLITTLETYPE_TXT,
    ZBUSINESS1_TXT,
    ZBUSINESS2_TXT,
    ZBUSINESS3_TXT,
    FIRST_CLASS_NAME_CN,
    SECOND_CLASS_NAME_CN,
    IP_NAME 
from ns.dim_oversea_item),

customer_md as (
select 
    entityid,
    CATEGORYNAME,
    CATEGORYNAME2,
    SUBSIDIARY_REGIONAL_SEGMENTATION 
from ns.zods_customer)


SELECT 
	i.tran_date,
    i.sale_country,
    i.customer_code,
    i.customer_name,
    iv.CATEGORYNAME,
    iv.CATEGORYNAME2,
    iv.SUBSIDIARY_REGIONAL_SEGMENTATION,
    i.item_code,
    i.item_name,
    iii.CUSTITEM_PM_UP_DATE,
    iii.IP_TYPE,
    iii.ZBIGTYPE_TXT,
    iii.ZMIDDLETYPE_TXT,
    iii.ZLITTLETYPE_TXT,
    iii.ZBUSINESS1_TXT,
    iii.ZBUSINESS2_TXT,
    iii.ZBUSINESS3_TXT,
    iii.FIRST_CLASS_NAME_CN,
    iii.SECOND_CLASS_NAME_CN,IP_NAME,
    i.incl_tax_rmb_amount_new,
    i.product_count_new,
    ii.incl_tax_rmb_amount_full,
    ii.product_count_full,
    v.incl_tax_rmb_amount_perday,
    v.product_count_perday
from 
(select * from new_item_sales) as i
left join 
(select * from full_sales) as ii
on 1=1
left join
(select * from item_md) as iii
on i.item_code = iii.itemid
left join 
(select * from customer_md) as iv
on i.customer_code = iv.entityid
left JOIN 
(select tran_date,sum(incl_tax_rmb_amount) as incl_tax_rmb_amount_perday,sum(product_count) as product_count_perday from all_sales group by tran_date) as v
on v.tran_date = i.tran_date