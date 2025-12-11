with base as (
  select
    distinct
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    pr.pr_code,
    pr.creator_name,
    pr.type_code,
    pr.type_name,
    goods.pro_cat_name1,
    goods.pro_cat_name2,
    goods.pro_cat_name3,
    goods.pro_type,
    goods.department_name,
    goods.ip_name,
    -- goods.ip_type,
    goods.launch_date,
    goods.series_name,
    goods.box_spec,
    max(pr.batch_number) as batch_number,
    max(pr.demand_time) as demand_time,
    max(pr.shipping_time) as pr_shiping_time,
    max(inv.real_delivery_date) as real_delivery_date,
    max(pr.create_time) as pr_create_time,
    max(inv.create_time) as inv_create_time
  from dw.dwd_pr_info pr
  left join po.purchase_requirement_related_shipping_list_detail pr_sl
    on pr_sl.pr_code = pr.pr_code
   and pr_sl.sku_hd_code = pr.sku_code
   and pr_sl.type = pr.type_code
   and pr_sl.channel_code = pr.channel_code
   and pr_sl.sl_code = pr.sl_code
  left join dw.dwd_po_invoice inv
    on inv.sl_code = pr_sl.sl_code
   and inv.sku_code = pr_sl.sku_hd_code
   and inv.type_code = pr_sl.type
   and inv.channel_code = pr_sl.channel_code
left join dw.dim_goods goods
    on goods.sku_code = pr.sku_code
  group by
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    pr.pr_code,
    pr.creator_name,
    pr.create_time,
    pr.type_code,
    pr.type_name,
    goods.pro_cat_name1,
    goods.pro_cat_name2,
    goods.pro_cat_name3,
    goods.pro_type,
    goods.department_name,
    goods.ip_name,
    goods.pro_cat_name3,
    goods.launch_date,
    goods.series_name,
    goods.box_spec
),
cnt as (
  select 
    pr_code,
    spu_code,
    major_spu_code,
    channel_code,
    type as type_code,
    sum(quantity) as req_cnt
  from po.purchase_requirement_sku_info 
  group by 
    pr_code,
    spu_code,
    major_spu_code,
    channel_code,
    type
),
po as (  
  select
    distinct
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    pr.pr_code,
    pr.creator_name,
    po.purchaser_id,
    po.supplier_name,
    po.type_code,
    max(po.shipping_time) as po_shiping_time,
    max(sl_log.create_time) as po_create_time
  from dw.dwd_pr_info pr
  left join dw.dwd_po_info po
   on pr.pr_code = po.pr_code
   and pr.sku_code = po.sku_code
   and pr.type_code = po.type_code
  left join po.operation_log as sl_log
  on pr.po_code = sl_log.business_code 
  and sl_log.operate_type='CONFIRM' 
  and sl_log.business_type='PURCHASE_ORDER'
  group by 
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    pr.pr_code,
    pr.creator_name,
    po.purchaser_id,
    po.supplier_name,
    po.type_code
), req_cnt as 
(
select 
  concat(serial.order_category, serial.order_code) as 订单序号,
  base.pro_cat_name1 as 商品一级分类,
  base.pro_cat_name2 as 商品二级分类,
  base.pro_cat_name3 as 商品三级分类,
  base.pro_type as 产品线,
  base.department_name as 产品部门,
  po.supplier_name as 供应商,
  user.name as 采购员,
  base.creator_name as 计划负责人,
  base.ip_name as IP,
  base.pro_cat_name3 as 系列IP分类,
  base.launch_date as 上市日期,
  base.series_name as 系列名称,
  base.major_spu_code as 主系列编码,
  base.spu_code as 系列编码,
  spu.retail_price as 零售价,
  base.box_spec as 盒规,
  base.pr_code as PR单,
  -- base.po_code as PO单,
  '成品' as PO生产类型,
  date_format(base.pr_create_time, 'yyyy-MM-dd') as PR创建日期,
  date_format(po.po_create_time, 'yyyy-MM-dd') as PO确认时间,
  date_format(base.demand_time, 'yyyy-MM-dd') as 需求到货时间,
  date_format(po.po_shiping_time, 'yyyy-MM-dd') as 供应商承诺发货时间,
  case
      when base.real_delivery_date is not null then base.real_delivery_date -- 有实际发货时间，优先取
      else case  -- 没有实际发货时间,取 3 个计划时间的最大值
          when greatest(base.demand_time, po.po_shiping_time, base.pr_shiping_time) < current_date
               then current_date  -- 如果最大时间小于今天,自动用今天
          else greatest(base.demand_time, po.po_shiping_time, base.pr_shiping_time)
      end
  end as 最新货期,
  date_format(base.pr_shiping_time, 'yyyy-MM-dd') as 出货清单发货时间,
  date_format(base.real_delivery_date, 'yyyy-MM-dd') as 发货单实际发货时间,
  date_format(base.inv_create_time, 'yyyy-MM-dd') as 收货时间,
  base.batch_number as 批次,
  base.type_name as 明细类型,
  cnt.req_cnt as 数量个,
  cnt.req_cnt/base.box_spec as 数量套,
  base.channel_code
from base 
left join cnt
 on base.pr_code = cnt.pr_code
 and base.spu_code = cnt.spu_code
 and base.major_spu_code = cnt.major_spu_code
 and base.channel_code = cnt.channel_code
--  and base.box_spec = cnt.box_spec
and base.type_code = cnt.type_code
-- and base.batch_number = cnt.batch_number
left join po 
  on base.pr_code = po.pr_code
  and base.spu_code = po.spu_code
  and base.major_spu_code = po.major_spu_code
  and base.channel_code = po.channel_code
  and base.type_code=po.type_code
left join po.order_serial_no_info as serial
  on base.pr_code = serial.order_code
  and base.spu_code=serial.spu_code
  and order_category='PR'
left join po.base_spu_info as spu
on base.spu_code = spu.spu_code
left join sds.r_user_wx as user -- 采购员
  on user.feishu_user_id=po.purchaser_id
where 
base.pr_code !='PR9331973608767488'
)



select 
    订单序号,
    商品一级分类,
    商品二级分类,
    商品三级分类,
    产品线,
    产品部门,
    供应商,
    采购员,
    计划负责人,
    IP,
    系列IP分类,
    上市日期,
    系列名称,
    主系列编码,
    系列编码,
    零售价,
    盒规,
    PR单,
    PO生产类型,
    PR创建日期,
    PO确认时间,
    需求到货时间,
    供应商承诺发货时间,
    最新货期,
    出货清单发货时间,
    发货单实际发货时间,
    收货时间,
    批次,
    明细类型,
    数量个,
    数量套,
 -- 大中华区
  sum(case when channel_code='CH124' then coalesce(数量个,0) else 0 end) as 大中华区盲盒,
--   sum(case when base.channel_code='大中华区' and goods.box_spec>0 
--            then cast(coalesce(cnt.req_cnt,0) as double)/goods.box_spec else 0 end) as 大中华区_套,
--   -- 欧洲区
  sum(case when channel_code='CH133' then coalesce(数量个,0) else 0 end) as 欧洲区,
--   sum(case when base.channel_code='欧洲区' and goods.box_spec>0 
--            then cast(coalesce(cnt.req_cnt,0) as double)/goods.box_spec else 0 end) as 欧洲区_套,
  -- 美洲区
  sum(case when channel_code='CH125' then coalesce(数量个,0) else 0 end) as 美洲区盲盒,
  sum(case when channel_code='CH127' then coalesce(数量个,0) else 0 end) as 美洲区明盒,
--   sum(case when base.channel_code='美洲区' and goods.box_spec>0 
--            then cast(coalesce(cnt.req_cnt,0) as double)/goods.box_spec else 0 end) as 美洲区_套,
  -- 亚太区
  sum(case when channel_code='CH110' then coalesce(数量个,0) else 0 end) as 亚太区,
  sum(case when channel_code='CH122' then coalesce(数量个,0) else 0 end) as 市场宣传,
  sum(case when channel_code='CH130' then coalesce(数量个,0) else 0 end) as 抖音朗园,
  sum(case when channel_code='CH111' then coalesce(数量个,0) else 0 end) as 跨境电商盲盒,
  sum(case when channel_code='CH131' then coalesce(数量个,0) else 0 end) as 抖音懋隆,  
  sum(case when channel_code='CH121' then coalesce(数量个,0) else 0 end) as 泡泡乐园
--   sum(case when base.channel_name='亚太区' and goods.box_spec>0 
--            then cast(coalesce(cnt.req_cnt,0) as double)/goods.box_spec else 0 end) as 亚太区_套
from req_cnt
group by 
    订单序号,
    商品一级分类,
    商品二级分类,
    商品三级分类,
    产品线,
    产品部门,
    供应商,
    采购员,
    计划负责人,
    IP,
    系列IP分类,
    上市日期,
    系列名称,
    主系列编码,
    系列编码,
    零售价,
    盒规,
    PR单,
    PO生产类型,
    PR创建日期,
    PO确认时间,
    需求到货时间,
    供应商承诺发货时间,
    最新货期,
    出货清单发货时间,
    发货单实际发货时间,
    收货时间,
    批次,
    明细类型,
    数量个,
    数量套
