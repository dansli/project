 -- ------------------ ---------------------------
-- Subject:BI-看板-门店销售库存监控看板-销售
-- Author: 郭婧
-- Create: 2025-06-12
-- Update: 更新时间  姓名  更改内容
-- ---------------------------------------------
SELECT 
    od.tran_date, -- 交易日期
    od.item_name,  -- 商品名称
    od.item_code,  -- 商品CODE
    od.customer_2nd_cat_name, -- 客户二级分类
    od.sale_country, -- 销售国家
    od.customer_continent, -- 客户所属洲
    od.customer_category as 客户一级类别,
    od.subsidiary_name as 主体名称,
    od.subsidiary_country as 客户国际,
    od.subsidiary_continent as 主体洲,
	od.product_count as product_count,  -- 销量
    od.incl_tax_rmb_amount as incl_tax_rmb_amount, -- 含税人民币金额
	od.incl_tax_foreign_amount as foreign_amount,  -- 含税外币金额
    od.customer_name, -- 客户名称
    c.subsidiary_regional_segmentation as 国家地区,
    i.custitem_pm_item_main_barcode as 六九码
    m.ip_lvl as ip等级,
	oi.ip_type,
    oi.custitem_pm_item_box, -- 箱规
    oi.custitem_pm_item_case, -- 盒规
    oi.custitem_pm_up_date, -- 上市时间
    oi.custitem_pm_english_name, -- 商品名称 英文
    oi.oversea_ip_name as name,  -- 海外IP名称
    oi.zbigtype_txt as 海鼎大类,
    oi.zmiddletype_txt as 海鼎中类,
    oi.zlittletype_txt as 海鼎小类,
    oi.first_class_name_cn as 海外一级, 
    oi.second_class_name_cn as 海外二级,
    oi.zbusiness1_txt as 商业一级,
    oi.zbusiness2_txt as 商业二级,
    oi.zbusiness3_txt as 商业三级,
    oi.fullname as 二零码, 
    oi.custitem_pm_china_price as 国内建议零售价,  
FROM
(
	SELECT 
		tran_date, -- 交易日期
		item_name,  -- 商品名称
		item_code,  -- 商品CODE
		customer_2nd_cat_name, -- 客户二级分类
		sale_country, -- 销售国家
		customer_continent, -- 客户所属洲
		customer_category  ,-- 客户一级类别 
		subsidiary_name  , -- 主体名称
		subsidiary_country,  -- 客户国际,
		subsidiary_continent , -- 主体洲
		customer_name, -- 客户名称
		customer_code,  -- 客户编码
		sum(product_count) as product_count,  -- 销量
		sum(incl_tax_rmb_amount) as incl_tax_rmb_amount, -- 含税人民币金额
		sum(incl_tax_foreign_amount) as incl_tax_foreign_amount  -- 含税外币金额
	FROM ns.dws_oversea_order_v2_detail	
	WHERE tran_date >= '${begindate}'
		AND tran_date <= '${ENDdate}'
		AND IS_TARGET = 1
    GROUP BY tran_date, -- 交易日期
		item_name,  -- 商品名称
		item_code,  -- 商品CODE
		customer_2nd_cat_name, -- 客户二级分类
		sale_country, -- 销售国家
		customer_continent, -- 客户所属洲
		customer_category  ,-- 客户一级类别 
		subsidiary_name  , -- 主体名称
		subsidiary_country,  -- 客户国际,
		subsidiary_continent , -- 主体洲
		customer_name, -- 客户名称
		customer_code -- 客户编码
) od
LEFT JOIN 
(
	SELECT subsidiary_regional_segmentation, --  国家地区
	  entityid
	FROM ns.zods_customer
)c	
ON od.customer_code = c.entityid 
LEFT JOIN 
(
	SELECT 
		 itemid
		,ip_type
		,custitem_pm_item_box 	-- 箱规
		,custitem_pm_item_case 	-- 盒规
		,custitem_pm_up_date 	-- 上市时间
		,custitem_pm_english_name -- 商品名称 英文
		,oversea_ip_name   		-- 海外IP名称
		,zbigtype_txt 			-- 海鼎大类
		,zmiddletype_txt 		-- 海鼎中类
		,zlittletype_txt 		-- 海鼎小类
		,first_class_name_cn 	-- 海外一级 
		,second_class_name_cn 	-- 海外二级
		,zbusiness1_txt 		-- 商业一级
		,zbusiness2_txt 		-- 商业二级
		,zbusiness3_txt 		-- 商业三级
		,fullname 				-- 二零码 
		,custitem_pm_china_price -- 国内建议零售价
	FROM ns.dim_oversea_item
)oi
ON od.item_code = oi.itemid  
LEFT JOIN 
(
	SELECT itemid,custitem_pm_item_main_barcode --  六九码
	FROM ns.item
) i
ON od.item_code = i.itemid
LEFT JOIN 
(
	SELECT country,ip_lvl,store_type,ip_type
	FROM  dw.dim_manual_country_ip_lvl
)m 
ON m.country = c.subsidiary_regional_segmentation
  AND m.store_type = oi.zbusiness2_txt
  AND m.ip_type = oi.oversea_ip_name