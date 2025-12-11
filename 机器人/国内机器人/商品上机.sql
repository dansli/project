select
  s.fildate,
  -- s.sku_hd_id,
  hy.region_sprvsr_name,
  hy.sprvsr_name,
  hy.splst_name,
  m.sku_rank,
  m.sku_short_name,
  -- s.robo_id,
  -- s.robo_code,
  s.robo_name,
  rb.def_machine_type,
  -- s.robo_rcode,
  -- s.city_wrh_id,
  -- s.city_wrh_code,
  -- s.city_wrh_name,
  -- s.country_wrh_code,
  -- case when s.robo_qmqty>0 then '有货未上机' else '城市仓有货未铺' end as type,
  s.robo_qmqty,
  s.city_wrh_qmqty 
from dw.dwd_stock_hd_robo as s
left join dw.dim_goods as g
on s.sku_hd_id = g.sku_hd_id
left join dw.dim_manual_robo_sku_mapping as m
on  m.sku_barcode = g.sku_barcode
left join dw.api_hby_robot_operator as hy   
on s.robo_rcode = hy.robot_code
left join sds.store as rb 
on  s.robo_rcode = rb.rcode
where (m.sku_rank <= 30 or (s.robo_qmqty > 0 and s.city_wrh_qmqty > 0))
and s.fildate between '${start}' and '${end}'
and 1=1 
${if(len(region_sprvsr_name)=0,""," and hy.region_sprvsr_name in ('"+replace(region_sprvsr_name,"\n","','")+"')")}
${if(len(sprvsr_name)=0,""," and hy.sprvsr_name in ('"+replace(sprvsr_name,"\n","','")+"')")}
${if(len(splst_name)=0,""," and hy.splst_name in ('"+replace(splst_name,"\n","','")+"')")}

-- ${if(len(robo_name)=0,""," and s.robo_name in ('"+replace(robo_name,"\n","','")+"')")}
-- ${if(len(sku_short_name)=0,""," and m.sku_short_name in ('"+replace(sku_short_name,"\n","','")+"')")}



