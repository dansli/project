select 
  ord.custrecord_hp_dms_ord_track_sourceso as contract_id,
  ord.custrecord_hp_dms_ord_track_delilocation as shipping_warehouse,
  ord.custrecord_hp_dms_ord_track_hddata as HD_wholesale_order_number, -- 国内发货有值
  tr.custbody_hp_shippingmethod as shipping_method,
  ord.custrecord_hp_dms_ord_track_shipdate as ns_shipp_date,
  tr.custbody_hp_customer_saleschannel as sales_channel,
  cn.custrecord_linklocation as channel_linked_warehouse_name,
  dms.custrecord_hp_dms_2b_it_eta as ETA,
  dms.custrecord_hp_dms_2b_it_ata as ATA,
  -- as in_stock_time,
  -- trl.item as item_id,
  item.itemid as 20_code,
  item.custitem_pm_item_main_barcode as 69_code,
  trl.quantity as order_qty,
  trl.quantity as ship_qty
  -- as in_stock_qty
  from ns.customrecord_hp_dms_ord_track as ord
  left join ns.transaction as tr
  on ord.custrecord_hp_dms_ord_track_link = tr.id
  left join transactionLine as trl
  on tr.id = trl.transaction
  left join ns.transaction as tr1
  on tr1.custbody_hp_pm_createdfrom = tr.id
  left join ns.CUSTOMRECORD_HP_DMS_2B_IT as dms -- DMS 公司间在途管理记录
  on tr1.custbody_hp_inoutbound_record = dms.id
  left join ns.transaction as tr2
  on dms.custrecord_hp_dms_2b_it_estto = tr2.id
  left join ns.customer as cus
  on tr.custbody_hp_dms_ord_customer = cus.id
  left join ns.CUSTOMLIST_PM_CUSTOMER_2ND_CAT as cat2 
  on cus.custentity_pm_customer_2nd_cat = cat2.id
  left join CUSTOMRECORD_CUSTOMER_CHANNEL as cn
  on tr.custbody_hp_customer_saleschannel = cn.id
  left join ns.item
  on trl.item = item.id
  where cat2.name ='Corp'





with sales_date as (
select 
 i.zdate,
 ii.customer_code,
ii.item_code
 from ns.zcaldate as i
 left join (select distinct customer_code,item_code from ns.dws_oversea_order_v2_detail where tran_date between '${start}' and '${end}' and CUSTOMER_2ND_CAT_NAME in ('Store'))as ii
 on 1=1 
 where zdate between '${start}' and '${end}'
),
item_sales as (
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
item_code,
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
customer_code
) as i
on sale.zdate=i.tran_date and sale.customer_code=i.customer_code and sale.item_code=i.item_code
left JOIN 
(select entityid,case when entityid in ('C23563','C23651') then '越南' 
when entityid='C30749' then '印度尼西亚' else SUBSIDIARY_REGIONAL_SEGMENTATION 
end as SUBSIDIARY_REGIONAL_SEGMENTATION from ns.zods_customer) as ii
on sale.customer_code = ii.entityid
left join (select cus_code,cus_name,warehouse_id,warehouse_name from dw.dim_customer_subsidiary) as cus
on cus.cus_code = sale.customer_code),

item_inventory as (
SELECT 
  dwb.zcalday,
  dwb.item_code,
  -- cus.cus_country,
  -- cus.cus_code,
  dwb.locationID,
  nvl(sum(quantityonhand)-sum(quantitycommitted),0) as 当地库存数量,
  nvl(sum(on_theway),0) as 在途库存
FROM ns.zmm_dwb002 as dwb
left join ns.location as lc 
on lc.id=dwb.locationID
-- left join (select distinct sub_id,cus_country,warehouse_id,cus_code from dw.dim_customer_subsidiary) as cus
-- on lc.id=cus.warehouse_id
where dwb.zcalday between '${start}' and '${end}'
and dwb.locationtype = 'store'
-- and cus.cus_country is not null
GROUP BY   
  dwb.zcalday,
  dwb.item_code,
  -- cus.cus_country,
  -- cus.cus_code,
  dwb.locationID
  )


select 
sale.zdate as 日期,
sale.商品代码,
sale.国家,
nvl(sale.销量,0) as 销量,
sale.门店名称,
sale.仓库名称,
i.CUSTITEM_PM_ITEM_MAIN_BARCODE as 条形码,
i.custitem_pm_china_price as 国内零售价,
i.displayname as 中文名称,
i.custitem_pm_english_name as 英文名称,
i.custitem_pm_up_date as 上市时间,
i.custitem_pm_item_case as 盒规,
i.zbusiness1_txt as 商业一级分类, 
i.zbusiness2_txt as 商业二级分类,
i.OVERSEA_IP_NAME as 海外IP,
nvl(inv.当地库存数量,0) as 当地库存数量,
nvl(inv.在途库存,0) as 在途库存,
ip.ip_rating as 商品等级
from item_sales as sale
left join item_inventory as inv
on inv.item_code=sale.商品代码 and inv.zcalday=sale.日期 and inv.locationID = sale.仓库编码
left join ns.dim_oversea_item as i 
on sale.商品代码=i.ITEMID
left join dw.dim_manual_ip_rating_mapping as ip
on i.OVERSEA_IP_NAME=ip.ip 
and i.zbusiness2_txt=ip.zbusiness2_txt 
and ip.country=sale.国家
where i.custitem_pm_up_date between '${listing_start}' and '${listing_end}'