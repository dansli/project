with base as (
  select
    distinct
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    pr.pr_code,
    -- pr.po_code,
    -- pr.box_spec,
    pr.creator_name,
    pr.type_code,
    pr.type_name,
    max(pr.batch_number) as batch_number,
    max(pr.demand_time) as demand_time,
    max(pr.shipping_time) as pr_shiping_time,
    max(inv.real_delivery_date) as real_delivery_date,
    max(pr.create_time) as pr_create_time,
    max(inv.create_time) as inv_create_time
    -- sum(pr.po_shipping_cnt) as po_shipping_cnt
    -- sum(inv.receive_cnt) as receive_cnt
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
  group by
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    pr.pr_code,
    -- pr.po_code,
    -- pr.box_spec,
    pr.creator_name,
    pr.create_time,
    pr.type_code,
    pr.type_name
    -- pr.batch_number
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
    -- pr.po_code,
    -- pr.box_spec,
    pr.creator_name,
    po.purchaser_id,
    po.supplier_name,
    po.type_code,
    max(po.shipping_time) as po_shiping_time,
    max(sl_log.create_time) as po_create_time
    -- sum(po.po_shipping_cnt) as po_shipping_cnt,
    -- sum(po_spu.quantity) as po_shipping_spu_cnt
  from dw.dwd_pr_info pr
  left join dw.dwd_po_info po
   on pr.pr_code = po.pr_code
   and pr.sku_code = po.sku_code
   and pr.type_code = po.type_code
  left join po.operation_log as sl_log
  on pr.po_code = sl_log.business_code 
  and sl_log.operate_type='CONFIRM' 
  and sl_log.business_type='PURCHASE_ORDER'
  --  and pr.po_code = po.po_code
  -- left join 
  -- (select 
  -- case when type='FREE_SPARE' then 'SPARE'	when type='PAY_SPARE' then 'SPARE' else type end AS type,
  -- po_code,
  -- spu_code,
  -- major_spu_code,
  -- quantity
  -- from po.purchase_order_spu_info) as po_spu
  -- on pr.spu_code = po_spu.spu_code
  -- and pr.major_spu_code = po_spu.major_spu_code
  -- and pr.type_code = po_spu.type
  -- and pr.po_code = po_spu.po_code
  group by 
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    pr.pr_code,
    -- pr.po_code,
    -- pr.box_spec,
    pr.creator_name,
    po.purchaser_id,
    po.supplier_name,
    po.type_code
)


select 
distinct 
  concat(serial.order_category, serial.order_code) as 订单序号,
  left(goods.pro_cat_code3, 2) as 商品一级分类,
  left(goods.pro_cat_code3, 4) as 商品二级分类,
  goods.pro_cat_code3 as 商品三级分类,
  goods.pro_type as 产品线,
  goods.department_name as 产品部门,
  po.supplier_name as 供应商,
  user.name as 采购员,
  base.creator_name as 计划负责人,
  goods.ip_name as IP,
  goods.pro_cat_name3 as 系列IP分类,
  goods.launch_date as 上市日期,
  goods.series_name as 系列名称,
  base.major_spu_code as 主系列编码,
  base.spu_code as 系列编码,
  spu.retail_price as 零售价,
  goods.box_spec as 盒规,
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
  cnt.req_cnt/goods.box_spec as 数量套,
  base.channel_name as 渠道
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
--  and base.box_spec = po.box_spec
--  and base.po_code = po.po_code
left join po.order_serial_no_info as serial
  on base.pr_code = serial.order_code
  and order_category='PR'
left join dw.dim_goods goods
  on goods.main_series_code = base.major_spu_code
left join po.base_spu_info as spu
on base.spu_code = spu.spu_code
-- left join po.operation_log as sl_log
--   on base.po_code = sl_log.business_code 
--   and sl_log.operate_type='CONFIRM' 
--   and sl_log.business_type='PURCHASE_ORDER'
left join sds.r_user_wx as user -- 采购员
  on user.feishu_user_id=po.purchaser_id
where 
base.pr_code !='PR9331973608767488'
and 1=1
${if(len(pro_type)=0,""," and goods.pro_type = '"+pro_type+"'")} -- 产品线
${if(len(creator_name)=0,""," and base.creator_name = '"+creator_name+"'")} -- 计划负责人
${if(len(series_name)=0,""," and goods.series_name = '"+series_name+"'")} -- 系列名称
${if(len(major_spu_code)=0,""," and base.major_spu_code = '"+major_spu_code+"'")} -- 主系列编码
${if(len(spu_code)=0,""," and base.spu_code = '"+spu_code+"'")} -- 系列编码
${if(len(pr_code)=0,""," and base.pr_code in ('"+replace(pr_code,"\n","','")+"')")} -- PR单
${if(len(type_name)=0,""," and base.type_name = '"+type_name+"'")} -- 明细类型
