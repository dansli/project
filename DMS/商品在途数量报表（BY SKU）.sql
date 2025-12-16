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
Orders_Under_Review,
Pending_Payment,
Paid_Qty,
Pending_Shipment_Qty,
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
  sum(t1.Orders_Under_Review) as Orders_Under_Review,
  sum(t1.Pending_Payment) as Pending_Payment,
  sum(t1.Paid_Qty) as Paid_Qty,
  sum(t1.Orders_QTY_partly_shipped) - sum(t1.Shipped_QTY) as Pending_Shipment_Qty,
  sum(t1.Undelivered_Qty) as Undelivered_Qty,
  SUM(CASE WHEN cus.cus_2nd_cat_name = 'Corp' THEN t1.Unreceived_Qty ELSE 0 END) AS Unreceived_Qty,
sum(t1.Orders_Under_Review)+sum(t1.Pending_Payment)+sum(t1.Orders_QTY_partly_shipped) - sum(t1.Shipped_QTY)+sum(t1.Paid_Qty)+SUM(CASE WHEN cus.cus_2nd_cat_name = 'Corp' THEN t1.Unreceived_Qty ELSE 0 END) as onway_qty,
  case when sum(t1.Orders_Under_Review)+sum(t1.Pending_Payment)+sum(t1.Orders_QTY_partly_shipped) - sum(t1.Shipped_QTY)+sum(t1.Paid_Qty)+SUM(CASE WHEN cus.cus_2nd_cat_name = 'Corp' THEN t1.Unreceived_Qty ELSE 0 END) > 0 then 'yes' else 'no' end as Transit_Status -- case when cus.cus_2nd_cat_name ='Corp' then sum(t1.Orders_QTY) - sum(t1.Shipped_QTY_NS) else 0 end as Unreceived_Qty
from (
SELECT
  o.store_code as Location,
  ord_detail.hd_code as HDcode,
  o.customer_code as cus_code,
  o.channel_code as channel_id,
  sum(if(o.order_state = 1, ord_detail.total_count, 0)) as Orders_Under_Review,
  sum(if(c.contract_state = 1, ord_detail.total_count, 0)) as Pending_Payment,
  sum(if(c.contract_state = 2, ord_detail.total_count, 0)) as Paid_Qty, 
  sum(IF(o.invoice_no IS NOT NULL, ord_detail.total_count, 0)) as Orders_QTY,
  sum(IF(c.contract_state = 3, ord_detail.total_count, 0)) as Orders_QTY_partly_shipped,  
  0 as Shipped_QTY,
  0 as Undelivered_Qty,
  0 as Unreceived_Qty
FROM
  dms.order_detail as ord_detail
inner join dms.order as o on ord_detail.order_no = o.order_no
left join dms.contract as c on c.invoice_no = o.invoice_no
where ord_detail.state = 1 
group by 
  o.store_code,
  ord_detail.hd_code,
  o.customer_code,
  o.channel_code
union all

SELECT
  s.store_code as Location,
  del_detail.hd_code as HDcode,
  d.customer_code as cus_code,
  d.channel_code as channel_id,
  0 as Orders_Under_Review,
  0 as Pending_Payment,
  0 as Paid_Qty,
  0 as Orders_QTY,
  0 as Orders_QTY_partly_shipped,
  sum(IF(c.contract_state = 3, del_detail.quantity, 0)) as Shipped_QTY,
  sum(if (d.in_storage_time is null or d.in_storage_time > curdate(), del_detail.quantity, 0)) as Undelivered_Qty,
  sum(
    case 
        when dms.custrecord_hp_dms_2b_it_estto is null 
        then del_detail.quantity
        else 0
    end
) as Unreceived_Qty -- 无TO单：Unreceived Qty=Undelivered Qty Shipped_QTY_NS
FROM 
dms.delivery_order_detail as del_detail 
left join dms.delivery_order as d on d.delivery_order_no = del_detail.delivery_order_no
left join dms.store_info as s on s.ns_store_code=d.ns_store_code
left join dms.contract as c on c.invoice_no=d.invoice_no
left join (select distinct custrecord_hp_dms_2b_it_shipnum,custrecord_hp_dms_2b_it_estto from 
ns.CUSTOMRECORD_HP_DMS_2B_IT) as dms 
on dms.custrecord_hp_dms_2b_it_shipnum = d.partner_delivery_order_no
where del_detail.state = 1 and c.contract_state!=6
group by 
  s.store_code,
  del_detail.hd_code,
  d.customer_code,
  d.channel_code
  
union all


select
  s.store_code as Location,
  ir_ord.sku_code as HDcode, 
  d.customer_code as cus_code,
  d.channel_code as channel_id,
  0 as Orders_Under_Review,
  0 as Pending_Payment,
  0 as Paid_Qty,
  0 as Orders_QTY,
  0 as Orders_QTY_partly_shipped,
  0 as Shipped_QTY,
  0 as Undelivered_Qty,
SUM(
    CASE WHEN dms.custrecord_hp_dms_2b_it_estto IS NOT NULL
         THEN COALESCE(ir_ord.to_quantity,0) - COALESCE(ir_ord.ir_quantity,0)
         ELSE 0
    END
) AS Unreceived_Qty

from  ns.CUSTOMRECORD_HP_DMS_2B_IT as dms 
left join dw.dwd_item_receipt_detail as ir_ord 
on ir_ord.to_id = dms.custrecord_hp_dms_2b_it_estto
inner join dms.delivery_order as d
on dms.custrecord_hp_dms_2b_it_shipnum = d.partner_delivery_order_no
-- left join dms.contract as c on c.invoice_no=d.invoice_no
left join dms.store_info as s on s.ns_store_code=d.ns_store_code   
-- where c.invoice_no='EUDCC312245N02CV'
group by 
  s.store_code,
  ir_ord.sku_code, 
  d.customer_code,
  d.channel_code
) as t1
left join dw.dim_goods as g on g.sku_code = t1.HDcode
left join dw.dim_customer_subsidiary as cus on cus.cus_code = t1.cus_code
left join dw.dim_customer_channel as channel on channel.channel_id = t1.channel_id
left join sds.ppro_series as ser on ser.code = g.series_code
left join dw.dms_customer_channel_info as dms_channel on dms_channel.channel_id = t1.channel_id
where t1.Location !='USGC线下经销商-USWE'
and 1=1
${if(len(begin_date)=0,""," and g.launch_date >= '"+begin_date+"'")}
${if(len(end_date)=0,""," and g.launch_date <= '"+end_date+"'")}
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
  channel.cus_country_cn)
  WHERE 1=1
${if(len(Transit_Status)=0,""," AND Transit_Status = '"+Transit_Status+"'")}