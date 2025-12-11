 -- ------------------ ---------------------------
-- Subject:BI-看板-门店销售库存监控看板-库存
-- Author: 郭婧
-- Create: 2025-06-12
-- Update: 更新时间  姓名  更改内容
-- ---------------------------------------------
-- CREATE TABLE dw.ads_ns_bi_inv_mntr_total
-- (
--      inv_id 			BIGINT   COMMENT'库存点id'
--     ,inv_name 			VARCHAR  COMMENT'库存点名称'
-- 	,inv_type  			VARCHAR  COMMENT'库存点类型'
-- 	,item_id 			BIGINT   COMMENT'商品ID'
-- 	,item_code 			VARCHAR  COMMENT'商品CODE'
-- 	,item_name 			VARCHAR  COMMENT'商品名称'
-- 	,bar_code  			VARCHAR  COMMENT'商品主条码'
-- 	,biz_date 			DATETIME COMMENT'日期'
-- 	,inv_cnt  			VARCHAR  COMMENT'当地库存数量 (库存总量-锁定库存)'
-- 	,way_cnt 			VARCHAR  COMMENT'在途数量'
-- 	,country_id     	BIGINT   COMMENT'国家ID'
-- 	,country_code  	    VARCHAR  COMMENT'国家CODE'
--     ,country_name		VARCHAR  COMMENT'国家名称'
--     ,cus_name  			VARCHAR  COMMENT'客户名称'
-- 	,etl_time			TIMESTAMP	 COMMENT '插入日期'
-- 	,PRIMARY KEY (inv_id,item_id,biz_date)
-- )COMMENT'门店销售库存监控看板-库存';

-- DELETE FROM dw.ads_ns_bi_inv_mntr_total
--  WHERE biz_date >='${last_60days}' ;
 
INSERT INTO dw.ads_ns_bi_inv_mntr_total 
SELECT 
     inv.inv_id 			-- 库存点id
    ,inv.inv_name 			-- 库存点名称
	,inv.inv_type  			-- 库存点类型
	,inv.item_id 			-- 商品ID
	,inv.item_code 			-- 商品CODE
	,inv.item_name 			-- 商品名称
	,inv.bar_code  			-- 商品主条码
	,inv.biz_date 			-- 日期
	,inv.inv_cnt  			-- 当地库存数量 (库存总量-锁定库存)
	,inv.way_cnt 			-- 在途数量
	,loc.country_id     	-- 国家ID
	,sub.country_code   	-- 国家CODE
    ,chtc.country_name		-- 国家名称
    ,mcw.cus_name  			-- 客户名称
    ,SYSDATE() AS etl_time  -- 插入日期
FROM 
(-- 库存表
	SELECT 
		 locationid   AS inv_id 	-- 库存点id
		,location_txt AS inv_name	-- 库存点名称
		,CASE 
		  WHEN locationtype IS NULL THEN 'Non_Location_Type' 
			ELSE locationtype 
		 END 		AS inv_type -- 库存点类型
		,itemid		AS item_id
		,item_code  AS item_code
		,item_txt 	AS item_name
		,barcode 	AS  bar_code  -- 商品主条码
		,zcalday  	AS  biz_date -- 日期
		,quantityonhand - quantitycommitted as  inv_cnt -- 当地库存数量 (库存总量-锁定库存)
		,on_theway 	AS way_cnt -- 在途数量
	FROM ns.zmm_dwb002
 	-- WHERE  zcalday >='${last_60days}'   -- 更新前60天数据
	-- 	AND zcalday <'${next_day}'    
)inv
LEFT JOIN
(
	SELECT id,subsidiary as country_id
	FROM ns.location
)loc
ON  inv.inv_id = loc.id
LEFT JOIN 
(
	SELECT id,country AS country_code
	FROM ns.subsidiary 
)sub
 ON loc.country_id = sub.id
LEFT JOIN 
( 
	SELECT custrecord_hc_tc_country_code AS country_id
		   ,CASE 
			  WHEN name = '台湾,中国' THEN '中国台湾'
			  WHEN name = '香港,中国' THEN '中国香港'
			  ELSE name 
			END AS country_name
	FROM ns.customrecord_hc_trading_country
)chtc
ON sub.country_code = chtc.country_id
LEFT JOIN 
( --  手工表 门店仓库映射表
	SELECT whse_name  -- 仓库名称
			,cus_name -- 客户名称
	FROM dw.dim_manual_country_whse
)mcw
ON inv.inv_name = mcw.whse_name