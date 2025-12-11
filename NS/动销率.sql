with sales as (
    select 
        s.sku_code,
        g.launch_date,
        c.cus_name,
        c.cus_contient_name as region,
        c.cus_contient_country as subsidiary,
        c.warehouse_id,
        c.cus_2nd_cat_name,
        sum(s.sale_qty) as sale_qty,
        sum(s.incl_tax_rmb_amt) as incl_tax_rmb_amt
        -- s.trans_date
    from dw.ads_sku_overseas_sales_daily as s
    left join dw.dim_goods as g
        on s.sku_code = g.sku_code
    left join dw.dim_customer_subsidiary as c
        on s.cus_id = c.cus_id
    where s.trans_date between '${start}' and '${end}'    
      and c.cus_contient_name is not null
      and c.cus_2nd_cat_name in ('Store','ROBOshop')
      and c.cus_contient_name in ('APAC','EUR')
    group by 
        s.sku_code,
        g.launch_date,
        c.cus_name,
        c.cus_contient_name,
        c.cus_contient_country,
        c.warehouse_id,
        c.cus_2nd_cat_name
),
item_inventory as (
    select 
        c.cus_contient_country as subsidiary,
        c.cus_contient_name as region,
        c.cus_name,
        -- dwb.zcalday,
        dwb.locationID,
        dwb.item_code,
        g.retail_price,
        c.cus_2nd_cat_name,
        nvl(sum(quantityonhand) - sum(quantitycommitted), 0) as inventory_store,
        nvl(sum(on_theway),0) as inventory_on_theway
    from ns.zmm_dwb002 as dwb
    left join dw.dim_customer_subsidiary as c
        on c.warehouse_id = dwb.locationID
    left join dw.dim_goods as g
        on dwb.item_code = g.sku_code
    where dwb.locationtype in('store','robo shop')
      and dwb.zcalday between '${start}' and '${end}'
    group by 
      c.cus_contient_country, 
      c.cus_contient_name,
      c.cus_name,
      -- dwb.zcalday,
      dwb.locationID,
      dwb.item_code,
      g.retail_price,
      c.cus_2nd_cat_name
),
-- 在店库存 SKU 数
inventory_sku as (
    select 
        region,
        subsidiary,
        cus_name,
        cus_2nd_cat_name,
        count(distinct item_code) as sku_in_inventory
    from item_inventory
    where inventory_store > 0
    group by region, subsidiary, cus_name,cus_2nd_cat_name),
-- 有动销的在店库存 SKU 数（满足：时间段内有库存 > 0，且销量合计 > 0）
active_sku as (
    select 
        inv.region,
        inv.subsidiary,
        inv.cus_name,
        inv.cus_2nd_cat_name,
        count(distinct inv.item_code) as sku_active
    from (
        -- 先筛出时间段内有库存的 SKU
        select distinct region, subsidiary, cus_name, item_code,cus_2nd_cat_name
        from item_inventory
        where inventory_store > 0
    ) inv
    join (
        -- 再筛出时间段内销量合计 > 0 的 SKU
        select sku_code, cus_name
        from sales
        group by sku_code, cus_name
        having sum(sale_qty) > 0
    ) s
      on inv.item_code = s.sku_code
     and inv.cus_name = s.cus_name
    group by inv.region, inv.subsidiary, inv.cus_name, inv.cus_2nd_cat_name
),
-- 动销率
sku_dynamic_rate as (
    select 
        i.region,
        i.subsidiary,
        i.cus_name,
        i.sku_in_inventory,
        i.cus_2nd_cat_name,
        nvl(a.sku_active,0) as sku_active,
        nvl(a.sku_active,0) * 1.0 / nullif(i.sku_in_inventory, 0) as dynamic_rate
    from inventory_sku i
    left join active_sku a
        on i.region = a.region
       and i.subsidiary = a.subsidiary
       and i.cus_name = a.cus_name
),
-- 配货丰富度
allocation_abundance as (
    select 
        i.region,
        i.subsidiary,
        i.cus_name,
        i.sku_in_inventory,
        d.store_size,
        i.cus_2nd_cat_name,
        i.sku_in_inventory * 1.0 / nullif(d.store_size, 0) as allocation_abundance
    from inventory_sku i
    left join dw.dim_customer_subsidiary d
        on i.cus_name = d.cus_name
)
-- 汇总结果
select 
    r.region,
    r.subsidiary,
    r.cus_name,
    r.cus_2nd_cat_name,
    r.sku_in_inventory,
    r.sku_active,
    r.dynamic_rate,
    ab.allocation_abundance
from sku_dynamic_rate r
left join allocation_abundance ab
    on r.region=ab.region and r.subsidiary=ab.subsidiary and r.cus_name=ab.cus_name 
where r.region in ('APAC','EUR')
and 1=1 ${if(region == '',"","and r.region in ('" + region + "')")} 
and 1=1 ${if(subsidiary == '',"","and  r.subsidiary in ('" + subsidiary + "')")} 
and 1=1 ${if(cus_name == '',"","and  r.cus_name in ('" + cus_name + "')")} 
and 1=1 ${if(cus_2nd_cat_name == '',"","and  r.cus_2nd_cat_name in ('" + cus_2nd_cat_name + "')")} 


