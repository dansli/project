select
-- 单据类型,
po.sku_code as 商品代码,
goods.sku_barcode as 商品条码, 
goods.sku_name as 商品名称, 
goods.main_series_code as 主系列编码, 
goods.series_code as 系列编码, 
goods.series_name as 系列名称, 
po.purchase_price as 采购单价（含税）,
goods.pro_type as 产品线编码, 
goods.packaging_form as 包装方式,
po.type_name as 商品类型,
inv.in_code as 发货单号,
inv.in_order_status_name as 发货单状态,
inv.real_delivery_quantity as 发货单总数,
inv.total_received_qty as 发货单收货总数,
inv.shipping_date as 发货时间,
DATE_FORMAT(sl_log.create_time, '%Y-%m-%d') as 工厂点击发货日期,  
inv.outer_delivery_code as 收货订单号,
inv.receive_order_type as 收货订单单据类型,
nvl(store.name,warehouse.name) as 仓位门店名称,
inv.receive_area_code as 仓位门店代码,
inv.receive_area_type_name as 仓位类型,
sup.name as 供应商,
user.name as 采购员,
inv.sl_code as 发货指令单号（出货清单）,
po.po_code as PO单号,
po.creator_name as PO单创建人,
po.purchase_cnt as PO单下单数,
po_cnt.total_received_qty as PO单收货数,
DATE_FORMAT(inv.po_first_receive_date, '%Y-%m-%d') as PO单首次收货日期,
DATE_FORMAT(inv.po_last_receive_date, '%Y-%m-%d') as PO单最后收货日期,
pr.pr_code as PR单号,
pr.creator_name as PR单创建人,
pr.req_cnt as PR单下单数,
pr_cnt.total_received_qty as PR单收货数,
DATE_FORMAT(inv.pr_first_receive_date, '%Y-%m-%d') as PR单首次收货日期,
DATE_FORMAT(inv.pr_last_receive_date, '%Y-%m-%d') as PR单最后收货日期
from 
(select 
    pr_code,
    sku_code,
    creator_name,
    type_code, 
    type_name,
    sum(req_cnt) as req_cnt
from 
(select 
    distinct pr_code,
    sku_code,
    creator_name,
    req_cnt,
    type_code,
    type_name
from dw.dwd_pr_info) 
group by 
    pr_code,
    sku_code,
    creator_name,
    type_code,
    type_name)
as pr
-- left join po.purchase_requirement_related_purchase_order_detail as pr_po -- PR和PO单关系信息表
-- on pr.pr_code = pr_po.pr_code and pr.sku_code = pr_po.sku_hd_code
left join
(select 
  pr_code,
  po_code,
  sku_code, 
  type_name,
  type_code, 
  purchaser_id,
  creator_name,
  supplier_id,
  purchase_price,
  sum(purchase_cnt) as purchase_cnt
from (select
  distinct pr_code,
  po_code,
  sku_code, 
  type_name,
  type_code, 
  purchaser_id,
  creator_name,
  supplier_id,
  purchase_price,
  purchase_cnt
from dw.dwd_po_info)
group by 
  pr_code,
  po_code,
  sku_code, 
  type_name, 
  type_code, 
  purchaser_id,
  creator_name,
  supplier_id,
  purchase_price)as po
on pr.pr_code = po.pr_code	and pr.sku_code = po.sku_code and pr.type_code = po.type_code
left join po.base_supplier_info as sup -- 供应商信息表
on po.supplier_id=sup.id
left join 
(select 
sl_code,
sku_hd_code,
case when type='FREE_SPARE' then 'SPARE'	when type='PAY_SPARE' then 'SPARE' else type end AS type,
po_code
from po.purchase_order_related_shipping_list_detail)	as po_sl -- PO单关联出货清单信息表
on po_sl.po_code=po.po_code and po_sl.sku_hd_code=po.sku_code and po_sl.type=po.type_code -- 新增
left join 
(select
  sl_code, -- 发货指令单号（出货清单）
  t1.in_code, -- 发货单号
  in_order_status_name, -- 发货单状态
  shipping_date, -- 发货时间
  sum(receive_cnt) AS total_received_qty, -- 发货单收货总数
  min(create_time) as po_first_receive_date, -- PO单首次收货日期
  min(create_time) as pr_first_receive_date, -- PR单首次收货日期
  max(create_time) as po_last_receive_date, -- PO单最后收货日期
  max(create_time) as pr_last_receive_date, -- PR单最后收货日期
  outer_delivery_code, -- 收货订单号
  receive_order_type, -- 收货订单单据类型
  receive_area_code, -- 仓位/门店代码
  receive_area_type_name, -- 仓位类型
  sum(real_delivery_cnt) as real_delivery_quantity, -- 发货单总数
  t1.sku_code,
  t1.type_code
from
 (select distinct
        sl_code,
        in_code,
        in_order_status_name,
        shipping_date,
        create_time,
        receive_order_type,
        receive_area_code,
        receive_area_type_name,
        real_delivery_cnt,
        sku_code,
        type_code
      from
        dw.dwd_po_invoice
    ) as t1
    left join (
      select distinct
        in_code,
        sku_code,
        type_code,
        sum(receive_cnt) as receive_cnt,
        GROUP_CONCAT(DISTINCT outer_delivery_code SEPARATOR ' & ') AS outer_delivery_code
      from
        dw.dwd_po_invoice
      group by
        in_code,real_delivery_cnt,sku_code,type_code
    ) as t2 on t1.in_code = t2.in_code and t1.sku_code=t2.sku_code and t1.type_code=t2.type_code
group by
  sl_code,
  t1.in_code,
  in_order_status_name,
  shipping_date,
  outer_delivery_code,
  receive_order_type,
  receive_area_code,
  receive_area_type_name,
  t1.sku_code,
  t1.type_code)as inv
on inv.sl_code=po_sl.sl_code and inv.sku_code=po_sl.sku_hd_code and inv.type_code=po_sl.type
left join (select create_time,business_code from po.operation_log where business_type='INVOICE' and operate_type='DELIVER') as sl_log
on sl_log.business_code=inv.in_code
left join(select
  sku_code,
  sku_name,
  sku_barcode,
  series_code,
  series_name,
  main_series_code,
  pro_type,
  packaging_form
from
  dw.dim_goods) as goods -- 商品信息表
on goods.sku_code=po.sku_code
left join po.base_store_info as store -- 门店信息表
on store.code=inv.receive_area_code
left join po.base_warehouse_info as warehouse -- 仓位信息表
on warehouse.code=inv.receive_area_code
left join sds.r_user_wx as user -- 采购员
on user.feishu_user_id=po.purchaser_id
left join 
(select
po_code, -- 发货指令单号（出货清单）
sum(receive_cnt) AS total_received_qty, -- PO单收货数量合计
sku_code,
type_code
from 
(select
distinct ii.po_code,
i.receive_cnt,
i.sku_code,
i.type_code
from dw.dwd_po_invoice as i 
left join (select 
case when type='FREE_SPARE' then 'SPARE'	
when type='PAY_SPARE' then 'SPARE' 
else type end AS type,
sku_hd_code,
sl_code,
po_code
from po.purchase_order_related_shipping_list_detail) as ii 
on i.sl_code=ii.sl_code and i.sku_code=ii.sku_hd_code and ii.type=i.type_code) 
group by 
po_code, 
sku_code,
type_code) as po_cnt
on po_cnt.po_code=po.po_code and po_cnt.sku_code=po.sku_code and po_cnt.type_code=po.type_code
left join 
(select
pr_code, -- 发货指令单号（出货清单）
sum(receive_cnt) AS total_received_qty, -- PR单收货数量合计/个
sku_code,
type_code
from dw.dwd_po_invoice
group by 
pr_code, 
sku_code,
type_code) as pr_cnt
on pr_cnt.pr_code=pr.pr_code and pr_cnt.sku_code=pr.sku_code and pr_cnt.type_code=pr.type_code
where pr.req_cnt <> 0 and po.po_code is not null
and inv.shipping_date between '${begin_date}' and '${end_date}' 
and 1=1
${if(len(sku_code)=0,""," and po.sku_code in ('"+replace(sku_code,"\n","','")+"')")} -- 商品代码
${if(len(sku_barcode)=0,""," and goods.sku_barcode in ('"+replace(sku_barcode,"\n","','")+"')")} -- 商品条码
${if(len(sku_name)=0,""," and goods.sku_name in ('"+replace(sku_name,"\n","','")+"')")} -- 商品名称
${if(len(main_series_code)=0,""," and goods.main_series_code in ('"+replace(main_series_code,"\n","','")+"')")} -- 主系列编码
${if(len(series_code)=0,""," and goods.series_code in ('"+replace(series_code,"\n","','")+"')")} -- 系列编码
${if(len(series_name)=0,""," and goods.series_name in ('"+replace(series_name,"\n","','")+"')")} -- 系列名称
${if(len(pro_type)=0,""," and goods.pro_type in ('"+replace(pro_type,"\n","','")+"')")} -- 产品线
${if(len(in_code)=0,""," and inv.in_code in ('"+replace(in_code,"\n","','")+"')")} -- 发货单号
${if(len(in_order_status_name)=0,""," and inv.in_order_status_name in ('"+replace(in_order_status_name,"\n","','")+"')")} -- 发货单状态
${if(len(name)=0,""," and sup.name in ('"+replace(name,"\n","','")+"')")} -- 供应商
${if(len(sl_code)=0,""," and inv.sl_code in ('"+replace(sl_code,"\n","','")+"')")} -- 发货指令单号（出货清单）
${if(len(po_code)=0,""," and po.po_code in ('"+replace(po_code,"\n","','")+"')")} -- PO单号
${if(len(pr_code)=0,""," and pr.pr_code in ('"+replace(pr_code,"\n","','")+"')")} -- PR单号
