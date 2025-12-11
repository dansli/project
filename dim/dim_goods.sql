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
  i.id as ns_sku_id, -- ns商品id
  i.displayname as ns_sku_name, -- ns商品名称
  i.CUSTITEM_PM_ENGLISH_NAME as ns_sku_english_name, -- ns商品英文名称
  i.custitem_pm_item_main_barcode as ns_sku_69_code, -- 69码
  i.itemid as ns_sku_20_code, -- 20码
  ii.name as second_class_name_en, -- 海外二级分类英文
  iii.name as first_class_name_en, -- 海外一级分类英文
  ii.custrecord_pm_class_name_cn as second_class_name_cn, -- 海外二级分类中文
  iii.custrecord_pm_class_name_cn as first_class_name_cn, -- 海外一级分类中文
  g.gid as hd_sku_id, -- hd商品id
  g.code as hd_sku_code, -- hd商品编码
  g.name as hd_sku_name, -- hd商品名称
  g.code2 as hd_sku_barcode, -- hd商品条码
  concat('[', g.code, ']', g.name) as hd_sku_display_name, -- hd商品显示名称
  g.series as series_code, -- 系列编码
  s.name as series_name, -- 系列名称
  concat('[', g.series, ']', s.name) as series_display_name, -- 系列显示名称
  s.mainseries as main_series_code, -- 主系列编码
  ms.name as main_series_name, -- 主系列名称
  sop1.scode as product_category_code1, -- 产品大类编码
  sop1.sname as product_category_name1, -- 产品大类名称
  concat('[', sop1.scode, ']', sop1.sname) as product_category_display_name1, -- 产品大类显示名称
  sop2.scode as product_category_code2, -- 产品中类编码
  sop2.sname as product_category_name2, -- 产品中类名称
  concat('[', sop2.scode, ']', sop2.sname) as product_category_display_name2, -- 产品中类显示名称
  sop3.scode as product_category_code3, -- 产品小类编码
  sop3.sname as product_category_name3, -- 产品小类名称
  concat('[', sop3.scode, ']', sop3.sname) as product_category_display_name3, -- 产品小类显示名称
  sob1.scode as business_category_code1, -- 商业一级编码
  sob1.sname as business_category_name1, -- 商业一级名称
  concat('[', sob1.scode, ']', sob1.sname) as business_category_display_name1, -- 商业一级显示名称
  sob2.scode as business_category_code2, -- 商业二级编码
  sob2.sname as business_category_name2, -- 商业二级名称
  concat('[', sob2.scode, ']', sob2.sname) as business_category_display_name2, -- 商业二级显示名称
  sob3.scode as business_category_code3, -- 商业三级编码
  sob3.sname as business_category_name3, -- 商业三级名称
  concat('[', sob3.scode, ']', sob3.sname) as business_category_display_name3, -- 商业三级显示名称
  s.ip as ip_code, -- IP编码
  ip.name as ip_name, -- IP名称
  concat('[', s.ip, ']', ip.name) as ip_display_name, -- IP显示名称
  g.def_dept as department_name, -- 部门名称
  s.seriestheme as series_theme_code, -- 系列主题编码
  st.fvalue as series_theme_name, -- 系列主题名称
  concat('[', s.seriestheme, ']', st.fvalue) as series_theme_display_name, -- 系列主题显示名称
  s.collaborationip as collaboration_ip_code, -- 联名IP编码
  cip.name as collaboration_ip_name, -- 联名IP名称
  concat('[', s.collaborationip, ']', cip.name) as collaboration_ip_display_name, -- 联名IP显示名称
  date_format(s.launchdate, '%Y-%m-%d') as launch_date, -- 上市日期
  g.rtlprc as retail_price, -- 零售价
  pt.fvalue as product_type, -- 产品线(产品类型)
  pm.fvalue as play_mode, -- 玩法
  dp.fvalue as product_property, -- 商品属性
  g.bzxs as packaging_form, -- 包装形式
  regexp_replace(g.style, '\\[.*?\\]', '') as style, -- 款式
  g.hegui as box_spec, -- 商品盒规
  g.xianggui as case_spec, -- 商品箱规
  g.createdate as created_time, -- 创建时间
  g.lstupdtime as last_modified_time, -- 最后修改时间
  cast(if(sop3.scode = '020702', 1, 0) as tinyint) as is_shopping_bag -- 是否为购物袋
from
  ns.item as i FULL OUTER
  JOIN sds.goods as g -- 商品
  on i.itemid = g.code
  LEFT JOIN (
    SELECT
      fullname,
      name,
      id,
      parent,
      custrecord_pm_class_name_cn
    FROM
      ns.classification
  ) as ii ON i.class = ii.id
  LEFT JOIN (
    SELECT
      fullname,
      name,
      id,
      parent,
      custrecord_pm_class_name_cn
    FROM
      ns.classification
  ) as iii ON ii.parent = iii.id
  left join sds.series as s -- 系列
  on g.series = s.code
  left join (
    select
      mainseries,
      name
    from
      sds.series
    where
      mainseries = code
  ) as ms -- 主系列
  on s.mainseries = ms.mainseries
  left join sds.sortname as sop1 -- 产品大类
  on sop1.acode = '0000'
  and substr(s.sort, 1, 2) = sop1.scode
  left join sds.sortname as sop2 -- 产品中类
  on sop2.acode = '0000'
  and substr(s.sort, 1, 4) = sop2.scode
  left join sds.sortname as sop3 -- 产品小类
  on sop3.acode = '0000'
  and substr(s.sort, 1, 6) = sop3.scode
  left join sds.sortname as sob1 -- 商业一级
  on sob1.acode = 'P0001'
  and substr(regexp_substr(g.def_datasort, '\\d+'), 1, 2) = sob1.scode
  left join sds.sortname as sob2 -- 商业二级
  on sob2.acode = 'P0001'
  and substr(regexp_substr(g.def_datasort, '\\d+'), 1, 4) = sob2.scode
  left join sds.sortname as sob3 -- 商业三级
  on sob3.acode = 'P0001'
  and regexp_substr(g.def_datasort, '\\d+') = sob3.scode
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
  and s.productType = pt.fkey
WHERE
  iii.name IS NOT NULL--  CREATE TABLE  IF NOT EXISTS  dw.dim_goods
--  (
-- 	  sku_code				varchar	 COMMENT'商品编码'
-- 	 ,sku_barcode 			varchar	 COMMENT'商品条码'
-- 	 ,sku_name 				varchar	 COMMENT'商品名称'
-- 	 ,sku_display_name 		varchar	 COMMENT'商品显示名称'
-- 	 ,sku_name_en			varchar	 COMMENT'商品英文名称'
-- 	 ,sku_ns_id				varchar	 COMMENT'ns商品ID'
-- 	 ,sku_hd_id 			varchar	 COMMENT'HD商品ID'
-- 	 ,department_name 		varchar	 COMMENT'部门名称'
-- 	 ,retail_price 			double	 COMMENT'零售价'
-- 	 ,expcntin_price		double	 COMMENT'商品采购单价'
-- 	 ,packaging_form 		varchar	 COMMENT'包装形式'
-- 	 ,style 				varchar	 COMMENT'款式'
-- 	 ,box_spec 				varchar	 COMMENT'商品盒规'
-- 	 ,case_spec 			varchar	 COMMENT'商品箱规'
-- 	 ,created_time 			datetime COMMENT'创建时间'
-- 	 ,last_modified_time 	datetime COMMENT'最后修改时间'
-- 	 ,second_class_name_en 	varchar	 COMMENT'海外二级分类英文'
-- 	 ,first_class_name_en 	varchar	 COMMENT'海外一级分类英文'
-- 	 ,second_class_name_cn 	varchar	 COMMENT'海外二级分类中文'
-- 	 ,first_class_name_cn 	varchar	 COMMENT'海外一级分类中文'
-- 	 ,first_class_code		varchar	 COMMENT'海外一级分类编码'
-- 	 ,second_class_code		varchar	 COMMENT'海外二级分类编码'
-- 	 ,series_code 			varchar	 COMMENT'系列编码'
-- 	 ,series_name 			varchar	 COMMENT'系列名称'
-- 	 ,series_display_name 	varchar	 COMMENT'系列显示名称'
-- 	 ,main_series_code 		varchar	 COMMENT'主系列编码'
-- 	 ,main_series_name 		varchar	 COMMENT'主系列名称'
-- 	 ,launch_date 			datetime COMMENT'上市日期'
-- 	 ,pro_cat_code			varchar	 COMMENT'产品大类编码'
-- 	 ,pro_cat_name1 		varchar	 COMMENT'产品大类名称'
-- 	 ,pro_cat_disp_name1 	varchar	 COMMENT'产品大类显示名称'
-- 	 ,pro_cat_code2 		varchar	 COMMENT'产品中类编码'
-- 	 ,pro_cat_name2 		varchar	 COMMENT'产品中类名称'
-- 	 ,pro_cat_dis_name2 	varchar	 COMMENT'产品中类显示名称'
-- 	 ,pro_cat_code3 		varchar	 COMMENT'产品小类编码'
-- 	 ,pro_cat_name3 		varchar	 COMMENT'产品小类名称'
-- 	 ,pro_cat_dis_name3 	varchar	 COMMENT'产品小类显示名称'
-- 	 ,ip_code 				varchar	 COMMENT'IP编码'
-- 	 ,ip_name 				varchar	 COMMENT'IP名称'
-- 	 ,ip_dis_name 			varchar	 COMMENT'IP显示名称'
-- 	 ,is_shopping_bag 		int		 COMMENT'是否为购物袋'
-- 	 ,series_theme_code 	varchar	 COMMENT'系列主题编码'
-- 	 ,series_theme_name 	varchar	 COMMENT'系列主题名称'
-- 	 ,series_theme_dis_name varchar	 COMMENT'系列主题显示名称'
-- 	 ,coll_ip_code 			varchar	 COMMENT'联名IP编码'
-- 	 ,coll_ip_name 			varchar	 COMMENT'联名IP名称'
-- 	 ,coll_ip_dis_name 		varchar	 COMMENT'联名IP显示名称'
-- 	 ,pro_type 				varchar	 COMMENT'产品线(产品类型)'
-- 	 ,play_mode 			varchar	 COMMENT'玩法'
-- 	 ,pro_property 			varchar	 COMMENT'商品属性'
-- 	 ,bus_cat_code1 		varchar	 COMMENT'商业一级编码'
-- 	 ,bus_cat_name1 		varchar	 COMMENT'商业一级名称'
-- 	 ,bus_cat_dis_name1 	varchar	 COMMENT'商业一级显示名称'
-- 	 ,bus_cat_code2 		varchar	 COMMENT'商业二级编码'
-- 	 ,bus_cat_name2 		varchar	 COMMENT'商业二级名称'
-- 	 ,bus_cat_dis_name2 	varchar	 COMMENT'商业二级显示名称'
-- 	 ,bus_cat_code3 		varchar	 COMMENT'商业三级编码'
-- 	 ,bus_cat_name3 		varchar	 COMMENT'商业三级名称'
-- 	 ,bus_cat_dis_name3 	varchar	 COMMENT'商业三级显示名称'
--      ,PRIMARY KEY (sku_code)
--  )COMMENT'商品信息表';


TRUNCATE TABLE dw.dim_goods;
INSERT INTO dw.dim_goods
SELECT	
	  NVL(t_goods.sku_code,t_item.sku_code) 	 AS  sku_code	-- 商品编码
	 ,NVL(t_goods.sku_barcode,t_item.sku_barcode)AS  sku_barcode -- 商品条码
	 ,NVL(t_goods.sku_name,t_item.sku_name)		 AS  sku_name 	-- 商品名称
	 ,t_goods.sku_display_name 		-- 商品显示名称
	 ,t_item.sku_name_en			-- 商品英文名称
	 ,t_item.sku_ns_id				-- ns商品id
	 ,t_goods.sku_hd_id 			-- HD商品ID
	 ,t_goods.department_name 		-- 部门名称
	 ,t_goods.retail_price 			-- 零售价
	 ,t_goods.expcntin_price		-- 商品采购单价
	 ,t_goods.packaging_form 		-- 包装形式
	 ,t_goods.style 				-- 款式
	 ,t_goods.box_spec 				-- 商品盒规
	 ,t_goods.case_spec 			-- 商品箱规
	 ,t_goods.created_time 			-- 创建时间
	 ,t_goods.last_modified_time 	-- 最后修改时间
	 ,t_class.second_class_name_en	-- 海外二级分类英文
	 ,t_class.first_class_name_en	-- 海外一级分类英文
	 ,t_class.second_class_name_cn	-- 海外二级分类中文
	 ,t_class.first_class_name_cn	-- 海外一级分类中文
	 ,t_class.first_class_code		-- 海外一级分类编码
	 ,t_class.second_class_code		-- 海外二级分类编码
	 ,t_ser.series_code	 			-- 系列编码
	 ,t_ser.series_name	 			-- 系列名称
	 ,t_ser.series_display_name	 	-- 系列显示名称
	 ,t_ser.main_series_code	 	-- 主系列编码
	 ,t_ser.main_series_name	 	-- 主系列名称
	 ,t_ser.launch_date	 			-- 上市日期
	 ,t_ser.pro_cat_code	 		-- 产品大类编码
	 ,t_ser.pro_cat_name1	 		-- 产品大类名称
	 ,t_ser.pro_cat_disp_name1	 	-- 产品大类显示名称
	 ,t_ser.pro_cat_code2	 		-- 产品中类编码
	 ,t_ser.pro_cat_name2	 		-- 产品中类名称
	 ,t_ser.pro_cat_dis_name2	 	-- 产品中类显示名称
	 ,t_ser.pro_cat_code3	 		-- 产品小类编码
	 ,t_ser.pro_cat_name3	 		-- 产品小类名称
	 ,t_ser.pro_cat_dis_name3	 	-- 产品小类显示名称
	 ,t_ser.ip_code	 				-- IP编码
	 ,t_ser.ip_name	 				-- IP名称
	 ,t_ser.ip_dis_name	 			-- IP显示名称
	 ,t_ser.is_shopping_bag	 		-- 是否为购物袋
	 ,t_ser.series_theme_code	 	-- 系列主题编码
	 ,t_ser.series_theme_name		-- 系列主题名称
	 ,t_ser.series_theme_dis_name	-- 系列主题显示名称
	 ,t_ser.coll_ip_code	 		-- 联名IP编码
	 ,t_ser.coll_ip_name	 		-- 联名IP名称
	 ,t_ser.coll_ip_dis_name	 	-- 联名IP显示名称
	 ,t_ser.pro_type	 			-- 产品线(产品类型)
	 ,t_ser.play_mode	 			-- 玩法
	 ,t_ser.pro_property	 		-- 商品属性 
	 ,sob1.scode 							   AS  bus_cat_code1 	-- 商业一级编码	
	 ,sob1.sname 							   AS  bus_cat_name1 	-- 商业一级名称	
	 ,CONCAT('[', sob1.scode, ']', sob1.sname) AS  bus_cat_dis_name1-- 商业一级显示名称	
	 ,sob2.scode 							   AS  bus_cat_code2 	-- 商业二级编码	
	 ,sob2.sname 							   AS  bus_cat_name2 	-- 商业二级名称	
	 ,CONCAT('[', sob2.scode, ']', sob2.sname) AS  bus_cat_dis_name2 -- 商业二级显示名称	
	 ,sob3.scode 							   AS  bus_cat_code3 	 -- 商业三级编码	
	 ,sob3.sname 							   AS  bus_cat_name3 	 -- 商业三级名称	
	 ,CONCAT('[', sob3.scode, ']', sob3.sname) AS  bus_cat_dis_name3 -- 商业三级显示名称	
FROM 
(-- NS 商品表
	SELECT  
		 id								   AS  sku_ns_id		-- ns商品id	
		,displayname 			 	       AS  sku_name		-- 商品名称	
		,custitem_pm_english_name 	       AS  sku_name_en	-- 商品英文名称	
		,custitem_pm_item_main_barcode     AS  sku_barcode	-- 商品显示名称	
		,itemid 						   AS  sku_code 		-- 商品编码	
		,class							
	FROM ns.item
)t_item
FULL JOIN 
( -- HD商品表
	SELECT
		 gid 						            AS  sku_hd_id 			-- 商品id	
		,code 						            AS  sku_code 			-- 商品编码	
		,name 						            AS  sku_name 			-- 商品名称	
		,code2						            AS  sku_barcode 		-- 商品条码	
		,CONCAT('[', code, ']', name)     	    AS  sku_display_name 	-- 商品显示名称	
		,def_dept 							    AS  department_name 	-- 部门名称	
		,rtlprc  							    AS  retail_price 		-- 零售价	
		,bzxs    							    AS  packaging_form 		-- 包装形式	
		,regexp_replace(style, '\\[.*?\\]', '') AS  style 				-- 款式	
		,hegui    							    AS  box_spec 			-- 商品盒规	
		,xianggui 							    AS  case_spec 			-- 商品箱规	
		,createdate  						    AS  created_time 		-- 创建时间	
		,lstupdtime  						    AS  last_modified_time 	-- 最后修改时间	
		,expcntinprc						    AS  expcntin_price		-- 商品采购单价
		,series -- 系列
		,def_datasort
	FROM sds.goods
)t_goods
	ON  t_item.sku_code=t_goods.sku_code
LEFT JOIN  
(-- 商品分类 
    SELECT	
		 t1.id	 							AS second_class_code 	-- 海外一级分类编码
		,t1.name 							AS second_class_name_en -- 海外二级分类英文	
		,t1.custrecord_pm_class_name_cn	 	AS second_class_name_cn -- 海外二级分类中文
		,t2.id	 							AS first_class_code 	-- 海外一级分类编码
		,t2.name   							AS first_class_name_en 	-- 海外一级分类英文		  
		,t2.custrecord_pm_class_name_cn	   	AS first_class_name_cn 	-- 海外一级分类中文	
    FROM ns.classification t1
	LEFT JOIN ns.classification t2
	ON t1.parent=t2.id	  
)t_class
	ON t_item.class = t_class.second_class_code	
LEFT JOIN 
( -- 系列
	SELECT 
		 t1.code 									    AS  series_code			    -- 系列编码
		,t1.name 									    AS  series_name  		    -- 系列名称
		,CONCAT('[', t1.code, ']', t1.name)			    AS  series_display_name     -- 系列显示名称	
		,t1.mainseries								    AS  main_series_code 	    -- 主系列编码	
		,t2.name									    AS  main_series_name 	    -- 主系列名称	
		,date_format(t1.launchdate, '%Y-%m-%d')         AS  launch_date             -- 上市日期	
		,sop1.scode 							        AS  pro_cat_code  		    -- 产品大类编码	
		,sop1.sname 							        AS  pro_cat_name1 		    -- 产品大类名称	
		,CONCAT('[', sop1.scode, ']', sop1.sname) 	    AS  pro_cat_disp_name1 	    -- 产品大类显示名称	
		,sop2.scode 							   	    AS  pro_cat_code2 		    -- 产品中类编码	
		,sop2.sname 							   	    AS  pro_cat_name2		    -- 产品中类名称	
		,CONCAT('[', sop2.scode, ']', sop2.sname) 	    AS  pro_cat_dis_name2 	    -- 产品中类显示名称	
		,sop3.scode 							   	    AS  pro_cat_code3 		    -- 产品小类编码	
		,sop3.sname 							   	    AS  pro_cat_name3 		    -- 产品小类名称	
		,CONCAT('[', sop3.scode, ']', sop3.sname) 	    AS  pro_cat_dis_name3 	    -- 产品小类显示名称
		,CAST(DECODE(sop3.scode,'020702',1,0) AS  INT)  AS  is_shopping_bag         -- 是否为购物袋	 		
		,t1.ip    								        AS  ip_code 				-- IP编码	
		,ip.name 								        AS  ip_name 				-- IP名称	
		,CONCAT('[', t1.ip, ']', ip.name) 		        AS  ip_dis_name 			-- IP显示名称	
		,t1.collaborationip 					        AS  coll_ip_code 		    -- 联名IP编码	
		,cip.name 								        AS  coll_ip_name 		    -- 联名IP名称	
		,CONCAT('[', t1.collaborationip, ']', cip.name) AS  coll_ip_dis_name 		-- 联名IP显示名称
		,t1.seriestheme 							    AS  series_theme_code 		-- 系列主题编码	
		,st.fvalue 							   			AS  series_theme_name 		-- 系列主题名称	
		,CONCAT('[',t1.seriestheme, ']',st.fvalue) 		AS  series_theme_dis_name 	-- 系列主题显示名称	
		,dp.fvalue 							   			AS  pro_property 			-- 商品属性	
	    ,pm.fvalue 							   			AS  play_mode 				-- 玩法	
		,pt.fvalue 							   			AS  pro_type 				-- 产品线(产品类型)	
	FROM sds.series t1 -- 系列
	LEFT JOIN sds.series t2  -- 主系列
		ON t1.mainseries=t2.code
		AND t2.mainseries = t2.code
	LEFT JOIN sds.sortname AS  sop1 -- 产品大类	
	  ON sop1.acode = '0000'	
		AND substr(t1.sort, 1, 2) = sop1.scode	
	LEFT JOIN  sds.sortname AS  sop2 -- 产品中类	
	  ON sop2.acode = '0000'	
		AND substr(t1.sort, 1, 4) = sop2.scode	
	LEFT JOIN  sds.sortname AS  sop3 -- 产品小类	
	  ON sop3.acode = '0000'	
		AND substr(t1.sort, 1, 6) = sop3.scode	
	LEFT JOIN sds.series_ip_config AS  ip -- IP	
	  ON t1.ip = ip.code	
	LEFT JOIN  sds.series_ip_config AS  cip -- 联名IP 	
	  ON t1.collaborationip = cip.code	
	LEFT JOIN  sds.ppro_options AS  st -- 系列主题	
	  ON st.type = 'SERIESTHEME'	
		AND t1.seriestheme = st.fkey	
	LEFT JOIN  sds.ppro_options AS  dp -- 商品属性	
	  ON dp.type = 'devProperty'	
		AND t1.devProperty = dp.fkey	
	LEFT JOIN  sds.ppro_options AS  pm -- 玩法 	
	  ON pm.type = 'playMode'	
		AND t1.playMode = pm.fkey	
	LEFT JOIN  sds.ppro_options AS  pt -- 产品线 	
	  ON pt.type = 'productType'	
		AND t1.producttype = pt.fkey	
)t_ser	
ON t_goods.series=t_ser.series_code
LEFT JOIN  sds.sortname AS  sob1 -- 商业一级	
  ON sob1.acode = 'P0001'	
	AND substr(regexp_substr(t_goods.def_datasort, '\\d+'), 1, 2) = sob1.scode	
LEFT JOIN  sds.sortname AS  sob2 -- 商业二级	
  ON sob2.acode = 'P0001'	
	AND substr(regexp_substr(t_goods.def_datasort, '\\d+'), 1, 4) = sob2.scode	
LEFT JOIN  sds.sortname AS  sob3 -- 商业三级	
  ON sob3.acode = 'P0001'	
	AND regexp_substr(t_goods.def_datasort, '\\d+') = sob3.scode	
WHERE	
  t_ser.main_series_name IS NOT NULL	

  ;