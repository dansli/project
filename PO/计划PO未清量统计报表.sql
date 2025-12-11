with base as (
  select
    distinct
    goods.pro_type,
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    goods.series_name,
    pr.pr_code,
    pr.box_spec,
    pr.creator_name,
    max(pr.demand_time) as demand_time,
    max(pr.shipping_time) as pr_shiping_time,
    max(inv.real_delivery_date) as real_delivery_date,
    sum(inv.real_delivery_cnt) as real_delivery_cnt,
    sum(inv.receive_cnt) as receive_cnt
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
   and inv.channel_code = pr.channel_code
  left join dw.dim_goods goods
    on goods.sku_code = pr.sku_code
  where pr.type_code = 'BULK'
    and pr_sl.type = 'BULK'
  group by
    goods.pro_type,
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    goods.series_name,
    pr.pr_code,
    pr.box_spec,
    pr.creator_name
),
cnt as (
  select 
    pr_code,
    spu_code,
    major_spu_code,
    channel_code,
    box_spec,
    sum(quantity) as req_cnt
  from po.purchase_requirement_sku_info 
  where type = 'BULK'
  group by 
    pr_code,
    spu_code,
    major_spu_code,
    channel_code,
    box_spec
),
po as (  
  select
    distinct
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    pr.pr_code,
    pr.box_spec,
    pr.creator_name,
    max(po.shipping_time) as po_shiping_time
  from dw.dwd_pr_info pr
  left join dw.dwd_po_info po
    on pr.pr_code = po.pr_code
   and pr.sku_code = po.sku_code
   and pr.type_code = po.type_code
  where pr.type_code = 'BULK'
    and po.type_code = 'BULK'
  group by 
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    pr.pr_code,
    pr.box_spec,
    pr.creator_name
)

select 
  t1.pro_type as 产品线,
  t1.major_spu_code as 主系列编码,
  t1.spu_code as 系列编码,
  t1.series_name as 系列名称,
  t1.channel_code as PO渠道编码,
  t1.channel_name as PO渠道名称,
  case
      when t1.real_delivery_date is not null then t1.real_delivery_date -- 有实际发货时间，优先取
      else case  -- 没有实际发货时间,取 3 个计划时间的最大值
          when greatest(t1.demand_time, t3.po_shiping_time, t1.pr_shiping_time) < current_date
               then current_date  -- 如果最大时间小于今天,自动用今天
          else greatest(t1.demand_time, t3.po_shiping_time, t1.pr_shiping_time)
      end
  end as 最新货期,
  date_format(t1.demand_time, 'yyyy-MM-dd') as 计划需求时间,
  date_format(t3.po_shiping_time, 'yyyy-MM-dd') as 工厂填报货期计划,
  date_format(t1.pr_shiping_time, 'yyyy-MM-dd') as 出货清单出货时间,
  date_format(t1.real_delivery_date, 'yyyy-MM-dd') as 发货单实际发货时间,
  t1.pr_code as PR单,
  -- t1.real_delivery_cnt,
  -- t1.receive_cnt,
  -- t2.req_cnt,
  round(t1.real_delivery_cnt - t1.receive_cnt,0) as PO在途,
  round(t2.req_cnt - t1.receive_cnt, 0) as PO未清,
  case when t1.box_spec > 0 then round((t1.real_delivery_cnt - t1.receive_cnt) / t1.box_spec, 0) end as PO在途套数,
  case when t1.box_spec > 0 then round((t2.req_cnt - t1.receive_cnt) / t1.box_spec, 0) end as PO未清套数,
  t1.box_spec as 盒规,
  t1.creator_name as 计划负责人
from base t1
left join cnt t2
  on t1.pr_code = t2.pr_code
 and t1.spu_code = t2.spu_code
 and t1.major_spu_code = t2.major_spu_code
 and t1.channel_code = t2.channel_code
 and t1.box_spec = t2.box_spec
left join po t3
  on t1.pr_code = t3.pr_code
 and t1.spu_code = t3.spu_code
 and t1.major_spu_code = t3.major_spu_code
 and t1.channel_code = t3.channel_code
 and t1.box_spec = t3.box_spec
where 
t1.pr_code !='PR9331973608767488'
and 1=1
${if(len(major_spu_code)=0,""," and t1.major_spu_code = '"+major_spu_code+"'")} -- 主系列编码
${if(len(spu_code)=0,""," and t1.spu_code = '"+spu_code+"'")} -- 系列编码
${if(len(series_name)=0,""," and t1.series_name = '"+series_name+"'")} -- 系列名称
${if(len(pr_code)=0,""," and t1.pr_code in ('"+replace(pr_code,"\n","','")+"')")} -- PR单
${if(len(creator_name)=0,""," and t1.creator_name = '"+creator_name+"'")} -- 计划负责人