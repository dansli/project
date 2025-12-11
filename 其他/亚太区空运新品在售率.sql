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





with dms_detail as (
select 
  cal.zdate,
  s.首次空运ETA,
  s.首次空运ATA,
  s.首次空运入库时间,  
  s.商品代码,
  s.国家,
  s.条形码,
  s.国内零售价,
  s.中文名称,
  s.英文名称,
  s.上市时间,
  s.盒规,
  s.商业一级分类, 
  s.商业二级分类,
  s.海外IP
from (  
select 
  -- min(o.eta) as 首次空运ETA,
  -- min(o.ata) as 首次空运ATA,
  -- min(o.in_storage_time) as 首次空运入库时间,  
  min(case when o.eta between '${start}' and '${end}' then o.eta end) as 首次空运ETA,
  min(case when o.ata between '${start}' and '${end}' then o.ata end) as 首次空运ATA,
  min(case when o.in_storage_time between '${start}' and '${end}' then o.in_storage_time end) as 首次空运入库时间,
  d.hd_code as 商品代码,
  c.name as 国家,
  i.CUSTITEM_PM_ITEM_MAIN_BARCODE as 条形码,
  i.custitem_pm_china_price as 国内零售价,
  i.displayname as 中文名称,
  i.custitem_pm_english_name as 英文名称,
  i.custitem_pm_up_date as 上市时间,
  i.custitem_pm_item_case as 盒规,
  i.zbusiness1_txt as 商业一级分类, 
  i.zbusiness2_txt as 商业二级分类,
  i.OVERSEA_IP_NAME as 海外IP
from dms.delivery_order as o
left join dms.delivery_order_detail as d
on o.delivery_order_no=d.delivery_order_no
left join (
select cus.ENTITYID,cur.name,max(cus.lastmodifieddate) 
from ns.customer as cus
left join ns.CUSTOMRECORD_PM_SALES_CONTRACT as con
on cus.id = con.custrecord_pm_sc_customer
left join ns.customrecord_hc_trading_country as cur
on con.custrecord_pm_sc_salesarea = cur.custrecord_hc_tc_name_en
group by cus.ENTITYID,cur.name
) as c
on c.ENTITYID=o.customer_code 
left join ns.dim_oversea_item as i 
on d.hd_code=i.ITEMID
where o.transport_type=2 -- 限定空运
  and i.custitem_pm_up_date between '${listing_start}' and '${listing_end}'
group by 
  d.hd_code,
  c.name,
  i.CUSTITEM_PM_ITEM_MAIN_BARCODE,
  i.custitem_pm_china_price,
  i.displayname,
  i.custitem_pm_english_name,
  i.custitem_pm_up_date,
  i.custitem_pm_item_case,
  i.zbusiness1_txt, 
  i.zbusiness2_txt,
  i.OVERSEA_IP_NAME
) as s 
full join 
(
 select zdate from  ns.zcaldate
 where zdate between '${start}' and '${end}'
) as cal
on 1=1
),

item_sales as (
SELECT 
i.tran_date as 日期,
ii.SUBSIDIARY_REGIONAL_SEGMENTATION as 国家,
i.item_code as 商品代码,
sum(i.PRODUCT_COUNT) as 销量
from
(SELECT 
tran_date,
customer_code,
customer_name,
customer_country,
customer_city,
customer_2nd_cat_name,
item_code,
item_name,
PRODUCT_COUNT
from 
ns.dws_oversea_order_v2_detail
where is_target = 1 
and (customer_3nd_cat_name <> '总部跨境电商' or customer_3nd_cat_name is null)
and item_name is not null 
and tran_date between '${start}' and '${end}') as i
left JOIN 
(select entityid,case when entityid in ('C23563','C23651') then '越南' 
when entityid='C30749' then '印度尼西亚' else SUBSIDIARY_REGIONAL_SEGMENTATION 
end as SUBSIDIARY_REGIONAL_SEGMENTATION from ns.zods_customer) as ii
on i.customer_code = ii.entityid
where i.CUSTOMER_2ND_CAT_NAME in ('Store')
group by i.tran_date,
ii.SUBSIDIARY_REGIONAL_SEGMENTATION,
i.item_code
), 

item_inventory as (
SELECT 
  dwb.zcalday,
  dwb.item_code,
  cus.COUNTRY_NAME,
  nvl(sum(quantityonhand)-sum(quantitycommitted),0) as 当地库存数量,
  nvl(sum(on_theway),0) as 在途库存
FROM ns.zmm_dwb002 as dwb
left join ns.location as lc 
on lc.id=dwb.locationID
left join (select distinct SUBSIDIARY,COUNTRY_NAME from ns.zods_customer) as cus
on lc.subsidiary=cus.SUBSIDIARY
where dwb.zcalday between '${start}' and '${end}'
and dwb.locationtype = 'store'
GROUP BY   
  dwb.zcalday,
  dwb.item_code,
  cus.COUNTRY_NAME),

sales_min_date as (
SELECT 
min(i.tran_date) as 最小日期,
ii.SUBSIDIARY_REGIONAL_SEGMENTATION as 国家,
i.item_code as 商品代码
from
(SELECT 
tran_date,
customer_code,
item_code,
CUSTOMER_2ND_CAT_NAME
from 
ns.dws_oversea_order_v2_detail
where is_target = 1 
and (customer_3nd_cat_name <> '总部跨境电商' or customer_3nd_cat_name is null)
and item_name is not null) as i
left JOIN 
(select entityid,case when entityid in ('C23563','C23651') then '越南' 
when entityid='C30749' then '印度尼西亚' else SUBSIDIARY_REGIONAL_SEGMENTATION 
end as SUBSIDIARY_REGIONAL_SEGMENTATION from ns.zods_customer) as ii
on i.customer_code = ii.entityid
where i.CUSTOMER_2ND_CAT_NAME in ('Store')
group by 
ii.SUBSIDIARY_REGIONAL_SEGMENTATION,
i.item_code
)


select 
dms.zdate as 日期,
dms.商品代码,
dms.国家,
nvl(sale.销量,0) as 销量,
dms.条形码,
dms.国内零售价,
dms.中文名称,
dms.英文名称,
dms.上市时间,
dms.盒规,
dms.商业一级分类,
dms.商业二级分类,
dms.海外IP,
dms.首次空运ETA,
dms.首次空运ATA,
dms.首次空运入库时间,
dms.首次空运入库时间 + interval 7 day as 推算到店时间,
case when dms.首次空运入库时间 + interval 7 day <= dms.上市时间 
then '是 'else '否' end as 计算是否可同期上市,
case when sale_date.最小日期 <= dms.上市时间 
then dms.上市时间 else sale_date.最小日期 end as 当地首次售卖日期,
nvl(inv.当地库存数量,0) as 当地库存数量,
nvl(inv.在途库存,0) as 在途库存,
ip.ip_rating as 商品等级
from dms_detail as dms
left join item_sales as sale
on sale.国家=dms.国家 and sale.商品代码 =dms.商品代码 and sale.日期=dms.zdate
left join item_inventory as inv
on inv.item_code=dms.商品代码 and inv.zcalday=dms.zdate and inv.COUNTRY_NAME=dms.国家
left join sales_min_date as sale_date
on sale_date.国家=dms.国家 and sale_date.商品代码=dms.商品代码
left join dw.dim_manual_ip_rating_mapping as ip
on dms.海外IP=ip.ip 
and dms.商业二级分类=ip.zbusiness2_txt 
and ip.country=dms.国家