select 
    date_format(t.fildate,'%Y-%m-%d') as fildate,
    t.ctrer,
    t.sprvsr_name,
    t.splst_name,
    t.robo_name,
    t.robo_rcode,
    t.code,
    t.robo_rank,
    w.sku_max,
    w.sku_min,
    t.hd_sku_cnt,
    case 
    when t.hd_sku_cnt > w.sku_max then 'SKU过多'
    when t.hd_sku_cnt < w.sku_min then 'SKU过少'
    when t.robo_rank is null then '未知机型'
    else '正常' end as sku_width_status
from (select 
  s.fildate,
  rb.ctrer,
  hy.sprvsr_name,
  hy.splst_name,
  s.robo_name,
  s.robo_rcode,
  rb.code,
  case when rb.def_machine_type like '%新自补%' then rb.def_machine_type
  when s.robo_rcode like 'R3-%' then 'R3大机器'
  when s.robo_rcode in (select robo_rcode from dw.dim_manual_robo_list) then '少一层机器'
  else '未知' end as robo_rank,
  COUNT(DISTINCT CASE WHEN s.robo_qmqty > 0 THEN s.sku_hd_id END) AS hd_sku_cnt
from dw.dwd_stock_hd_robo as s
left join dw.dim_goods as g
on s.sku_hd_id = g.sku_hd_id
left join dw.api_hby_robot_operator as hy   
on s.robo_rcode = hy.robot_code
left join sds.store as rb 
on  s.robo_rcode = rb.rcode
where g.pro_cat_name3 != ('玻璃钢') and g.pro_cat_name3 not like ('%道具%') and g.pro_cat_name3 not like ('%陈列%') and g.pro_cat_name2 not like ('%券包%') and g.pro_cat_name3 not like ('%400%%') and g.pro_cat_name3 not like ('%徽章%')
group by
  s.fildate,
  rb.ctrer,
  hy.sprvsr_name,
  hy.splst_name,
  s.robo_name,
  s.robo_rcode,
  rb.code,
  case when rb.def_machine_type like '%新自补%' then rb.def_machine_type
  when s.robo_rcode like 'R3-%' then 'R3大机器'
  when s.robo_rcode in (select robo_rcode from dw.dim_manual_robo_list) then '少一层机器'
  else '未知' end
) as t
left join dw.dim_manual_robo_sku_width as w  
on w.robo_rank=t.robo_rank
left join (select 
  machine_id,
  notify_time,
  SUM(quantity) as quantity
from machine_slot_status_log_cn			
GROUP BY 
  machine_id,
  notify_time) as hy_stock
on hy_stock.machine_id=t.robo_rcode and date_format(t.fildate,'%Y-%m-%d') = date_format(hy_stock.notify_time,'%Y-%m-%d')
where t.fildate between '${start}' and '${end}'
and 1=1 
${if(len(ctrer)=0,""," and t.ctrer in ('"+replace(ctrer,"\n","','")+"')")}
${if(len(sprvsr_name)=0,""," and t.sprvsr_name in ('"+replace(sprvsr_name,"\n","','")+"')")}
${if(len(splst_name)=0,""," and t.splst_name in ('"+replace(splst_name,"\n","','")+"')")}
${if(len(robo_rcode)=0,""," and t.robo_rcode in ('"+replace(robo_rcode,"\n","','")+"')")}
${if(len(robo_name)=0,""," and t.robo_name in ('"+replace(robo_name,"\n","','")+"')")}
${if(len(code)=0,""," and t.code in ('"+replace(code,"\n","','")+"')")}
${if(len(robo_rank)=0,""," and t.robo_rank in ('"+replace(robo_rank,"\n","','")+"')")}
${if(len(sku_width_status)=0,""," and     case 
    when t.hd_sku_cnt > w.sku_max then 'SKU过多'
    when t.hd_sku_cnt < w.sku_min then 'SKU过少'
    when t.robo_rank is null then '未知机型'
    else '正常' end in ('"+replace(sku_width_status,"\n","','")+"')")}



select 
  machine_id,
  notify_time,
  sku,
  SUM(quantity) as quantity
from machine_slot_status_log_cn			
GROUP BY 
  machine_id,
  notify_time,
  sku
