select 
pr.pr_code, -- PR单号
pr.creator_name, -- PR单创建人
pr_sku.quantity as pr_qty, -- PR单下单数/个
po_sku.sku_hd_code, -- 商品代码
po_sku.major_spu_code, -- 主系列编码
po_sku.spu_code, -- 系列编码
po_sku.purchase_price, -- 采购单价（含税）
po_sku.type, -- 商品类型
po_sku.quantity as po_qty, -- PO单下单数/个
sup.name as supplier_name, -- 供应商名称(找不到对应id)
po.purchaser_id, -- 采购员ID
po.po_code, -- PO单号
po.creator_name, -- PO单创建人
sl.sl_code, -- 发货指令单号（出货清单）
inv.in_code, -- 发货单号
inv.order_status, -- 发货单状态
inv.shipping_time, -- 发货时间
inv_rec.total_received_qty as receive_quantity, -- 发货单收货总数/个
inv_rec.first_receive_date as po_first_receive_date , -- PO单首次收货日期
inv_rec.first_receive_date as pr_first_receive_date, -- PR单首次收货日期
inv_rec.last_receive_date as po_last_receive_date, -- PO单最后收货日期
inv_rec.last_receive_date as pr_last_receive_date, -- PR单最后收货日期
inv_rel.outer_delivery_code, -- 收货订单号
case when inv_rel.receive_area_source = 'HD_H6' and receive_area_type='STORE' then '直配出货定单'
when inv_rel.receive_area_source = 'HD_H6' and receive_area_type='WAREHOUSE' then '自营进货定单'
end as receive_order_type, -- 收货订单单据类型
inv_rel.receive_area_code, -- 仓位/门店代码
inv_rel.receive_area_type, -- 仓位类型
inv_sku.real_delivery_quantity, -- 发货单总数/个
sku_barcode.barcode as sku_barcode, -- 商品条码/69码
sku.sku_name, -- 商品名称
sku.package_form_code, -- 包装方式
spu.spu_name, -- 系列名称
spu.product_type_code, -- 产品线编码
nvl(store.name,warehouse.name) as storewarehouse_name -- 仓位/门店名称
from purchase_requirement_info as pr -- PR单信息表
left join (select 
    pr_code,
    sku_hd_code,
    sum(quantity) as quantity
from purchase_requirement_sku_info 
group by 
pr_code,sku_hd_code) as pr_sku -- PR单商品信息表
on pr.pr_code = pr_sku.pr_code
left join purchase_requirement_related_purchase_order_info as pr_po -- PR和PO单关系信息表
on pr_po.pr_code = pr.pr_code			
left join purchase_order_info as po --PO单信息表
on po.po_code = pr_po.po_code
left join (select 
sku_hd_code, 
major_spu_code, 
spu_code, 
purchase_price, 
type, 
po_code,
sum(quantity) as quantity
from purchase_order_sku_info
group by 
sku_hd_code, 
major_spu_code, 
spu_code, 
purchase_price, 
type, 
po_code) as po_sku --PO单商品信息表
on po.po_code = po_sku.po_code
left join base_supplier_info as sup --供应商信息表
on po.supplier_id=sup.id
left join purchase_order_related_shipping_list_info as po_sl -- PO单关联出货清单信息表
on po.po_code = po_sl.po_code
left join shipping_list_info as sl -- 出货清单信息表
on sl.sl_code = po_sl.sl_code
left join invoice_info as inv -- 发货单信息表
on inv.related_code=sl.sl_code
left join (SELECT
  in_code,
  sku_hd_code,
  sum(receive_cnt) AS total_received_qty,
  min(create_time) AS first_receive_date,
  max(create_time) AS last_receive_date
FROM
  invoice_receive_detail
group by 
in_code,sku_hd_code
) as inv_rec -- 发货单收货明细表
on inv.in_code = inv_rec.in_code
left join invoice_related_receive_area_info as inv_rel -- 发货单关联收货区域信息表
on inv.in_code = inv_rel.in_code
left join (select 
    sum(real_delivery_cnt) as real_delivery_quantity,
    in_code,
    sku_hd_code
from invoice_sku_info
group by 
in_code,sku_hd_code) as inv_sku-- 发货单商品信息表
on inv.in_code = inv_sku.in_code
left join (select 
    sku_hd_code,
    barcode 
from base_sku_barcode_info 
where main_code = 1) as sku_barcode -- 商品条码信息表
on sku_barcode.sku_hd_code=inv_sku.sku_hd_code 
left join base_sku_info  as sku -- 商品信息表
on sku.sku_hd_code=inv_sku.sku_hd_code
left join base_spu_info as spu -- 系列信息表
on spu.spu_code=sku.spu_code
left join base_store_info as store -- 门店信息表
on store.code=inv_rel.receive_area_code
left join base_warehouse_info as warehouse -- 仓位信息表
on warehouse.code=inv_rel.receive_area_code


