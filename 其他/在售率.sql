with dms_detail as (select 
min(o.eta) as 首次空运ETA,
min(o.ata) as 首次空运ATA,
min(o.consignment_time) as 首次空运入库时间,  
d.hd_code as 商品代码,
c.COUNTRY_NAME as 国家
from dms.delivery_order as o
left join dms.delivery_order_detail as d
on o.id=d.id
left join ns.zods_customer as c
on c.ENTITYID=o.customer_code
where o.transport_type=2 -- 限定空运
group by d.sku_code,c.COUNTRY_NAME),

item_sales as (
select 
  ii.TRAN_DATE as 日期,
  ii.ITEM_CODE as 商品代码,
  ii.SUBSIDIARY_COUNTRY as 国家,
  sum(ii.PRODUCT_COUNT) as 销量,
  i.CUSTITEM_PM_ITEM_MAIN_BARCODE as 条形码,
i.custitem_pm_china_price as 国内零售价,
i.displayname as 中文名称,
i.custitem_pm_english_name as 英文名称,
i.custitem_pm_up_date as 上市时间,
i.custitem_pm_item_case as 盒规,
i.zbusiness1_txt as 商业一级分类, 
i.zbusiness2_txt as 商业二级分类,
i.OVERSEA_IP_NAME as 海外IP
from ns.dws_oversea_order_v2_detail as ii
left join ns.dim_oversea_item as i 
on ii.ITEM_CODE=i.ITEMID
  where ii.TRAN_DATE between '2025-06-01' and '2025-06-30'
  and i.custitem_pm_up_date between '2025-06-01' and '2025-06-30' -- 限定6月上市新品
group by   
ii.TRAN_DATE,
ii.ITEM_CODE,
ii.SUBSIDIARY_COUNTRY,
i.CUSTITEM_PM_ITEM_MAIN_BARCODE,
i.custitem_pm_china_price,
i.displayname,
i.custitem_pm_english_name,
i.custitem_pm_up_date,
i.custitem_pm_item_case,
i.zbusiness1_txt,
i.zbusiness2_txt,
i.OVERSEA_IP_NAME
), 

item_inventory as (
SELECT 
  dwb.zcalday,
  dwb.item_code,
  cus.COUNTRY_NAME,
  nvl(sum(quantityonhand)-sum(quantitycommitted),0) as 当地库存数量,
  sum(on_theway) as 在途库存
FROM ns.zmm_dwb002 as dwb
left join ns.location as lc 
on lc.id=dwb.locationID
left join ns.zods_customer as cus 
on lc.subsidiary=cus.SUBSIDIARY
where dwb.locationtype in ('ECOM','store')
and dwb.zcalday between '2025-06-01' and '2025-06-30'
GROUP BY   
  dwb.zcalday,
  dwb.item_code,
  cus.COUNTRY_NAME)


select 
sale.*,
dms.首次空运ETA,
dms.首次空运ATA,
dms.首次空运入库时间,
inv.当地库存数量,
inv.在途库存
from item_sales as sale
left join dms_detail as dms
on sale.国家=dms.国家 and sale.商品代码 =dms.商品代码
left join item_inventory as inv
on inv.item_code=sale.商品代码 and inv.zcalday=sale.日期 and inv.COUNTRY_NAME=sale.国家