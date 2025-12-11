-- 销量
with sales as (
    select 
        s.sku_code,
        g.launch_date,
        c.cus_name,
        c.cus_contient_name as region,
        c.cus_contient_country as subsidiary,
        c.warehouse_id,
        s.sale_qty,
        s.incl_tax_rmb_amt,
        datediff(s.trans_date, g.launch_date) as diff_days
    from dw.ads_sku_overseas_sales_daily as s
    left join dw.dim_goods as g
        on s.sku_code = g.sku_code
    left join dw.dim_customer_subsidiary as c
        on s.cus_id = c.cus_id
    where g.launch_date between '${start}' and '${end}'
      and s.trans_date between g.launch_date and date_add(g.launch_date, 30)
      and ((c.sub_id = '1' AND c.cus_2nd_cat_name = 'E-com')
        OR (c.sub_id NOT IN ('28','21','15','22','24', '1','42') AND c.cus_contient_country NOT LIKE '%No performance%'))
      and c.cus_contient_name is not null
      and c.cus_2nd_cat_name = 'Store'
),
sales_summary as (
    select
        region,
        subsidiary,
        cus_name,
  		warehouse_id,
  		sku_code,
        min(launch_date) as launch_date,  -- 取新品上市时间
        sum(case when diff_days = 0 then sale_qty else 0 end) as day1_sale_qty,
        sum(case when diff_days between 0 and 6 then sale_qty else 0 end) as week1_sale_qty,
        sum(case when diff_days between 0 and 29 then sale_qty else 0 end) as month1_sale_qty
    from sales
    group by region, subsidiary, cus_name,warehouse_id,sku_code
),

-- 库存（首日、首周、首月）
item_inventory as (
    select 
        c.cus_contient_country as subsidiary,
        dwb.zcalday,
        dwb.locationID,
        dwb.item_code,
        nvl(sum(quantityonhand) - sum(quantitycommitted), 0) as inventory
    from ns.zmm_dwb002 as dwb
    left join dw.dim_customer_subsidiary as c
        on c.warehouse_id = dwb.locationID
    where dwb.locationtype = 'store'
    group by c.cus_contient_country, dwb.zcalday,dwb.locationID,dwb.item_code
)

select 
    s.region,
    s.subsidiary,
    s.cus_name,
	s.sku_code,
    -- 售罄率
    round(s.day1_sale_qty / nullif(s.day1_sale_qty + inv_day1.inventory, 0), 4) as day1_sell_through_rate,
    round(s.week1_sale_qty / nullif(s.week1_sale_qty + inv_week1.inventory, 0), 4) as week1_sell_through_rate,
    round(s.month1_sale_qty / nullif(s.month1_sale_qty + inv_month1.inventory, 0), 4) as month1_sell_through_rate
from sales_summary s
left join item_inventory inv_day1
    on s.subsidiary = inv_day1.subsidiary 
   and inv_day1.zcalday = s.launch_date
   and inv_day1.locationID = s.warehouse_id
   and inv_day1.item_code = s.sku_code
left join item_inventory inv_week1
    on s.subsidiary = inv_week1.subsidiary
   and inv_week1.zcalday = date_add(s.launch_date, 6)
   and inv_week1.locationID = s.warehouse_id
   and inv_week1.item_code = s.sku_code
left join item_inventory inv_month1
    on s.subsidiary = inv_month1.subsidiary
   and inv_month1.zcalday = date_add(s.launch_date, 29)
   and inv_month1.locationID = s.warehouse_id
   and inv_month1.item_code = s.sku_code