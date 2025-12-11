/*
用来替换强哥的原模型：ZGOODS，其中有些字段可能有用但是这次没有加进来：
  GD.CPXZ, -- 产品性质
  GD.CPZ, -- 产品组
  GD.CPZDM, -- 产品组代码
  GD.VDRGDCODE, -- 供应商自编码
  VD.CODE AS ZVENDOR, -- 供应商代码
  VD.NAME AS ZVENDOR_TXT, -- 供应商名称
  BD.CODE AS ZBRAND, -- 品牌代码
  BD.NAME AS ZBRAND_TXT, -- 品牌名称
  GD.VDRGID, -- 供应商ID

该模型数据目前都来源于海鼎，但是在海外有一些自采商品或者物料，海鼎里是没有的，不过依然是希望把这个模型建设成完整模型。
待以后需要海外这部分商品信息的时候，再行合并数据。

海鼎里有三张商品表，ppro_goods、goods、goodsh。
其中ppro_goods数据最全，但是有很多过程数据，比如没有审核的数据，所以没有取它。
而goods和goodsh字段一样，数据略有不同，
goodsh比goods多几百条数据，但是肉眼看没有用，都是脏数据，
海鼎报表基本都用的是goodsh，但是goodsh有一个大问题，就是code不唯一，有脏数据。懒得清洗了，直接用goods。

后续整改的点：
1. 最终要废掉强哥的ZGOODS。

update 2024-12-26
将series的表的内联改为左联，否则会有少量商品没有系列信息，有code但是在系列表里没有。
涉及不少是通过系列表出来的数据，后续如果需要再想办法。

*/

CREATE TABLE IF NOT EXISTS dw.dim_goods_info (
  sku_id int COMMENT '商品id',
  sku_code varchar(32) COMMENT '商品编码',
  sku_name varchar(80) COMMENT '商品名称',
  sku_barcode varchar(32) COMMENT '商品条码',
  sku_display_name varchar(120) COMMENT '商品显示名称',
  series_code varchar(20) COMMENT '系列编码',
  series_name varchar(255) COMMENT '系列名称',
  series_display_name varchar(280) COMMENT '系列显示名称',
  main_series_code varchar(20) COMMENT '主系列编码',
  main_series_name varchar(255) COMMENT '主系列名称',
  product_category_code1 varchar(20) COMMENT '产品大类编码',
  product_category_name1 varchar(255) COMMENT '产品大类名称',
  product_category_display_name1 varchar(280) COMMENT '产品大类显示名称',
  product_category_code2 varchar(20) COMMENT '产品中类编码',
  product_category_name2 varchar(255) COMMENT '产品中类名称',
  product_category_display_name2 varchar(280) COMMENT '产品中类显示名称',
  product_category_code3 varchar(20) COMMENT '产品小类编码',
  product_category_name3 varchar(255) COMMENT '产品小类名称',
  product_category_display_name3 varchar(280) COMMENT '产品小类显示名称',
  business_category_code1 varchar(20) COMMENT '商业一级编码',
  business_category_name1 varchar(255) COMMENT '商业一级名称',
  business_category_display_name1 varchar(280) COMMENT '商业一级显示名称',
  business_category_code2 varchar(20) COMMENT '商业二级编码',
  business_category_name2 varchar(255) COMMENT '商业二级名称',
  business_category_display_name2 varchar(280) COMMENT '商业二级显示名称',
  business_category_code3 varchar(20) COMMENT '商业三级编码',
  business_category_name3 varchar(255) COMMENT '商业三级名称',
  business_category_display_name3 varchar(280) COMMENT '商业三级显示名称',
  ip_code varchar(20) COMMENT 'IP编码',
  ip_name varchar(50) COMMENT 'IP名称',
  ip_display_name varchar(80) COMMENT 'IP显示名称',
  department_name varchar(60) COMMENT '部门名称',
  series_theme_code varchar(100) COMMENT '系列主题编码',
  series_theme_name varchar(1024) COMMENT '系列主题名称',
  series_theme_display_name varchar(1150) COMMENT '系列主题显示名称',
  collaboration_ip_code varchar(20) COMMENT '联名IP编码',
  collaboration_ip_name varchar(50) COMMENT '联名IP名称',
  collaboration_ip_display_name varchar(80) COMMENT '联名IP显示名称',
  launch_date date COMMENT '上市日期',
  retail_price decimal(24,4) COMMENT '零售价',
  product_type varchar(1024) COMMENT '产品线(产品类型)',
  play_mode varchar(1024) COMMENT '玩法',
  product_property varchar(1024) COMMENT '商品属性',
  packaging_form varchar(30) COMMENT '包装形式',
  style varchar(32) COMMENT '款式',
  box_spec varchar(20) COMMENT '商品盒规',
  case_spec varchar(20) COMMENT '商品箱规',
  created_time datetime COMMENT '创建时间',
  last_modified_time datetime COMMENT '最后修改时间',
  is_shopping_bag tinyint COMMENT '是否为购物袋',
  PRIMARY KEY (sku_code)
) COMMENT='商品主数据';


truncate table dw.dim_goods_info;
insert into dw.dim_goods_info 
select 
  g.gid as sku_id, -- 商品id
  g.code as sku_code, -- 商品编码
  g.name as sku_name, -- 商品名称
  g.code2 as sku_barcode, -- 商品条码
  concat('[',g.code,']',g.name) as sku_display_name, -- 商品显示名称
  g.series as series_code, -- 系列编码
  s.name as series_name, -- 系列名称
  concat('[',g.series,']',s.name) as series_display_name, -- 系列显示名称
  s.mainseries as main_series_code, -- 主系列编码
  ms.name as main_series_name, -- 主系列名称
  sop1.scode as product_category_code1, -- 产品大类编码
  sop1.sname as product_category_name1, -- 产品大类名称
  concat('[',sop1.scode,']',sop1.sname) as product_category_display_name1, -- 产品大类显示名称
  sop2.scode as product_category_code2, -- 产品中类编码
  sop2.sname as product_category_name2, -- 产品中类名称
  concat('[',sop2.scode,']',sop2.sname) as product_category_display_name2, -- 产品中类显示名称
  sop3.scode as product_category_code3, -- 产品小类编码
  sop3.sname as product_category_name3, -- 产品小类名称
  concat('[',sop3.scode,']',sop3.sname) as product_category_display_name3, -- 产品小类显示名称
  sob1.scode as business_category_code1, -- 商业一级编码
  sob1.sname as business_category_name1, -- 商业一级名称
  concat('[',sob1.scode,']',sob1.sname) as business_category_display_name1, -- 商业一级显示名称
  sob2.scode as business_category_code2, -- 商业二级编码
  sob2.sname as business_category_name2, -- 商业二级名称
  concat('[',sob2.scode,']',sob2.sname) as business_category_display_name2, -- 商业二级显示名称
  sob3.scode as business_category_code3, -- 商业三级编码
  sob3.sname as business_category_name3, -- 商业三级名称
  concat('[',sob3.scode,']',sob3.sname) as business_category_display_name3, -- 商业三级显示名称
  s.ip as ip_code, -- IP编码
  ip.name as ip_name, -- IP名称
  concat('[',s.ip,']',ip.name) as ip_display_name, -- IP显示名称
  g.def_dept as department_name, -- 部门名称
  s.seriestheme as series_theme_code, -- 系列主题编码
  st.fvalue as series_theme_name, -- 系列主题名称
  concat('[',s.seriestheme,']',st.fvalue) as series_theme_display_name, -- 系列主题显示名称
  s.collaborationip as collaboration_ip_code, -- 联名IP编码
  cip.name as collaboration_ip_name, -- 联名IP名称
  concat('[',s.collaborationip,']',cip.name) as collaboration_ip_display_name, -- 联名IP显示名称
  date_format(s.launchdate,'%Y-%m-%d') as launch_date, -- 上市日期
  g.rtlprc as retail_price, -- 零售价
  pt.fvalue as product_type, -- 产品线(产品类型)
  pm.fvalue as play_mode, -- 玩法
  dp.fvalue as product_property, -- 商品属性
  g.bzxs as packaging_form, -- 包装形式
  regexp_replace(g.style,'\\[.*?\\]','') as style, -- 款式
  g.hegui as box_spec, -- 商品盒规
  g.xianggui as case_spec, -- 商品箱规
  g.createdate as created_time, -- 创建时间
  g.lstupdtime as last_modified_time, -- 最后修改时间
  cast(if(sop3.scode='020702',1,0) as tinyint) as is_shopping_bag -- 是否为购物袋
from sds.goods as g -- 商品
left join sds.series as s -- 系列
on g.series = s.code
left join (
  select 
    mainseries,
    name 
  from sds.series 
  where mainseries = code
) as ms -- 主系列
on s.mainseries = ms.mainseries
left join sds.sortname as sop1 -- 产品大类
on sop1.acode = '0000' 
and substr(s.sort,1,2) = sop1.scode
left join sds.sortname as sop2 -- 产品中类
on sop2.acode = '0000' 
and substr(s.sort,1,4) = sop2.scode
left join sds.sortname as sop3 -- 产品小类
on sop3.acode = '0000' 
and substr(s.sort,1,6) = sop3.scode
left join sds.sortname as sob1 -- 商业一级
on sob1.acode = 'P0001'
and substr(regexp_substr(g.def_datasort,'\\d+'),1,2) = sob1.scode 
left join sds.sortname as sob2 -- 商业二级
on sob2.acode = 'P0001'
and substr(regexp_substr(g.def_datasort,'\\d+'),1,4) = sob2.scode 
left join sds.sortname as sob3 -- 商业三级
on sob3.acode = 'P0001'
and regexp_substr(g.def_datasort,'\\d+') = sob3.scode 
left join sds.series_ip_config as ip -- IP
on s.ip = ip.code 
left join sds.series_ip_config as cip -- 联名IP 
on s.collaborationip = cip.code 
left join sds.ppro_options as st -- 系列主题
on st.type = 'SERIESTHEME' 
and s.seriestheme = st.fkey
left join sds.ppro_options as dp -- 商品属性
on dp.type = 'devProperty' 
and s.devProperty = dp.fkey 
left join sds.ppro_options as pm -- 玩法 
on pm.type = 'playMode' 
and s.playMode = pm.fkey
left join sds.ppro_options as pt -- 产品线 
on pt.type = 'productType' 
and s.productType = pt.fkey;
