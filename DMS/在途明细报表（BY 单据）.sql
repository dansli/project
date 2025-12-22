select 
  t1.Location,
  t1.HDcode,
  g.sku_barcode as barcode,
  g.sku_name,
  g.sku_name_en,
  g.series_code,
  g.series_name,
  ser.ename as series_name_en,
  g.launch_date,
  g.retail_price,
  g.box_spec,
  g.case_spec,
  t1.cus_code,
  cus.cus_name as cus_name,
  cus.cus_2nd_cat_name as customer_type,
  t1.channel_id,
  channel.channel_name_cn as channel_name,
  channel.cus_country_cn as country,
  t1.currency,
  t1.order_no,
  t1.order_state,
  max(t1.order_date) as order_date,
  sum(t1.order_QTY) as order_QTY,
  sum(t1.order_value) as order_value,
  t1.invoice_no,
  sum(t1.contract_price) as contract_price,
  max(c.created_time) as contract_date,
  t1.contract_payment_remarks,
  DECODE(t1.invoice_state,'1','未付款','2','已付款','3','部分发货','4','已发货','5','已完成',t1.invoice_state)  AS	invoice_state,
  t1.external_order_no,
  sum(t1.contract_QTY) as contract_QTY,
  sum(t1.Orders_QTY_partly_shipped) - sum(t1.Shipped_QTY) as Pending_Shipment_Qty,
  t1.delivery_order_no,
  t1.partner_delivery_order_no,
  max(d.delivery_time) as shipping_time,
  DECODE(t1.transportation_method,'1','SEA','2','AIR','3','LAND','4','TRAIN','5','WEIHAI SEA','6','Express Delivery',t1.transportation_method) as transportation_method,
  max(d.etd) as ETD,
  max(d.eta) as ETA,
  max(d.atd) as ATD,
  max(d.ata) as ATA,
  max(d.in_storage_time) as delivery_time,
  max(ir.NS_Receiving_Time) as NS_Receiving_Time,
  sum(t1.del_Shipped_amount) as del_Shipped_amount,
  sum(t1.del_Shipped_QTY) as del_Shipped_QTY,
  sum(t1.Undelivered_Qty) as Undelivered_Qty,
  case when cus.cus_2nd_cat_name ='Corp' then sum(Unreceived_Qty) else 0 end as Unreceived_Qty
from (
  -- 在途订单信息
SELECT
  o.store_code as Location,
  ord_detail.hd_code as HDcode,
  o.customer_code as cus_code,
  o.channel_code as channel_id,
  o.trade_currency as currency,
  ord_detail.order_no as order_no,
  ord_detail.state as order_state,
  max(o.created_time) as order_date,
  null as invoice_no,
  null as contract_payment_remarks,
  null as invoice_state,
  null as external_order_no,
  null as delivery_order_no,
  null as partner_delivery_order_no,
  null as transportation_method,
  sum(ord_detail.total_count) as order_QTY, -- 审核中数量
  sum(ord_detail.total_price) as order_value, -- 审核中商品金额
  0 as contract_price, -- 合同金额
  0 as contract_QTY, -- 合同未付款、已付款、部分发货数量
  0 as Orders_QTY_partly_shipped,  -- 部分发货数量
  0 as del_Shipped_amount,
  0 as del_Shipped_QTY,
  0 as Shipped_QTY,
  0 as Undelivered_Qty,
  0 as Unreceived_Qty
FROM
  dms.order_detail as ord_detail
inner join dms.order as o on ord_detail.order_no = o.order_no
where ord_detail.state = 1 and o.order_state = 1 -- 订单审核中
group by 
  o.store_code,
  ord_detail.hd_code,
  o.customer_code,
  o.channel_code,
  o.trade_currency,
  ord_detail.order_no,
  ord_detail.state

union all

-- 合同信息

SELECT
  o.store_code as Location,
  ord_detail.hd_code as HDcode,
  o.customer_code as cus_code,
  o.channel_code as channel_id,
  c.trade_currency as currency,
  null as order_no,
  null as order_state,
  cast(null as timestamp) as order_date,
  c.invoice_no as invoice_no,
  c.freight_desc as contract_payment_remarks,
  c.contract_state as invoice_state,
  c.hd_order_no as external_order_no,
  d.delivery_order_no as delivery_order_no,
  d.partner_delivery_order_no as partner_delivery_order_no,
  d.transport_type as transportation_method,
  0 as order_QTY, -- 审核中数量
  0 as order_value, -- 审核中商品金额
  sum(ord_detail.total_price) as contract_price,
  sum(ord_detail.total_count) as contract_QTY,-- -- 合同未付款、已付款、部分发货数量
  sum(IF(c.contract_state = 3, ord_detail.total_count, 0)) as Orders_QTY_partly_shipped,  -- 部分发货数量
  0 as del_Shipped_amount,
  0 as del_Shipped_QTY,
  0 as Shipped_QTY,
  0 as Undelivered_Qty,
  0 as Unreceived_Qty
FROM
  dms.order_detail as ord_detail
inner join dms.`order` as o on ord_detail.order_no = o.order_no
left join dms.contract as c on c.invoice_no = o.invoice_no
left join dms.delivery_order as d on c.invoice_no = d.invoice_no
where ord_detail.state = 1 and c.contract_state in ('1','2','3','4','5')
group by 
  o.store_code,
  ord_detail.hd_code,
  o.customer_code,
  o.channel_code,
  c.trade_currency,
  c.invoice_no,
  c.freight_desc,
  c.contract_state,
  c.hd_order_no

union all

-- 发货单信息

SELECT
  s.store_code as Location,
  del_detail.hd_code as HDcode,
  d.customer_code as cus_code,
  d.channel_code as channel_id,
  c.trade_currency as currency,
  null as order_no,
  null as order_state,
  cast(null as timestamp) as order_date,
  c.invoice_no as invoice_no,
  c.freight_desc as contract_payment_remarks,
  c.contract_state as invoice_state,
  c.hd_order_no as external_order_no,
  d.delivery_order_no as delivery_order_no,
  d.partner_delivery_order_no as partner_delivery_order_no,
  d.transport_type as transportation_method,
  0 as order_QTY, -- 审核中数量
  0 as order_value, -- 审核中商品金额
  0 as contract_price,
  0 as contract_QTY,-- -- 合同未付款、已付款、部分发货数量
  0 as Orders_QTY_partly_shipped,  -- 部分发货数量
  sum(del_detail.amount) as del_Shipped_amount, -- 发货金额
  sum(del_detail.quantity) as del_Shipped_QTY, -- 发货数量
  sum(IF(c.contract_state = 3, del_detail.quantity, 0)) as Shipped_QTY, -- 部分发货数量
  sum(if (d.in_storage_time is null or d.in_storage_time > curdate(), del_detail.quantity, 0)) as Undelivered_Qty,
  0 as Unreceived_Qty
FROM 
dms.delivery_order_detail as del_detail 
left join dms.delivery_order as d on d.delivery_order_no = del_detail.delivery_order_no
left join dms.store_info as s on s.ns_store_code=d.ns_store_code
left join dms.contract as c on c.invoice_no=d.invoice_no
where del_detail.state = 1 
-- and c.contract_state!=6
and c.contract_state in ('1','2','3','4','5')
group by 
  s.store_code,
  del_detail.hd_code,
  d.customer_code,
  d.channel_code,
  c.trade_currency,
  c.invoice_no,
  c.freight_desc,
  c.contract_state,
  c.hd_order_no,
  d.delivery_order_no,
  d.partner_delivery_order_no,
  d.transport_type


union all

-- NS-ir单信息
select 
  Location,
  HDcode, 
  cus_code,
  channel_id,
  null as currency,
  null as order_no,
  null as order_state,
  cast(null as timestamp) as order_date,
  invoice_no,
  contract_payment_remarks,
  invoice_state,
  external_order_no,
  delivery_order_no,
  partner_delivery_order_no,
  transportation_method,
  0 as order_QTY, -- 审核中数量
  0 as order_value, -- 审核中商品金额
  0 as contract_price,
  0 as contract_QTY,-- -- 合同未付款、已付款、部分发货数量
  0 as Orders_QTY_partly_shipped,  -- 部分发货数量
  0 as del_Shipped_amount, -- 发货金额
  0 as del_Shipped_QTY, -- 发货数量
  0 as Shipped_QTY, -- 部分发货数量
  0 as Undelivered_Qty, 
  sum(if (NS_Receiving_Time is null or NS_Receiving_Time > curdate(), Shipped_QTY_NS, 0)) as Unreceived_Qty 
from (select
  s.store_code as Location,
  it.itemid as HDcode, 
  d.customer_code as cus_code,
  d.channel_code as channel_id,
  tr.custbody_pm_so_src_no as invoice_no,
  max(c.created_time) as contract_date,
  c.freight_desc as contract_payment_remarks,
  c.contract_state as invoice_state,
  c.hd_order_no as external_order_no,
  d.delivery_order_no as delivery_order_no,
  d.partner_delivery_order_no as partner_delivery_order_no,
  max(d.delivery_time) as shipping_time,
  d.transport_type as transportation_method,
  max(d.etd) as ETD,
  max(d.eta) as ETA,
  max(d.atd) as ATD,
  max(d.ata) as ATA,
  max(d.in_storage_time) as delivery_time,
  max(ir.NS_Receiving_Time) as NS_Receiving_Time,
  sum(trl.quantity) as Shipped_QTY_NS
from 
ns.CUSTOMRECORD_HP_DMS_2B_IT as dms -- DMS公司间在途管理记录
inner join ns.transaction as tr 
on dms.custrecord_hp_dms_2b_it_estto = tr.id 
inner join dms.delivery_order as d
on dms.custrecord_hp_dms_2b_it_shipnum = d.partner_delivery_order_no
left join ns.transactionLine as trl 
on  tr.id = trl.transaction and trl.transactionLineType='RECEIVING'
left join dms.store_info as s on s.ns_store_code=d.ns_store_code
LEFT JOIN ns.item	as it ON trl.item=it.id
left join dms.contract as c on c.invoice_no=d.invoice_no
left join 
(select 
  tr.trandate as NS_Receiving_Time,
  tr.tranid, -- NS IR单号
  trl.createdfrom -- NS TO单ID
from ns.transactionline as trl  
inner join ns.transaction as tr
on tr.id = trl.transaction 
where tr.recordtype = 'itemreceipt') as ir
on ir.createdfrom = tr.id
where c.contract_state in ('1','2','3','4','5')
group by 
  s.store_code,
  it.itemid, 
  d.customer_code,
  d.channel_code,
  tr.custbody_pm_so_src_no,
  c.freight_desc,
  c.contract_state,
  c.hd_order_no,
  d.delivery_order_no,
  d.partner_delivery_order_no,
  d.transport_type
  ) as t
) as t1
left join dw.dim_goods as g on g.sku_code = t1.HDcode
left join dw.dim_customer_subsidiary as cus on cus.cus_code = t1.cus_code
left join dw.dim_customer_channel as channel on channel.channel_id = t1.channel_id
left join sds.ppro_series as ser on ser.code = g.series_code
left join dms.contract as c on c.invoice_no=t1.invoice_no -- 取合同时间
left join dms.delivery_order as d on d.delivery_order_no = t1.delivery_order_no -- 取发货单时间
left join ns.CUSTOMRECORD_HP_DMS_2B_IT as dms  on dms.custrecord_hp_dms_2b_it_shipnum = t1.partner_delivery_order_no
inner join ns.transaction as tr  on dms.custrecord_hp_dms_2b_it_estto = tr.id 
left join 
(select 
  max(tr.trandate) as NS_Receiving_Time,
  tr.tranid, -- NS IR单号
  trl.createdfrom -- NS TO单ID
from ns.transactionline as trl  
inner join ns.transaction as tr
on tr.id = trl.transaction 
where tr.recordtype = 'itemreceipt'
group by 
  tr.tranid,
  trl.createdfrom) as ir
on ir.createdfrom = tr.id
where t1.Location !='USGC线下经销商-USWE'
and 1=1
${if(len(begin_date)=0,""," and g.launch_date >= '"+begin_date+"'")}
${if(len(end_date)=0,""," and g.launch_date <= '"+end_date+"'")}
${if(len(order_start)=0,""," and t1.order_date >= '"+order_start+"'")}
${if(len(order_end)=0,""," and t1.order_date <= '"+order_end+"'")}
${if(len(contract_start)=0,""," and c.created_time >= '"+contract_start+"'")}
${if(len(contract_end)=0,""," and c.created_time <= '"+contract_end+"'")}
${if(len(Location)=0,""," and t1.Location in ('"+replace(Location,"\n","','")+"')")} -- 仓位
${if(len(HDcode)=0,""," and t1.HDcode in ('"+replace(HDcode,"\n","','")+"')")} -- 海鼎编码
${if(len(sku_barcode)=0,""," and g.sku_barcode in ('"+replace(sku_barcode,"\n","','")+"')")} -- 商品条码
${if(len(sku_name)=0,""," and g.sku_name in ('"+replace(sku_name,"\n","','")+"')")} -- 商品中文名称
${if(len(sku_name_en)=0,""," and g.sku_name_en in ('"+replace(sku_name_en,"\n","','")+"')")} -- 商品英文名称
${if(len(series_code)=0,""," and g.series_code in ('"+replace(series_code,"\n","','")+"')")} -- 系列编码
${if(len(series_name)=0,""," and g.series_name in ('"+replace(series_name,"\n","','")+"')")} -- 系列名称
${if(len(ename)=0,""," and ser.ename in ('"+replace(ename,"\n","','")+"')")} -- 系列英文名称
${if(len(cus_code)=0,""," and t1.cus_code in ('"+replace(cus_code,"\n","','")+"')")} -- 客户编码
${if(len(cus_name)=0,""," and cus.cus_name in ('"+replace(cus_name,"\n","','")+"')")} -- 客户名称
${if(len(channel_id)=0,""," and t1.channel_id in ('"+replace(channel_id,"\n","','")+"')")} -- 渠道编码
${if(len(channel_name_cn)=0,""," and channel.channel_name_cn in ('"+replace(channel_name_cn,"\n","','")+"')")} -- 渠道名称
${if(len(cus_country_cn)=0,""," and channel.cus_country_cn in ('"+replace(cus_country_cn,"\n","','")+"')")} -- 国家名称
${if(len(cus_2nd_cat_name)=0,""," and cus.cus_2nd_cat_name in ('"+replace(cus_2nd_cat_name,"\n","','")+"')")} -- 二级分类
${if(len(order_no)=0,""," and t1.order_no in ('"+replace(order_no,"\n","','")+"')")} -- 订单号
${if(len(invoice_no)=0,""," and t1.invoice_no in ('"+replace(invoice_no,"\n","','")+"')")} -- 合同号
${if(len(invoice_state)=0,""," and DECODE(t1.invoice_state,'1','未付款','2','已付款','3','部分发货','4','已发货','5','已完成',t1.invoice_state) in ('"+replace(invoice_state,"\n","','")+"')")} -- 合同状态
${if(len(external_order_no)=0,""," and t1.external_order_no in ('"+replace(external_order_no,"\n","','")+"')")} -- 出库单号
${if(len(delivery_order_no)=0,""," and t1.delivery_order_no in ('"+replace(delivery_order_no,"\n","','")+"')")} -- 发货单号
${if(len(partner_delivery_order_no)=0,""," and t1.partner_delivery_order_no in ('"+replace(partner_delivery_order_no,"\n","','")+"')")} -- ERP发货单号
${if(len(transportation_method)=0,""," and t1.transportation_method in ('"+replace(transportation_method,"\n","','")+"')")} -- 运输方式
group by 
  t1.Location,
  t1.HDcode,
  g.sku_barcode,
  g.sku_name,
  g.sku_name_en,
  g.series_code,
  g.series_name,
  ser.ename,
  g.launch_date,
  g.retail_price,
  g.box_spec,
  g.case_spec,
  t1.cus_code,
  cus.cus_name,
  cus.cus_2nd_cat_name,
  t1.channel_id,
  channel.channel_name_cn,
  channel.cus_country_cn,
  t1.currency,
  t1.order_no,
  t1.order_state,
  t1.invoice_no,
  t1.contract_payment_remarks,
  DECODE(t1.invoice_state,'1','未付款','2','已付款','3','部分发货','4','已发货','5','已完成',t1.invoice_state),
  t1.external_order_no,
  t1.delivery_order_no,
  t1.partner_delivery_order_no,
  t1.transportation_method


------------------------------------------------------
select 
  t1.Location,
  t1.HDcode,
  g.sku_barcode as barcode,
  g.sku_name,
  g.sku_name_en,
  g.series_code,
  g.series_name,
  ser.ename as series_name_en,
  g.launch_date,
  g.retail_price,
  g.box_spec,
  g.case_spec,
  t1.cus_code,
  cus.cus_name as cus_name,
  cus.cus_2nd_cat_name as customer_type,
  t1.channel_id,
  channel.channel_name_cn as channel_name,
  channel.cus_country_cn as country,
  t1.currency,
  t1.order_no,
  t1.order_state,
  max(t1.order_date) as order_date,
  sum(t1.order_QTY) as order_QTY,
  sum(t1.order_value) as order_value,
  t1.invoice_no,
  sum(t1.contract_price) as contract_price,
--   max(c.created_time) as contract_date,
  c.created_time,
  t1.contract_payment_remarks,
  DECODE(t1.invoice_state,'1','Pending Payment','2','Paid','3','Partly Shipped','4','Shipped','5','Completed',t1.invoice_state)  AS	invoice_state,
  t1.external_order_no,
  sum(t1.contract_QTY) as contract_QTY,
  sum(t1.Orders_QTY_partly_shipped) - sum(t1.Shipped_QTY) as Pending_Shipment_Qty,
  t1.delivery_order_no,
  DECODE(d.delivery_order_state,'1','Shipped','4','Wait for sailing','5','Sailed','6','Arrived at port','7','Customs clearance','8','Delivered',d.delivery_order_state) as delivery_order_state,
  t1.partner_delivery_order_no,
  -- max(d.delivery_time) as shipping_time,
  d.delivery_time as shipping_time,
  DECODE(t1.transportation_method,'1','SEA','2','AIR','3','LAND','4','TRAIN','5','WEIHAI SEA','6','Express Delivery',t1.transportation_method) as transportation_method,
  -- max(d.etd) as ETD,
  -- max(d.eta) as ETA,
  -- max(d.atd) as ATD,
  -- max(d.ata) as ATA,
  d.etd as ETD,
  d.eta as ETA,
  d.atd as ATD,
  d.ata as ATA,
  d.in_storage_time as delivery_time,
  -- max(d.in_storage_time) as delivery_time,
  max(ir.NS_Receiving_Time) as NS_Receiving_Time,
--   ir.NS_Receiving_Time as NS_Receiving_Time,
  sum(t1.del_Shipped_amount) as del_Shipped_amount,
  sum(t1.del_Shipped_QTY) as del_Shipped_QTY,
  sum(t1.Undelivered_Qty) as Undelivered_Qty,
  SUM(CASE WHEN cus.cus_2nd_cat_name = 'Corp' THEN t1.Unreceived_Qty ELSE 0 END) AS Unreceived_Qty
from (
  -- 在途订单信息
SELECT
  o.store_code as Location,
  ord_detail.hd_code as HDcode,
  o.customer_code as cus_code,
  o.channel_code as channel_id,
  o.trade_currency as currency,
  ord_detail.order_no as order_no,
  ord_detail.state as order_state,
  max(o.created_time) as order_date,
  null as invoice_no,
  null as contract_payment_remarks,
  '' as invoice_state,
  null as external_order_no,
  null as delivery_order_no,
  null as partner_delivery_order_no,
  null as transportation_method,
  sum(ord_detail.total_count) as order_QTY, -- 审核中数量
  sum(ord_detail.total_price) as order_value, -- 审核中商品金额
  0 as contract_price, -- 合同金额
  0 as contract_QTY, -- 合同未付款、已付款、部分发货数量
  0 as Orders_QTY_partly_shipped,  -- 部分发货数量
  0 as del_Shipped_amount,
  0 as del_Shipped_QTY,
  0 as Shipped_QTY,
  0 as Undelivered_Qty,
  0 as Unreceived_Qty
FROM
  dms.order_detail as ord_detail
inner join dms.order as o on ord_detail.order_no = o.order_no
where ord_detail.state = 1 and o.order_state = 1 -- 订单审核中
group by 
  o.store_code,
  ord_detail.hd_code,
  o.customer_code,
  o.channel_code,
  o.trade_currency,
  ord_detail.order_no,
  ord_detail.state

union all

-- 合同信息



union all

-- 发货单信息

SELECT
  s.store_code as Location,
  del_detail.hd_code as HDcode,
  d.customer_code as cus_code,
  d.channel_code as channel_id,
  c.trade_currency as currency,
  null as order_no,
  null as order_state,
  cast(null as timestamp) as order_date,
  c.invoice_no as invoice_no,
  c.freight_desc as contract_payment_remarks,
  c.contract_state as invoice_state,
  c.hd_order_no as external_order_no,
  d.delivery_order_no as delivery_order_no,
  d.partner_delivery_order_no as partner_delivery_order_no,
  d.transport_type as transportation_method,
  0 as order_QTY, -- 审核中数量
  0 as order_value, -- 审核中商品金额
  0 as contract_price,
  0 as contract_QTY,-- -- 合同未付款、已付款、部分发货数量
  0 as Orders_QTY_partly_shipped,  -- 部分发货数量
  sum(del_detail.amount) as del_Shipped_amount, -- 发货金额
  sum(del_detail.quantity) as del_Shipped_QTY, -- 发货数量
  sum(IF(c.contract_state = 3, del_detail.quantity, 0)) as Shipped_QTY, -- 部分发货数量
  sum(if (d.in_storage_time is null or d.in_storage_time > curdate(), del_detail.quantity, 0)) as Undelivered_Qty,
  0 as Unreceived_Qty
FROM 
dms.delivery_order_detail as del_detail 
left join dms.delivery_order as d on d.delivery_order_no = del_detail.delivery_order_no
left join dms.store_info as s on s.ns_store_code=d.ns_store_code
left join dms.contract as c on c.invoice_no=d.invoice_no
where del_detail.state = 1 
-- and c.contract_state!=6
and c.contract_state in ('1','2','3','4','5')
group by 
  s.store_code,
  del_detail.hd_code,
  d.customer_code,
  d.channel_code,
  c.trade_currency,
  c.invoice_no,
  c.freight_desc,
  c.contract_state,
  c.hd_order_no,
  d.delivery_order_no,
  d.partner_delivery_order_no,
  d.transport_type


union all

-- NS-ir单信息
select 
  Location,
  HDcode, 
  cus_code,
  channel_id,
  currency,
  null as order_no,
  null as order_state,
  cast(null as timestamp) as order_date,
  invoice_no,
  contract_payment_remarks,
  invoice_state,
  external_order_no,
  delivery_order_no,
  partner_delivery_order_no,
  transportation_method,
  0 as order_QTY, -- 审核中数量
  0 as order_value, -- 审核中商品金额
  0 as contract_price,
  0 as contract_QTY,-- -- 合同未付款、已付款、部分发货数量
  0 as Orders_QTY_partly_shipped,  -- 部分发货数量
  0 as del_Shipped_amount, -- 发货金额
  0 as del_Shipped_QTY, -- 发货数量
  0 as Shipped_QTY, -- 部分发货数量
  0 as Undelivered_Qty, 
  sum(Shipped_QTY_NS) as Unreceived_Qty
--   sum(if (NS_Receiving_Time is null or NS_Receiving_Time > curdate(), Shipped_QTY_NS, 0)) as Unreceived_Qty
from (select
  s.store_code as Location,
  it.itemid as HDcode, 
  d.customer_code as cus_code,
  d.channel_code as channel_id,
  c.trade_currency as currency,
  tr.custbody_pm_so_src_no as invoice_no,
  max(c.created_time) as contract_date,
  c.freight_desc as contract_payment_remarks,
  c.contract_state as invoice_state,
  c.hd_order_no as external_order_no,
  d.delivery_order_no as delivery_order_no,
  d.partner_delivery_order_no as partner_delivery_order_no,
  max(d.delivery_time) as shipping_time,
  d.transport_type as transportation_method,
  max(d.etd) as ETD,
  max(d.eta) as ETA,
  max(d.atd) as ATD,
  max(d.ata) as ATA,
  max(d.in_storage_time) as delivery_time,
  sum(trl.quantity) as Shipped_QTY_NS
from 
ns.CUSTOMRECORD_HP_DMS_2B_IT as dms -- DMS公司间在途管理记录
inner join ns.transaction as tr 
on dms.custrecord_hp_dms_2b_it_estto = tr.id 
inner join dms.delivery_order as d
on dms.custrecord_hp_dms_2b_it_shipnum = d.partner_delivery_order_no
left join ns.transactionLine as trl 
on  tr.id = trl.transaction and trl.transactionLineType='RECEIVING'
left join dms.store_info as s on s.ns_store_code=d.ns_store_code
LEFT JOIN ns.item	as it ON trl.item=it.id
left join dms.contract as c on c.invoice_no=d.invoice_no
where c.contract_state in ('1','2','3','4','5')
group by 
  s.store_code,
  it.itemid, 
  d.customer_code,
  d.channel_code,
  c.trade_currency,
  tr.custbody_pm_so_src_no,
  c.freight_desc,
  c.contract_state,
  c.hd_order_no,
  d.delivery_order_no,
  d.partner_delivery_order_no,
  d.transport_type
  ) as t
group by 
  Location,
  HDcode, 
  cus_code,
  channel_id,
  currency,
  invoice_no,
  contract_payment_remarks,
  invoice_state,
  external_order_no,
  delivery_order_no,
  partner_delivery_order_no,
  transportation_method
) as t1
left join dw.dim_goods as g on g.sku_code = t1.HDcode
left join dw.dim_customer_subsidiary as cus on cus.cus_code = t1.cus_code
left join dw.dim_customer_channel as channel on channel.channel_id = t1.channel_id
left join sds.ppro_series as ser on ser.code = g.series_code
left join dms.contract as c on c.invoice_no=t1.invoice_no -- 取合同时间
left join dms.delivery_order as d on d.delivery_order_no = t1.delivery_order_no -- 取发货单时间
left join ns.CUSTOMRECORD_HP_DMS_2B_IT as dms  on dms.custrecord_hp_dms_2b_it_shipnum = t1.partner_delivery_order_no
left join ns.transaction as tr  on dms.custrecord_hp_dms_2b_it_estto = tr.id 
left join 
(select 
  max(tr.trandate) as NS_Receiving_Time,
  tr.tranid, -- NS IR单号
  trl.createdfrom -- NS TO单ID
from ns.transactionline as trl  
inner join ns.transaction as tr
on tr.id = trl.transaction 
where tr.recordtype = 'itemreceipt'
group by 
  tr.tranid,
  trl.createdfrom) as ir
on ir.createdfrom = tr.id
where t1.Location !='USGC线下经销商-USWE'
and 1=1
${if(len(begin_date)=0,""," and g.launch_date >= '"+begin_date+"'")}
${if(len(end_date)=0,""," and g.launch_date <= '"+end_date+"'")}
${if(len(order_start)=0,""," and t1.order_date >= '"+order_start+"'")}
${if(len(order_end)=0,""," and t1.order_date <= '"+order_end+"'")}
${if(len(contract_start)=0,""," and c.created_time >= '"+contract_start+"'")}
${if(len(contract_end)=0,""," and c.created_time <= '"+contract_end+"'")}
${if(len(Location)=0,""," and t1.Location in ('"+replace(Location,"\n","','")+"')")} -- 仓位
${if(len(HDcode)=0,""," and t1.HDcode in ('"+replace(HDcode,"\n","','")+"')")} -- 海鼎编码
${if(len(sku_barcode)=0,""," and g.sku_barcode in ('"+replace(sku_barcode,"\n","','")+"')")} -- 商品条码
${if(len(sku_name)=0,""," and g.sku_name in ('"+replace(sku_name,"\n","','")+"')")} -- 商品中文名称
${if(len(sku_name_en)=0,""," and g.sku_name_en in ('"+replace(sku_name_en,"\n","','")+"')")} -- 商品英文名称
${if(len(series_code)=0,""," and g.series_code in ('"+replace(series_code,"\n","','")+"')")} -- 系列编码
${if(len(series_name)=0,""," and g.series_name in ('"+replace(series_name,"\n","','")+"')")} -- 系列名称
${if(len(ename)=0,""," and ser.ename in ('"+replace(ename,"\n","','")+"')")} -- 系列英文名称
${if(len(cus_code)=0,""," and t1.cus_code in ('"+replace(cus_code,"\n","','")+"')")} -- 客户编码
${if(len(cus_name)=0,""," and cus.cus_name in ('"+replace(cus_name,"\n","','")+"')")} -- 客户名称
${if(len(channel_id)=0,""," and t1.channel_id in ('"+replace(channel_id,"\n","','")+"')")} -- 渠道编码
${if(len(channel_name_cn)=0,""," and channel.channel_name_cn in ('"+replace(channel_name_cn,"\n","','")+"')")} -- 渠道名称
${if(len(cus_country_cn)=0,""," and channel.cus_country_cn in ('"+replace(cus_country_cn,"\n","','")+"')")} -- 国家名称
${if(len(cus_2nd_cat_name)=0,""," and cus.cus_2nd_cat_name in ('"+replace(cus_2nd_cat_name,"\n","','")+"')")} -- 二级分类
${if(len(order_no)=0,""," and t1.order_no in ('"+replace(order_no,"\n","','")+"')")} -- 订单号
${if(len(invoice_no)=0,""," and t1.invoice_no in ('"+replace(invoice_no,"\n","','")+"')")} -- 合同号
${if(len(invoice_state)=0,""," and DECODE(t1.invoice_state,'1','Pending Payment','2','Paid','3','Partly Shipped','4','Shipped','5','Completed',t1.invoice_state) in ('"+replace(invoice_state,"\n","','")+"')")} -- 合同状态
${if(len(external_order_no)=0,""," and t1.external_order_no in ('"+replace(external_order_no,"\n","','")+"')")} -- 出库单号
${if(len(delivery_order_no)=0,""," and t1.delivery_order_no in ('"+replace(delivery_order_no,"\n","','")+"')")} -- 发货单号
${if(len(partner_delivery_order_no)=0,""," and t1.partner_delivery_order_no in ('"+replace(partner_delivery_order_no,"\n","','")+"')")} -- ERP发货单号
${if(len(transportation_method)=0,""," and DECODE(t1.transportation_method,'1','SEA','2','AIR','3','LAND','4','TRAIN','5','WEIHAI SEA','6','Express Delivery',t1.transportation_method) in ('"+replace(transportation_method,"\n","','")+"')")} -- 运输方式
${if(len(delivery_order_state)=0,""," and DECODE(d.delivery_order_state,'1','Shipped','4','Wait for sailing','5','Sailed','6','Arrived at destination port','7','Customs clearance','8','Delivered',d.delivery_order_state) in ('"+replace(delivery_order_state,"\n","','")+"')")} -- 发货单状态
group by 
  t1.Location,
  t1.HDcode,
  g.sku_barcode,
  g.sku_name,
  g.sku_name_en,
  g.series_code,
  g.series_name,
  ser.ename,
  g.launch_date,
  g.retail_price,
  g.box_spec,
  g.case_spec,
  t1.cus_code,
  cus.cus_name,
  cus.cus_2nd_cat_name,
  t1.channel_id,
  channel.channel_name_cn,
  channel.cus_country_cn,
  t1.currency,
  t1.order_no,
  t1.order_state,
  t1.invoice_no,
  t1.contract_payment_remarks,
  DECODE(t1.invoice_state,'1','Pending Payment','2','Paid','3','Partly Shipped','4','Shipped','5','Completed',t1.invoice_state),
  t1.external_order_no,
  t1.delivery_order_no,
  DECODE(d.delivery_order_state,'1','Shipped','4','Wait for sailing','5','Sailed','6','Arrived at port','7','Customs clearance','8','Delivered',d.delivery_order_state),
  t1.partner_delivery_order_no,
  DECODE(t1.transportation_method,'1','SEA','2','AIR','3','LAND','4','TRAIN','5','WEIHAI SEA','6','Express Delivery',t1.transportation_method)
------------------------------------------------------
-- 修改逻辑
-- 部分发货没发货部分只展示合同 10.28



select 
  Location,
  HDcode,
  barcode,
  sku_name,
  sku_name_en,
  series_code,
  series_name,
  series_name_en,
  launch_date,
  retail_price,
  box_spec,
  case_spec,
  cus_code,
  cus_name,
  customer_type,
  channel_id,
  channel_name,
  CH_Class1_code,
  CH_Class1,
  CH_Class2_code,
  CH_Class2,
  CH_Class3_code,
  CH_Class3,  
  country,
  currency,
  order_no,
  order_state,
  order_date,
  order_QTY,
  order_value,
  invoice_no,
  contract_price,
  created_time,
  contract_payment_remarks,
  invoice_state,
  external_order_no,
  contract_QTY,
  Pending_Shipment_Qty,
  delivery_order_no,
  delivery_order_state,
  partner_delivery_order_no,
  shipping_time,
  transportation_method,
  ETD,
  ETA,
  ATD,
  ATA,
  delivery_time,
  NS_Receiving_Time,
  del_Shipped_amount,
  del_Shipped_QTY,
  Undelivered_Qty,
  Unreceived_Qty,
  onway_qty,
  Transit_Status
from (select 
  t1.Location,
  t1.HDcode,
  g.sku_barcode as barcode,
  g.sku_name,
  g.sku_name_en,
  g.series_code,
  g.series_name,
  ser.ename as series_name_en,
  g.launch_date,
  g.retail_price,
  g.box_spec,
  g.case_spec,
  t1.cus_code,
  cus.cus_name as cus_name,
  cus.cus_2nd_cat_name as customer_type,
  t1.channel_id,
  channel.channel_name_cn as channel_name,
  dms_channel.ch_c1_code as CH_Class1_code,
  dms_channel.ch_c1_name as CH_Class1,
  dms_channel.ch_c2_code as CH_Class2_code,
  dms_channel.ch_c2_name as CH_Class2,
  dms_channel.ch_c3_code as CH_Class3_code,
  dms_channel.ch_c3_name as CH_Class3,  
  channel.cus_country_cn as country,
  t1.currency,
  t1.order_no,
  t1.order_state,
  max(t1.order_date) as order_date,
  sum(t1.order_QTY) as order_QTY,
  sum(t1.order_value) as order_value,
  t1.invoice_no,
  sum(t1.contract_price) as contract_price,
--   max(c.created_time) as contract_date,
  c.created_time,
  t1.contract_payment_remarks,
  DECODE(t1.invoice_state,'1','Pending Payment','2','Paid','3','Partly Shipped','4','Shipped','5','Completed',t1.invoice_state)  AS	invoice_state,
  t1.external_order_no,
  sum(t1.contract_QTY) as contract_QTY,
  sum(t1.Orders_QTY_partly_shipped) - sum(t1.Shipped_QTY) as Pending_Shipment_Qty,
  t1.delivery_order_no,
  DECODE(d.delivery_order_state,'1','Shipped','4','Wait for sailing','5','Sailed','6','Arrived at port','7','Customs clearance','8','Delivered',d.delivery_order_state) as delivery_order_state,
  t1.partner_delivery_order_no,
  -- max(d.delivery_time) as shipping_time,
  d.delivery_time as shipping_time,
  DECODE(t1.transportation_method,'1','SEA','2','AIR','3','LAND','4','TRAIN','5','WEIHAI SEA','6','Express Delivery',t1.transportation_method) as transportation_method,
  -- max(d.etd) as ETD,
  -- max(d.eta) as ETA,
  -- max(d.atd) as ATD,
  -- max(d.ata) as ATA,
  d.etd as ETD,
  d.eta as ETA,
  d.atd as ATD,
  d.ata as ATA,
  d.in_storage_time as delivery_time,
  -- max(d.in_storage_time) as delivery_time,
  max(ir.latest_to_date) as NS_Receiving_Time,
--   ir.NS_Receiving_Time as NS_Receiving_Time,
  sum(t1.del_Shipped_amount) as del_Shipped_amount,
  sum(t1.del_Shipped_QTY) as del_Shipped_QTY,
  sum(t1.Undelivered_Qty) as Undelivered_Qty,
  sum(case when cus.cus_2nd_cat_name = 'Corp' 
         then coalesce(Unreceived_Qty, 0) 
         else 0 
    end) as Unreceived_Qty,
  sum(t1.order_QTY)+ sum(t1.Orders_QTY_partly_shipped) - sum(t1.Shipped_QTY) + sum(case when cus.cus_2nd_cat_name = 'Corp' 
         then coalesce(Unreceived_Qty, 0) 
         else 0 
    end) as onway_qty,
  case when sum(t1.order_QTY)+ sum(t1.Orders_QTY_partly_shipped) - sum(t1.Shipped_QTY) + sum(case when cus.cus_2nd_cat_name = 'Corp' 
         then coalesce(Unreceived_Qty, 0) 
         else 0 
    end)>0 then 'yes' else 'no' end as Transit_Status

  -- case when cus.cus_2nd_cat_name ='Corp' then sum(Unreceived_Qty) else 0 end as Unreceived_Qty
from (
  -- 在途订单信息
SELECT
  o.store_code as Location,
  ord_detail.hd_code as HDcode,
  o.customer_code as cus_code,
  o.channel_code as channel_id,
  o.trade_currency as currency,
  ord_detail.order_no as order_no,
  ord_detail.state as order_state,
  max(o.created_time) as order_date,
  null as invoice_no,
  null as contract_payment_remarks,
  '' as invoice_state,
  null as external_order_no,
  null as delivery_order_no,
  null as partner_delivery_order_no,
  null as transportation_method,
  sum(ord_detail.total_count) as order_QTY, -- 审核中数量
  sum(ord_detail.total_price) as order_value, -- 审核中商品金额
  0 as contract_price, -- 合同金额
  0 as contract_QTY, -- 合同未付款、已付款、部分发货数量
  0 as Orders_QTY_partly_shipped,  -- 部分发货数量
  0 as del_Shipped_amount,
  0 as del_Shipped_QTY,
  0 as Shipped_QTY,
  0 as Undelivered_Qty,
  0 as Unreceived_Qty
FROM
  dms.order_detail as ord_detail
inner join dms.order as o on ord_detail.order_no = o.order_no
where ord_detail.state = 1 and o.order_state = 1 -- 订单审核中
group by 
  o.store_code,
  ord_detail.hd_code,
  o.customer_code,
  o.channel_code,
  o.trade_currency,
  ord_detail.order_no,
  ord_detail.state

union all
-- 除了已发货和已完成，其他状态的合同只展示合同信息，发货单信息不展示
SELECT
  ord_detail.store_code as Location,
  ord_detail.hd_code as HDcode,
  ord_detail.customer_code as cus_code,
  ord_detail.channel_code as channel_id,
  c.trade_currency as currency,
  null as order_no,
  null as order_state,
  cast(null as timestamp) as order_date,
  c.invoice_no as invoice_no,
  c.freight_desc as contract_payment_remarks,
  c.contract_state as invoice_state,
  c.hd_order_no as external_order_no,
  null as delivery_order_no,
  null as partner_delivery_order_no,
  null as transportation_method,
  0 as order_QTY, -- 审核中数量
  0 as order_value, -- 审核中商品金额
  sum(ord_detail.total_price) as contract_price,
  sum(ord_detail.total_count) as contract_QTY,-- -- 合同未付款、已付款、部分发货数量
  sum(IF(c.contract_state in ('1','2','3'), ord_detail.total_count, 0)) as Orders_QTY_partly_shipped,  -- 部分发货数量
  0 as del_Shipped_amount,
  0 as del_Shipped_QTY,
  COALESCE(sum(IF(c.contract_state in ('1','2','3'), del_detail.quantity, 0)), 0) AS Shipped_QTY,
  0 as Undelivered_Qty,
  0 as Unreceived_Qty
FROM
  dms.contract as c
  -- left join dms.`order` as o on c.invoice_no = o.invoice_no
  -- left join dms.order_detail as ord_detail on o.order_no = ord_detail.order_no
left join(
  select 
  o.store_code,
  ord.hd_code,
  o.customer_code,
  o.channel_code,
  o.invoice_no,
  sum(ord.total_price) as total_price,
  sum(ord.total_count) as total_count
  from dms.order as o
  inner join dms.order_detail as ord on o.order_no = ord.order_no
where ord.state =1
  group by   
  o.store_code,
  ord.hd_code,
  o.customer_code,
  o.channel_code,
  o.invoice_no
) as ord_detail
on c.invoice_no = ord_detail.invoice_no
--   dms.order_detail as ord_detail
-- inner join dms.`order` as o on ord_detail.order_no = o.order_no
-- left join dms.contract as c on c.invoice_no = o.invoice_no
-- left join dms.delivery_order as d on c.invoice_no = d.invoice_no
LEFT JOIN (
    SELECT
        d.invoice_no,
        del.hd_code,
        SUM(del.quantity) AS quantity
    FROM dms.delivery_order as d
    left join dms.delivery_order_detail as del
    on d.delivery_order_no = del.delivery_order_no
    GROUP BY d.invoice_no,del.hd_code
) AS del_detail
on c.invoice_no = del_detail.invoice_no AND ord_detail.hd_code = del_detail.hd_code
where c.contract_state in ('1','2','3')
group by 
  ord_detail.store_code,
  ord_detail.hd_code,
  ord_detail.customer_code,
  ord_detail.channel_code,
  c.trade_currency,
  c.invoice_no,
  c.freight_desc,
  c.contract_state,
  c.hd_order_no

union all

-- 发货单信息

SELECT
  s.store_code as Location,
  del_detail.hd_code as HDcode,
  d.customer_code as cus_code,
  d.channel_code as channel_id,
  c.trade_currency as currency,
  null as order_no,
  null as order_state,
  cast(null as timestamp) as order_date,
  c.invoice_no as invoice_no,
  c.freight_desc as contract_payment_remarks,
  c.contract_state as invoice_state,
  c.hd_order_no as external_order_no,
  d.delivery_order_no as delivery_order_no,
  d.partner_delivery_order_no as partner_delivery_order_no,
  d.transport_type as transportation_method,
  0 as order_QTY, -- 审核中数量
  0 as order_value, -- 审核中商品金额
  0 as contract_price,
  0 as contract_QTY,-- -- 合同未付款、已付款、部分发货数量
  0 as Orders_QTY_partly_shipped,  -- 部分发货数量
  sum(del_detail.amount) as del_Shipped_amount, -- 发货金额
  sum(del_detail.quantity) as del_Shipped_QTY, -- 发货数量
  0 as Shipped_QTY, -- 部分发货数量
  sum(if (d.in_storage_time is null or d.in_storage_time > curdate(), del_detail.quantity, 0)) as Undelivered_Qty,
  sum(case when dms.custrecord_hp_dms_2b_it_estto is null 
        then del_detail.quantity
        else 0 end) as Unreceived_Qty
-- 无TO单：Unreceived Qty=Undelivered Qty
FROM 
dms.delivery_order_detail as del_detail 
left join dms.delivery_order as d on d.delivery_order_no = del_detail.delivery_order_no
left join dms.store_info as s on s.ns_store_code=d.ns_store_code
left join dms.contract as c on c.invoice_no=d.invoice_no
left join (select distinct custrecord_hp_dms_2b_it_shipnum,custrecord_hp_dms_2b_it_estto from 
ns.CUSTOMRECORD_HP_DMS_2B_IT) as dms 
on dms.custrecord_hp_dms_2b_it_shipnum = d.partner_delivery_order_no
where del_detail.state = 1 
-- and c.contract_state!=6
and c.contract_state in ('3','4','5')
group by 
  s.store_code,
  del_detail.hd_code,
  d.customer_code,
  d.channel_code,
  c.trade_currency,
  c.invoice_no,
  c.freight_desc,
  c.contract_state,
  c.hd_order_no,
  d.delivery_order_no,
  d.partner_delivery_order_no,
  d.transport_type


union all

-- NS-ir单信息
select
  s.store_code as Location,
  ir_ord.sku_code as HDcode, 
  d.customer_code as cus_code,
  d.channel_code as channel_id,
  c.trade_currency as currency,
  null as order_no,
  null as order_state,
  cast(null as timestamp) as order_date, 
  c.invoice_no as invoice_no,
  c.freight_desc as contract_payment_remarks,
  c.contract_state as invoice_state,
  c.hd_order_no as external_order_no,
  d.delivery_order_no as delivery_order_no,
  d.partner_delivery_order_no as partner_delivery_order_no,
  d.transport_type as transportation_method,
  0 as order_QTY, -- 审核中数量
  0 as order_value, -- 审核中商品金额
  0 as contract_price,
  0 as contract_QTY,-- -- 合同未付款、已付款、部分发货数量
  0 as Orders_QTY_partly_shipped,  -- 部分发货数量
  0 as del_Shipped_amount, -- 发货金额
  0 as del_Shipped_QTY, -- 发货数量
  0 as Shipped_QTY, -- 部分发货数量
  0 as Undelivered_Qty, 
SUM(
    CASE WHEN dms.custrecord_hp_dms_2b_it_estto IS NOT NULL
         THEN ir_ord.to_quantity - ir_ord.ir_quantity
         ELSE 0
    END
) AS Unreceived_Qty

from  ns.CUSTOMRECORD_HP_DMS_2B_IT as dms 
left join dw.dwd_item_receipt_detail as ir_ord 
on ir_ord.to_id = dms.custrecord_hp_dms_2b_it_estto
inner join dms.delivery_order as d
on dms.custrecord_hp_dms_2b_it_shipnum = d.partner_delivery_order_no
left join dms.contract as c on c.invoice_no=d.invoice_no
left join dms.store_info as s on s.ns_store_code=d.ns_store_code   
-- where c.invoice_no='EUDCC312245N02CV'
where ir_ord.sku_code is not null
group by 
  s.store_code,
  ir_ord.sku_code, 
  d.customer_code,
  d.channel_code,
  c.trade_currency,
  c.invoice_no,
  c.freight_desc,
  c.contract_state,
  c.hd_order_no,
  d.delivery_order_no,
  d.partner_delivery_order_no,
  d.transport_type
) as t1
left join dw.dim_goods as g on g.sku_code = t1.HDcode
left join dw.dim_customer_subsidiary as cus on cus.cus_code = t1.cus_code
left join dw.dim_customer_channel as channel on channel.channel_id = t1.channel_id
left join sds.ppro_series as ser on ser.code = g.series_code
left join dms.contract as c on c.invoice_no=t1.invoice_no -- 取合同时间
left join dms.delivery_order as d on d.delivery_order_no = t1.delivery_order_no -- 取发货单时间
left join 
(select custrecord_hp_dms_2b_it_shipnum,max(latest_to_date) as latest_to_date
  from ns.CUSTOMRECORD_HP_DMS_2B_IT as dms 
  left join dw.dwd_item_receipt_detail as ir_ord 
  on ir_ord.to_id = dms.custrecord_hp_dms_2b_it_estto
group by custrecord_hp_dms_2b_it_shipnum) as ir
on t1.partner_delivery_order_no=ir.custrecord_hp_dms_2b_it_shipnum
left join dw.dms_customer_channel_info as dms_channel on dms_channel.channel_id = t1.channel_id
where t1.Location !='USGC线下经销商-USWE'
-- and t1.invoice_no='A39PMUKC5O15DE' and t1.HDcode='1240902005'
and 1=1
${if(len(begin_date)=0,""," and g.launch_date >= '"+begin_date+"'")}
${if(len(end_date)=0,""," and g.launch_date <= '"+end_date+"'")}
${if(len(order_start)=0,""," and t1.order_date >= '"+order_start+"'")}
${if(len(order_end)=0,""," and t1.order_date <= '"+order_end+"'")}
${if(len(contract_start)=0,""," and c.created_time >= '"+contract_start+"'")}
${if(len(contract_end)=0,""," and c.created_time <= '"+contract_end+"'")}
${if(len(Location)=0,""," and t1.Location in ('"+replace(Location,"\n","','")+"')")} -- 仓位
${if(len(HDcode)=0,""," and t1.HDcode in ('"+replace(HDcode,"\n","','")+"')")} -- 海鼎编码
${if(len(sku_barcode)=0,""," and g.sku_barcode in ('"+replace(sku_barcode,"\n","','")+"')")} -- 商品条码
${if(len(sku_name)=0,""," and g.sku_name in ('"+replace(sku_name,"\n","','")+"')")} -- 商品中文名称
${if(len(sku_name_en)=0,""," and g.sku_name_en in ('"+replace(sku_name_en,"\n","','")+"')")} -- 商品英文名称
${if(len(series_code)=0,""," and g.series_code in ('"+replace(series_code,"\n","','")+"')")} -- 系列编码
${if(len(series_name)=0,""," and g.series_name in ('"+replace(series_name,"\n","','")+"')")} -- 系列名称
${if(len(ename)=0,""," and ser.ename in ('"+replace(ename,"\n","','")+"')")} -- 系列英文名称
${if(len(cus_code)=0,""," and t1.cus_code in ('"+replace(cus_code,"\n","','")+"')")} -- 客户编码
${if(len(cus_name)=0,""," and cus.cus_name in ('"+replace(cus_name,"\n","','")+"')")} -- 客户名称
${if(len(channel_id)=0,""," and t1.channel_id in ('"+replace(channel_id,"\n","','")+"')")} -- 渠道编码
${if(len(channel_name_cn)=0,""," and channel.channel_name_cn in ('"+replace(channel_name_cn,"\n","','")+"')")} -- 渠道名称
${if(len(cus_country_cn)=0,""," and channel.cus_country_cn in ('"+replace(cus_country_cn,"\n","','")+"')")} -- 国家名称
${if(len(cus_2nd_cat_name)=0,""," and cus.cus_2nd_cat_name in ('"+replace(cus_2nd_cat_name,"\n","','")+"')")} -- 二级分类
${if(len(order_no)=0,""," and t1.order_no in ('"+replace(order_no,"\n","','")+"')")} -- 订单号
${if(len(invoice_no)=0,""," and t1.invoice_no in ('"+replace(invoice_no,"\n","','")+"')")} -- 合同号
${if(len(invoice_state)=0,""," and DECODE(t1.invoice_state,'1','Pending Payment','2','Paid','3','Partly Shipped','4','Shipped','5','Completed',t1.invoice_state) in ('"+replace(invoice_state,"\n","','")+"')")} -- 合同状态
${if(len(external_order_no)=0,""," and t1.external_order_no in ('"+replace(external_order_no,"\n","','")+"')")} -- 出库单号
${if(len(delivery_order_no)=0,""," and t1.delivery_order_no in ('"+replace(delivery_order_no,"\n","','")+"')")} -- 发货单号
${if(len(partner_delivery_order_no)=0,""," and t1.partner_delivery_order_no in ('"+replace(partner_delivery_order_no,"\n","','")+"')")} -- ERP发货单号
${if(len(transportation_method)=0,""," and DECODE(t1.transportation_method,'1','SEA','2','AIR','3','LAND','4','TRAIN','5','WEIHAI SEA','6','Express Delivery',t1.transportation_method) in ('"+replace(transportation_method,"\n","','")+"')")} -- 运输方式
${if(len(delivery_order_state)=0,""," and DECODE(d.delivery_order_state,'1','Shipped','4','Wait for sailing','5','Sailed','6','Arrived at destination port','7','Customs clearance','8','Delivered',d.delivery_order_state) in ('"+replace(delivery_order_state,"\n","','")+"')")} -- 发货单状态
${if(len(ch_c1_name)=0,""," and dms_channel.ch_c1_name in ('"+replace(ch_c1_name,"\n","','")+"')")} 
${if(len(ch_c2_name)=0,""," and dms_channel.ch_c2_name in ('"+replace(ch_c2_name,"\n","','")+"')")} 
${if(len(ch_c3_name)=0,""," and dms_channel.ch_c3_name in ('"+replace(ch_c3_name,"\n","','")+"')")} 
group by 
  t1.Location,
  t1.HDcode,
  g.sku_barcode,
  g.sku_name,
  g.sku_name_en,
  g.series_code,
  g.series_name,
  ser.ename,
  g.launch_date,
  g.retail_price,
  g.box_spec,
  g.case_spec,
  t1.cus_code,
  cus.cus_name,
  cus.cus_2nd_cat_name,
  t1.channel_id,
  channel.channel_name_cn,
  dms_channel.ch_c1_code,
  dms_channel.ch_c1_name,
  dms_channel.ch_c2_code,
  dms_channel.ch_c2_name,
  dms_channel.ch_c3_code,
  dms_channel.ch_c3_name,
  channel.cus_country_cn,
  t1.currency,
  t1.order_no,
  t1.order_state,
  t1.invoice_no,
  t1.contract_payment_remarks,
  DECODE(t1.invoice_state,'1','Pending Payment','2','Paid','3','Partly Shipped','4','Shipped','5','Completed',t1.invoice_state),
  t1.external_order_no,
  t1.delivery_order_no,
  DECODE(d.delivery_order_state,'1','Shipped','4','Wait for sailing','5','Sailed','6','Arrived at port','7','Customs clearance','8','Delivered',d.delivery_order_state),
  t1.partner_delivery_order_no,
  DECODE(t1.transportation_method,'1','SEA','2','AIR','3','LAND','4','TRAIN','5','WEIHAI SEA','6','Express Delivery',t1.transportation_method))
 WHERE 1=1
${if(len(Transit_Status)=0,""," AND Transit_Status = '"+Transit_Status+"'")}