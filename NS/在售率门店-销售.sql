with sales_date as (
select 
 i.zdate,
 ii.customer_code,
ii.item_code
 from ns.zcaldate as i
 left join (select distinct customer_code,item_code from ns.dws_oversea_order_v2_detail where tran_date between '2025-06-01' and '2025-06-30' and CUSTOMER_2ND_CAT_NAME in ('Store'))as ii
 on 1=1 
 where zdate between '2025-06-01' and '2025-06-30'
)

SELECT 
sale.zdate as 日期,
ii.SUBSIDIARY_REGIONAL_SEGMENTATION as 国家,
cus.cus_name as 门店名称,
sale.customer_code as 门店编码,
sale.item_code as 商品代码,
cus.warehouse_id as 仓库编码,
cus.warehouse_name as 仓库名称,
nvl(i.PRODUCT_COUNT,0) as 销量
from sales_date as sale
left join 
(SELECT 
tran_date,
customer_code,
-- b.customer_name,
-- b.customer_country,
-- b.customer_city,
-- b.customer_2nd_cat_name,
item_code,
-- b.item_name,
sum(PRODUCT_COUNT) as PRODUCT_COUNT
from
ns.dws_oversea_order_v2_detail
where is_target = 1 
and (customer_3nd_cat_name <> '总部跨境电商' or customer_3nd_cat_name is null)
and item_name is not null 
and tran_date between '${start}' and '${end}'
and CUSTOMER_2ND_CAT_NAME in ('Store')
group by 
tran_date,
item_code,
-- i.customer_name,
customer_code
-- cus.warehouse_id,
-- cus.warehouse_name
) as i
on sale.zdate=i.tran_date and sale.customer_code=i.customer_code and sale.item_code=i.item_code
left JOIN 
(select entityid,case when entityid in ('C23563','C23651') then '越南' 
when entityid='C30749' then '印度尼西亚' else SUBSIDIARY_REGIONAL_SEGMENTATION 
end as SUBSIDIARY_REGIONAL_SEGMENTATION from ns.zods_customer) as ii
on i.customer_code = ii.entityid
left join (select cus_code,cus_name,warehouse_id,warehouse_name from dw.dim_customer_subsidiary) as cus
on cus.cus_code = i.customer_code
where sale.customer_code='POSJP13' and sale.item_code='1240425007'