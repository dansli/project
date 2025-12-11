with new_item_cnt as (
    select
    count(distinct s.sku_barcode) as new_item_cnt,
    c.cus_contient_name
    from  dw.ads_sku_overseas_sales_daily as s  
    left join dw.dim_customer_subsidiary as c
    on s.cus_id = c.cus_id
    left join dw.dim_goods as g
    on s.sku_code = g.sku_code
    where s.trans_date between '${start}' and '${end}'
    and s.cus_2nd_cat_name in ('Store')
    and g.launch_date between '${start}' and '${end}'
    -- and  c.cus_contient_name ='APAC'
    group by 
    c.cus_contient_name
),
store_new_item_cnt as (
    select 
    count(distinct s.sku_barcode) as store_new_item_cnt,
    c.cus_name,
    c.cus_contient_name,
    c.cus_contient_country
    from  dw.ads_sku_overseas_sales_daily as s  
    left join dw.dim_customer_subsidiary as c
    on s.cus_id = c.cus_id
    left join dw.dim_goods as g
    on s.sku_code = g.sku_code
    where s.trans_date between '${start}' and '${end}'
    and s.cus_2nd_cat_name in ('Store')
    -- and  c.cus_contient_name ='APAC'
    and g.launch_date between '${start}' and '${end}'
    group by 
        c.cus_name,
        c.cus_contient_name,
        c.cus_contient_country
)
select 
ii.cus_name,
ii.cus_contient_country,
i.cus_contient_name,
ii.store_new_item_cnt/i.new_item_cnt as store_new_item_rate
from new_item_cnt as i
left join store_new_item_cnt as ii
on i.cus_contient_name = ii.cus_contient_name



select count(distinct sku_barcode) from dw.dim_goods where launch_date between '2025-08-01' and '2025-08-31'