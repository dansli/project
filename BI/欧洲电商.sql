select 
mb.platform_order_id,
mb.shop_id,
mb.shop_code,
mb.shop_name,
mb.item_name,
mb.stock_sku,
floor(sum(mb.item_sales_count)/g.box_spec_ns) as box_qty,
mod(sum(mb.item_sales_count),g.box_spec_ns) as single_qty
from dw.dwd_itemsales_detail_mb as mb 
left join dw.dim_goods as g 
on mb.stock_sku=g.sku_code
group by 
mb.platform_order_id,
mb.shop_id,
mb.shop_code,
mb.shop_name,
mb.item_name,
mb.stock_sku