select
-- 单据类型,
po.sku_code as 商品代码,
sku_barcode.barcode as 商品条码,
inv.sku_name as 商品名称,
po.major_spu_code as 主系列编码,
po.spu_code as 系列编码,
spu.spu_name as 系列名称,
po.purchase_price as 采购单价（含税）,
spu.product_type_code as 产品线编码,
inv.package_form_code as 包装方式,
po.type_code as 商品类型,
inv.in_code as 发货单号,
inv.in_order_status as 发货单状态,
inv.real_delivery_quantity as 发货单总数,
inv.total_received_qty as 发货单收货总数,
inv.shipping_time as 发货时间,
sl_log.create_time as 工厂点击发货日期,
inv.outer_delivery_code as 收货订单号,
inv.receive_order_type as 收货订单单据类型,
nvl(store.name,warehouse.name) as 仓位门店名称,
inv.receive_area_code as 仓位门店代码,
inv.receive_area_type as 仓位类型,
sup.name as 供应商,
po.purchaser_id as 采购员,
inv.sl_code as 发货指令单号（出货清单）,
po.po_code as PO单号,
po.creator_name as PO单创建人,
po.purchase_cnt as PO单下单数,
po_cnt.total_received_qty as PO单收货数,
inv.po_first_receive_date as PO单首次收货日期,
inv.po_last_receive_date as PO单最后收货日期,
pr.pr_code as PR单号,
pr.creator_name as PR单创建人,
pr.req_cnt as PR单下单数,
pr_cnt.total_received_qty as PR单收货数,
inv.pr_first_receive_date as PR单首次收货日期,
inv.pr_last_receive_date as PR单最后收货日期
from 
(select 
    pr_code,
    sku_code,
    creator_name,
    sum(req_cnt) as req_cnt
from 
(select 
    distinct pr_code,
    sku_code,
    creator_name,
    req_cnt
from dw.dwd_pr_info) 
group by 
    pr_code,
    sku_code,
    creator_name)
as pr
left join po.purchase_requirement_related_purchase_order_detail as pr_po -- PR和PO单关系信息表
on pr.pr_code = pr_po.pr_code and pr.sku_code = pr_po.sku_hd_code
left join
(select 
  po_code,
  sku_code, 
  major_spu_code, 
  spu_code, 
  purchase_price, 
  type_code, 
  purchaser_id,
  creator_name,
  supplier_id,
  sum(purchase_cnt) as purchase_cnt
from (select
  distinct po_code,
  sku_code, 
  major_spu_code, 
  spu_code, 
  purchase_price, 
  type_code, 
  purchaser_id,
  creator_name,
  supplier_id,
  purchase_cnt
from dw.dwd_po_info)
group by 
po_code,
  sku_code, 
  major_spu_code, 
  spu_code, 
  purchase_price, 
  type_code, 
  purchaser_id,
  creator_name,
  supplier_id)as po
on pr_po.po_code = po.po_code	and pr_po.sku_hd_code = po.sku_code
left join po.base_supplier_info as sup -- 供应商信息表
on po.supplier_id=sup.id
left join po.purchase_order_related_shipping_list_detail	as po_sl -- PO单关联出货清单信息表
on po_sl.po_code=po.po_code
left join 
(select
sl_code, -- 发货指令单号（出货清单）
in_code, -- 发货单号
in_order_status, -- 发货单状态
shipping_time, -- 发货时间
sum(receive_cnt) AS total_received_qty, -- 发货单收货总数
min(create_time) as po_first_receive_date , -- PO单首次收货日期
min(create_time) as pr_first_receive_date, -- PR单首次收货日期
max(create_time) as po_last_receive_date, -- PO单最后收货日期
max(create_time) as pr_last_receive_date, -- PR单最后收货日期
outer_delivery_code, -- 收货订单号
receive_order_type, -- 收货订单单据类型
receive_area_code, -- 仓位/门店代码
receive_area_type, -- 仓位类型
sum(real_delivery_cnt) as real_delivery_quantity, -- 发货单总数
sku_code,
sku_name, -- 商品名称
package_form_code -- 包装方式
from (select
distinct sl_code, 
in_code, 
in_order_status, 
shipping_time, 
receive_cnt,
create_time,
outer_delivery_code, 
receive_order_type, 
receive_area_code, 
receive_area_type, 
real_delivery_cnt, 
sku_name, 
sku_code,
package_form_code 
from dw.dwd_invoice_info) 
group by 
sl_code, 
in_code, 
in_order_status, 
shipping_time, 
outer_delivery_code, 
receive_order_type, 
receive_area_code, 
receive_area_type, 
sku_code,
sku_name, 
package_form_code)as inv
on inv.sl_code=po_sl.sl_code and inv.sku_code=po_sl.sku_hd_code
left join (select create_time,business_code from po.operation_log where business_type='INVOICE' and operate_type='DELIVER') as sl_log
on sl_log.business_code=inv.in_code
left join (select 
    sku_hd_code,
    barcode 
from po.base_sku_barcode_info 
where main_code = 1) as sku_barcode -- 商品条码信息表
on sku_barcode.sku_hd_code=po.sku_code 
left join po.base_spu_info as spu -- 系列信息表
on spu.spu_code=po.spu_code
left join po.base_store_info as store -- 门店信息表
on store.code=inv.receive_area_code
left join po.base_warehouse_info as warehouse -- 仓位信息表
on warehouse.code=inv.receive_area_code
left join 
(select
po_code, -- 发货指令单号（出货清单）
sum(receive_cnt) AS total_received_qty, -- PO单收货数量合计
sku_code
from 
(select
distinct ii.po_code,
i.receive_cnt,
i.sku_code
from dw.dwd_invoice_info as i 
left join po.purchase_order_related_shipping_list_detail as ii 
on i.sl_code=ii.sl_code and i.sku_code=ii.sku_hd_code) 
group by 
po_code, 
sku_code) as po_cnt
on po_cnt.po_code=po.po_code and po_cnt.sku_code=po.sku_code
left join 
(select
pr_code, -- 发货指令单号（出货清单）
sum(receive_cnt) AS total_received_qty, -- PR单收货数量合计/个
sku_code
from 
(select
distinct iii.pr_code, 
i.receive_cnt,
i.sku_code
from dw.dwd_invoice_info as i 
left join po.purchase_order_related_shipping_list_detail as ii 
on i.sl_code=ii.sl_code and i.sku_code=ii.sku_hd_code
left join po.purchase_requirement_related_purchase_order_detail as iii
  on iii.po_code=ii.po_code and ii.sku_hd_code=iii.sku_hd_code) 
group by 
pr_code, 
sku_code) as pr_cnt
on pr_cnt.pr_code=pr.pr_code and pr_cnt.sku_code=pr.sku_code
where 1=1
${if(len(sku_code)=0,""," and po.sku_code in ('"+replace(sku_code,"\n","','")+"')")} -- 商品代码
${if(len(barcode)=0,""," and sku_barcode.barcode in ('"+replace(barcode,"\n","','")+"')")} -- 商品条码
${if(len(sku_name)=0,""," and inv.sku_name in ('"+replace(sku_name,"\n","','")+"')")} -- 商品名称
${if(len(major_spu_code)=0,""," and po.major_spu_code in ('"+replace(major_spu_code,"\n","','")+"')")} -- 主系列编码
${if(len(spu_code)=0,""," and po.spu_code in ('"+replace(spu_code,"\n","','")+"')")} -- 系列编码
${if(len(spu_name)=0,""," and spu.spu_name in ('"+replace(spu_name,"\n","','")+"')")} -- 系列名称
${if(len(product_type_code)=0,""," and spu.product_type_code in ('"+replace(product_type_code,"\n","','")+"')")} -- 产品线
${if(len(in_code)=0,""," and inv.in_code in ('"+replace(in_code,"\n","','")+"')")} -- 发货单号
${if(len(in_order_status)=0,""," and inv.in_order_status in ('"+replace(in_order_status,"\n","','")+"')")} -- 发货单状态
${if(len(name)=0,""," and sup.name in ('"+replace(name,"\n","','")+"')")} -- 供应商
${if(len(sl_code)=0,""," and inv.sl_code in ('"+replace(sl_code,"\n","','")+"')")} -- 发货指令单号（出货清单）
${if(len(po_code)=0,""," and po.po_code in ('"+replace(po_code,"\n","','")+"')")} -- PO单号
${if(len(pr_code)=0,""," and pr.pr_code in ('"+replace(pr_code,"\n","','")+"')")} -- PR单号
