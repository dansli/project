 with item_inventory as (select 
        c.cus_contient_country as subsidiary,
        c.cus_contient_name as region,
        c.cus_name,
        dwb.zcalday,
        dwb.locationID,
        dwb.item_code,
        g.retail_price,
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
      dwb.zcalday,
      dwb.locationID,
      dwb.item_code,
      g.retail_price)


select 
  subsidiary,
  region,
  cus_name,
  zcalday,
  locationID,
  item_code,
  -- retail_price,
  -- inventory_store,
  -- inventory_on_theway,
  inventory_store*retail_price as inv_amt_store,
  inventory_on_theway*retail_price as inv_amt_on_theway
from item_inventory
where cus_name is not null
and region in ('APAC','EUR')