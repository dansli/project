/*
强哥之前的垃圾sql，大量抄了海鼎之前的。
但是又融入了自己的模型。
重构是早晚的事儿。目前只调整了格式，做了部分优化。

update 2024-12-25
增加渠道判断，将线下销售拆为：线下销售、经销-南京金鹰

update 2024-12-31
大幅调整格式，在保持逻辑不变的前提下，做了深度优化，重构需要花太多时间，所以没重构；
增加新指标：不含税销售金额。

update 2025-02-08
增加系列代码、系列名称。
采用新模型重构，但还是用了不少ods层的表，未来应该全部都转为模型。
里面还用到了dw.zmd_ods001，后续计划也将其干掉。

update 2025-02-10
修改不含税销售金额逻辑，和含税销售金额保持一致。

update 2025-02-20
将0201Z136从线下销售渠道中拆出，渠道名为门店名称。

update 2025-05-12
增加模板参数，para_channel，用来做渠道权限，临时方案。
*/

/* WITH HDTMP_SALDRPT0 AS (
  SELECT 
    DATE_FORMAT(R.FILDATE,'%Y') as ZCALDATE,
    G.CODE as ZGOODS,
    if(s.def_qyzt_Nj = '南京金鹰', '02', '01') as ZCLIENT,
    if(s.def_qyzt_Nj = '南京金鹰', '经销-南京金鹰', '线下销售') as ZCLIENT_TXT,
    SUM(R.SALEQTY) as 数量,
    SUM(R.STDTOTAL) as 吊牌额,
    SUM(
      CASE 
        WHEN G.PROPERTY LIKE '%自主%' AND S.def_qyzt_Nj='南京金鹰' 
        THEN (R.SALEAMT + R.SALETAX) * 0.45
        WHEN G.PROPERTY NOT LIKE '%自主%' AND S.def_qyzt_Nj='南京金鹰' 
        THEN (R.SALECAMT + R.SALECTAX) * 1.05 
        ELSE (R.SALEAMT + R.SALETAX) 
      END
    ) as 结算金额,
    SUM(R.SALEAMT) as 去税零售额,
    SUM(R.SALECAMT + R.SALECTAX) as 含税成本额,
    SUM(R.SALECAMT) as 去税成本额
  FROM SDS.RPT_STORESALDRPT as R 
  inner join SDS.STORE as S 
  on R.ORGKEY = S.GID 
  inner join SDS.GOODSH as G 
  on R.PDKEY = G.GID 
  WHERE R.CLS IN ('零售', '成本调整') 
    AND R.FILDATE >= '${sDate}' 
    AND R.FILDATE < '${eDate}'
  GROUP BY 
    DATE_FORMAT(R.FILDATE,'%Y'),
    G.CODE,
    if(s.def_qyzt_Nj = '南京金鹰', '02', '01'),
    if(s.def_qyzt_Nj = '南京金鹰', '经销-南京金鹰', '线下销售')
)
SELECT 
  a.ZCALDATE as 年度,
  dept.name as 商品部门,
  a.ZGOODS as 商品代码,
  g.code2 as 商品条码,
  g.name as 商品名称,
  r.rtlprc as 售价,
  a.数量,
  a.ZCLIENT as 渠道代码,
  a.ZCLIENT_TXT as 渠道名称,
  g.property as 商品属性,
  g.ip as IP,
  b.NAME as 副IP,
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
  吊牌额 as 吊牌金额,
  结算金额 as 含税销售金额,
  去税零售额 as 不含税销售金额,
  含税成本额 as 含税成本,
  去税成本额 as 不含税成本,
  DEF_DATASORT as 商业二级分类,
  date_format(ZFSALEDATE,'%Y/%m/%d') as 首次售卖日期,
  a.批发类型,
  ods.ZGROUNDDATE as 计划上市日期
FROM (
-- 取线下销售
  SELECT 
    ZCALDATE,
    ZGOODS,
    ZCLIENT,
    ZCLIENT_TXT,
    数量,
    吊牌额,
    结算金额,
    去税零售额, 
    含税成本额,
    去税成本额,
    '' as 批发类型
  FROM HDTMP_SALDRPT0 
  union all
-- 取渠道销售
  select 
    left(ZCALDAY,4) as ZCALDATE,
    ZGOODS,
    a.ZCLIENT,
    b.ZCLIENT_txt,
    sum(ZQTY) as 数量,
    sum(ZRTOTAL) as 售价额,
    sum(ZREALAMT) as 含税发生额,
    sum(ZNTAMT) as 去税发生额,
    sum(ZCTAMT) as 含税成本额,
    sum(ZCAMT) as 去税成本额,
    ZDEF_WHOLESALETYPE as 批发类型
  from DW.ZSD_DWB002 as a 
  left join DW.ZCLIENT as b 
  on a.zclient = b.zclient
  where ZCALDAY >= '${sDate}' 
    and ZCALDAY < '${eDate}'
  group by 
    left(ZCALDAY,4),
    ZGOODS,
    a.ZCLIENT,
    a.ZDEF_WHOLESALETYPE
-- ==== 补customer_service销售
  union all
  SELECT 
    DATE_FORMAT(SL.TIME, '%Y%') AS ZCALDATE,
    ZGD.ZGOODS AS ZGOODS,
    CL.CODE AS ZCLIENT,
    CL.NAME AS ZCLIENT_TXT,
    sum(SD.QTY*-1) AS 数量,
    sum(SD.RTOTAL*-1) AS 售价额,
    sum(SD.TOTAL*-1) AS 含税发生额,
    sum((SD.TOTAL-SD.TAX)*-1) as 去税发生额,
    sum((SD.CAMT+SD.CTAX)*-1) AS 含税成本额,
    sum(SD.CAMT*-1) AS 去税成本额,
    NULL as 批发类型
  FROM SDS.STKOUTBCKDTL as SD 
  left join SDS.STKOUTBCK as S 
  on S.NUM = SD.NUM 
  AND S.CLS = SD.CLS
  left join SDS.STKOUTBCKLOG as SL 
  on S.NUM = SL.NUM 
  AND S.CLS = SL.CLS
  left join DW.ZGOODS as ZGD 
  on SD.GDGID = ZGD.ZGID
  left join SDS.CLIENT as CL 
  on S.CLIENT = CL.GID
  WHERE S.CLS = '批发退' 
    AND SL.STAT IN (320,340,1000,1020,1040) 
    and ifnull(s.SRCCLS,0) = 'customer_service' 
    and DATE_FORMAT(SL.TIME, '%Y%m%d') >= '${sDate}'
    and DATE_FORMAT(SL.TIME, '%Y%m%d') < '${eDate}'
  group by 
    DATE_FORMAT(SL.TIME, '%Y%'),
    ZGD.ZGOODS,
    CL.CODE,
    CL.NAME
) as a 
left join sds.goods as g 
on a.ZGOODS = g.CODE
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
left join dw.zmd_ods001 as ods 
on ods.zgoods = a.zgoods; */



with ssr as ( -- 取线下销售 取得是海鼎日结表
  select 
    date_format(ssr.fildate, '%Y') as 年度,
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
    sum(ssr.salecamt) as 不含税成本
  from sds.rpt_storesaldrpt as ssr -- 门店销售日报
  inner join sds.store as s 
  on ssr.orgkey = s.gid 
  inner join sds.goodsh as g 
  on ssr.pdkey = g.gid 
  where ssr.cls in ('零售', '成本调整') 
    and ssr.fildate >= '${sDate}' 
    and ssr.fildate < '${eDate}'
  group by  
    date_format(ssr.fildate, '%Y'),
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
    date_format(wod.trans_date, '%Y') as 年度,
    wod.sku_code as 商品代码,
    wod.client_code as 渠道代码,
    c.name as 渠道名称,
    sum(wod.sales_qty) as 数量,
    sum(wod.tag_amt) as 吊牌金额,
    sum(wod.sales_amt) as 含税销售金额,
    sum(wod.sales_amt - wod.sales_tax_amt) as 不含税销售金额,
    sum(wod.cost_amt) as 含税成本,
    sum(wod.cost_amt - wod.cost_tax_amt) as 不含税成本,
    wod.wholesale_type as 批发类型
  from dw.dwd_hd_wholesale_order_detail as wod 
  left join sds.client as c
  on wod.client_id = c.gid 
  where wod.trans_date >= '${sDate}' 
    and wod.trans_date < '${eDate}'
  group by 
    date_format(wod.trans_date, '%Y'),
    wod.sku_code,
    wod.client_code,
    c.name,
    wod.wholesale_type    
)
select  
  t.年度,
  dept.name as 商品部门,
  t.商品代码,
  g.code2 as 商品条码,
  g.name as 商品名称,
  r.rtlprc as 售价,
  t.数量,
  t.渠道代码,
  t.渠道名称,
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
  g.DEF_DATASORT as 商业二级分类,
  gss.first_sale_date as 首次售卖日期,
  t.批发类型,
  gss.launch_date as 计划上市日期
from (
  select 
    年度,
    商品代码,
    渠道代码,
    渠道名称,
    数量,
    吊牌金额,
    含税销售金额,
    不含税销售金额, 
    含税成本,
    不含税成本,
    '' as 批发类型
  from ssr 
  union all
  select  
    年度,
    商品代码,
    渠道代码,
    渠道名称,
    数量,
    吊牌金额,
    含税销售金额,
    不含税销售金额, 
    含税成本,
    不含税成本,
    批发类型
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
where 1 = 1
${if(len(channel)=0,""," and t.渠道代码 in ('"+channel+"') ")} 
${if(len(para_channel)=0,""," and t.渠道代码 in ('"+para_channel+"') ")} 

