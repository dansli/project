with ssr as ( -- 取线下销售 取得是海鼎日结表
  select 
    ssr.fildate as 日期,
    g.code as 商品代码,
    case 
      when s.def_qyzt_nj = '南京金鹰' then '02'
      when s.code = '0201Z136' then '0201Z136'
      else '01'
    end as 渠道代码,
    case 
      when s.def_qyzt_nj = '南京金鹰' then '经销-南京金鹰'
      when s.code = '0201Z136' then 'Molly＇s Dessert House 西单限时快闪店'
      else '线下销售'
    end as 渠道名称,
    -- if(s.def_qyzt_nj = '南京金鹰', '02', '01') as 渠道代码,
    -- if(s.def_qyzt_nj = '南京金鹰', '经销-南京金鹰', '线下销售') as 渠道名称,
    sum(ssr.saleqty) as 数量,
    sum(ssr.stdtotal) as 吊牌金额,
    sum(
      case 
        when s.def_qyzt_nj = '南京金鹰' and g.property = '自主' -- 区域状态_南京和属性
        then (ssr.saleamt + ssr.saletax) * 0.45 -- 含税销售金额*0.45
        when s.def_qyzt_nj = '南京金鹰' and g.property != '自主' -- 区域状态_南京和属性
        then (ssr.salecamt + ssr.salectax) * 1.05 -- 含税成本*1.05
        else ssr.saleamt + ssr.saletax
      end
    ) as 含税销售金额,
    sum(
      case 
        when s.def_qyzt_nj = '南京金鹰' and g.property = '自主' -- 区域状态_南京和属性
        then ssr.saleamt * 0.45 -- 不含税销售金额*0.45
        when s.def_qyzt_nj = '南京金鹰' and g.property != '自主' -- 区域状态_南京和属性
        then ssr.salecamt * 1.05 -- 不含税成本*1.05
        else ssr.saleamt
      end
    ) as 不含税销售金额,
    sum(ssr.salecamt + ssr.salectax) as 含税成本,
    sum(ssr.salecamt) as 不含税成本,
    s.code as 门店代码,
    s.name as 门店名称
  from sds.rpt_storesaldrpt as ssr -- 门店销售日报
  inner join sds.store as s 
  on ssr.orgkey = s.gid 
  inner join sds.goodsh as g 
  on ssr.pdkey = g.gid 
  where ssr.cls in ('零售', '成本调整') 
    and ssr.fildate >= '${sDate}' 
    and ssr.fildate < '${eDate}'
  group by  
    ssr.fildate,
    g.code,
    -- if(s.def_qyzt_nj = '南京金鹰', '02', '01'),
    -- if(s.def_qyzt_nj = '南京金鹰', '经销-南京金鹰', '线下销售')
    case 
      when s.def_qyzt_nj = '南京金鹰' then '02'
      when s.code = '0201Z136' then '0201Z136'
      else '01'
    end,
    case 
      when s.def_qyzt_nj = '南京金鹰' then '经销-南京金鹰'
      when s.code = '0201Z136' then 'Molly＇s Dessert House 西单限时快闪店'
      else '线下销售'
    end
), 
wod as ( -- 取渠道销售
  select 
    wod.trans_date as 日期,
    wod.sku_code as 商品代码,
    wod.client_code as 渠道代码,
    c.name as 渠道名称,
    sum(wod.sales_qty) as 数量,
    sum(wod.tag_amt) as 吊牌金额,
    sum(wod.sales_amt) as 含税销售金额,
    sum(wod.sales_amt - wod.sales_tax_amt) as 不含税销售金额,
    sum(wod.cost_amt) as 含税成本,
    sum(wod.cost_amt - wod.cost_tax_amt) as 不含税成本,
    wod.wholesale_type as 批发类型,
    wod.store_code as 门店代码,
    wod.store_name as 门店名称
  from dw.dwd_hd_wholesale_order_detail as wod 
  left join sds.client as c
  on wod.client_id = c.gid 
  where wod.trans_date >= '${sDate}' 
    and wod.trans_date < '${eDate}'
  group by 
    wod.trans_date,
    wod.sku_code,
    wod.client_code,
    c.name,
    wod.wholesale_type    
)
select  
  t.日期,
  dept.name as 商品部门,
  t.商品代码,
  g.code2 as 商品条码,
  g.name as 商品名称,
  r.rtlprc as 售价,
  t.数量,
  t.渠道代码,
  t.渠道名称,
  t.门店代码,
  t.门店名称,
  g.property as 商品属性,
  g.ip as IP,
  b.name as 副IP,
  s.code as 系列代码,
  s.name as 系列名称,
  so2.sname as 大类名称,
  so3.sname as 中类名称,
  so4.sname as 小类名称,
  s.srcblgorg as 结算主体代码,
  case s.srcblgorg 
    when 'POP MART-01' then '北京泡泡玛特文化创意有限公司'
    when 'POP MART-02' then '杭州共鸣魔法科技有限公司'
    when 'POP MART-03' then '北京泡泡玛特乐园管理有限公司'
    when 'POP MART-04' then '北京一幅商贸有限公司'
    when 'POP MART-05' then '上海零作文化创意有限公司'
    when 'POP MART-06' then '北京偲徕艺术设计有限公司'
    when 'POP MART-07' then '北京福赏福赏科技有限公司'
    when 'POP MART-08' then '北京里面空间艺术文化有限公司'
  end as 结算主体,
  g.DEF_CPX as 产品线,
  sort.sname as 商品类别,
  t.吊牌金额,
  t.含税销售金额,
  t.不含税销售金额,
  t.含税成本,
  t.不含税成本,
  g.DEF_DATASORT as 商业三级分类,
  gss.first_sale_date as 首次售卖日期,
  t.批发类型,
  gss.launch_date as 计划上市日期,
  dcm.channel_1st_name 渠道_一级,
  dcm.channel_2nd_name as 渠道_二级,
  dcm.channel_3rd_name as 渠道_三级,
  ms.name as 主系列名称
from (
  select 
    日期,
    商品代码,
    渠道代码,
    渠道名称,
    数量,
    吊牌金额,
    含税销售金额,
    不含税销售金额, 
    含税成本,
    不含税成本,
    '' as 批发类型,
    门店代码,
    门店名称
  from ssr 
  union all
  select  
    日期,
    商品代码,
    渠道代码,
    渠道名称,
    数量,
    吊牌金额,
    含税销售金额,
    不含税销售金额, 
    含税成本,
    不含税成本,
    批发类型,
    门店代码,
    门店名称
  from wod 
) as t 
inner join sds.goods as g 
on t.商品代码 = g.CODE
left join sds.sort as sort 
on g.sort = sort.scode
left join sds.dept as dept 
on g.dep = dept.code
left join sds.rpggd as r 
on g.code2 = r.inputcode
left join sds.ppmt_goods_ip as b 
on g.ip1 = b.code
left join sds.ppro_series as s 
on g.series = s.code
left join sds.sortname as so2 
on so2.acode = '0000' 
and substr(s.sort,1,2) = so2.scode
left join sds.sortname as so3 
on so3.acode = '0000' 
and substr(s.sort,1,4) = so3.scode
left join sds.sortname as so4 
on so4.acode = '0000' 
and substr(s.sort,1,6) = so4.scode
left join dw.dws_goods_sales_summary as gss 
on t.商品代码 = gss.sku_code
left join dw.dim_manual_hd_channel_mapping as dcm 
on t.渠道代码 = dcm.channel_code
left join sds.series as s1 on s1.code = g.series
left join  (	
    select mainseries, name	
    from  sds.series	
    where mainseries = code	
  )  ms -- 主系列	
  ON s1.mainseries = ms.mainseries
where 1 = 1
${if(len(channel)=0,""," and t.渠道代码 in ('"+channel+"') ")} 
${if(len(para_channel)=0,""," and t.渠道代码 in ('"+para_channel+"') ")} 