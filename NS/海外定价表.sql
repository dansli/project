---- 海外定价表
select 
  b.hd_item_id as SKU,
  b.item_displayname as "商品名称",
  b.item_english_name as "英文名称",
  c.series_code as "系列编码",
  c.series_name as "系列名称",
  b.item_main_barcode as  "商品条码",
  b.item_business_1st_class_name as "商业一级",
  b.item_business_2nd_class_name as "商业二级",
  b.item_business_3rd_class_name as "商业三级",
  b.item_price_cn as "吊牌价",
  b.item_box_spec as "盒规",
  b.item_case_spec as "箱规",
  c.series_ip_name as IP,
  b.item_launch_date as "上市日期",
  d.name as "销售国家",
  a.custrecord_item_rrp_included_tax as "是否含税",
  nvl(custrecord_link_item_price, custrecord_item_rrp_suggest_price) as "对应国家含税价格",
  e.custrecord_pm_69_main_barcode
from ns.customrecord_item_rrp as a
left join 
(
	SELECT 
		 item_id
		,series_id
		,hd_item_id 					-- SKU
		,item_displayname 				-- 商品名称
		,item_english_name 				-- 英文名称
		,item_main_barcode 				-- 商品条码
		,item_business_1st_class_name 	-- 商业一级
		,item_business_2nd_class_name 	-- 商业二级
		,item_business_3rd_class_name 	-- 商业三级
		,item_price_cn 					-- 吊牌价
		,item_box_spec 					-- 盒规
		,item_case_spec 				-- 箱规
		,item_launch_date 				-- 上市日期
	FROM dw.dim_ns_item_info
) b 
on a.custrecord_link_item = b.item_id
left join 
(
	SELECT
	 	 series_id
		,series_code 	-- 系列编码
		,series_name 	-- 系列名称
		,series_ip_name -- IP
	FROM dw.dim_ns_series_info 
)c 
on b.series_id = c.series_id
left join ns.customrecord_hc_trading_country as d 
	on a.custrecord_item_rrp_country_region=d.custrecord_hc_tc_name_en and d.isinactive = 'F'
left join ns.customrecord_pm_item_code_list as e 
	on a.custrecord_link_itemcode = e.id
where a.isinactive = 'F'
  and e.custrecord_pm_69_main_barcode = 'T'
  
  
 

NS表-ns.customrecord_pm_item_code_list-物料代码列表自定义记录
NS表-ns.customrecord_item_rrp-物料建议零售价自定义记录
视图-dw.dim_ns_item_info
视图-dw.dim_ns_series_info

----------------------------------------------------- 视图--dim_ns_item_info----------------------------------
   CREATE VIEW `dw`.`dim_ns_item_info` AS SELECT
  `item`.`id` `item_id`
, `item`.`itemtype` `item_type`
, `item`.`custitem_pm_spu_id` `item_spu_id`
, `item`.`itemid` `hd_item_id`
, `item`.`custitem_pm_item_main_barcode` `item_main_barcode`
, `item`.`displayname` `item_displayname`
, `item`.`custitem_pm_english_name` `item_english_name`
, `ns`.`to_date`(`item`.`custitem_pm_up_date`) `item_launch_date`
, `item`.`custitem_pm_item_case` `item_box_spec`
, `item`.`custitem_pm_item_box` `item_case_spec`
, `item`.`custitem_pm_item_packing` `item_packing_method`
, `item`.`custitem_pm_selling_gameplay` `item_selling_gameplay`
, `item`.`custitem_pm_china_price` `item_price_cn`
, `item`.`custitem_pm_int_key` `purchase_price_excl_tax`
, `item`.`custitem_pm_item_purchase_price` `contract_purchase_price`
, `cat`.`item_cat_1st_name`
, `cat`.`item_cat_1st_name_en`
, `cat`.`item_cat_1st_name_cn`
, `cat`.`item_cat_2nd_name`
, `cat`.`item_cat_2nd_name_en`
, `cat`.`item_cat_2nd_name_cn`
, `ip`.`first_ip_name` `first_ip_name`
, `ip`.`first_ip_id` `first_ip_id`
, `ip`.`first_iptype_name` `first_iptype_name`
, `ip`.`num_of_ips` `num_of_ips`
, `ip`.`ip_list` `ip_list`
, `ip`.`iptype_list` `iptype_list`
, `item`.`custitem_pop_oversea_ip` `oversea_ip_id`
, `oip`.`name` `oversea_ip_name`
, `item`.`custitem_pm_item_series` `series_id`
, `item`.`custitem_pm_business_1st_class` `item_business_1st_class_name`
, `item`.`custitem_pm_business_2nd_class` `item_business_2nd_class_name`
, `item`.`custitem_pm_business_3rd_class` `item_business_3rd_class_name`
, `si`.`main_series_code` `main_series_code`
, `si`.`series_product_model` `series_product_model`
, `si`.`series_product_properties` `series_product_properties`
, `si`.`series_product_line` `series_product_line`
, `si`.`series_product_team` `series_product_team`
, `si`.`series_power_supply_type` `series_power_supply_type`
, `si`.`series_brand` `series_brand`
, `si`.`series_goods_properties` `series_goods_properties`
, `si`.`series_class_code` `series_class_code`
, `si`.`series_business_sector` `series_business_sector`
, `si`.`series_play_method` `series_play_method`
, `si`.`series_battery_cnt` `series_battery_cnt`
, `si`.`series_battery_type` `series_battery_type`
, `si`.`series_code` `series_code`
, `si`.`series_name` `series_name`
, `si`.`series_english_name` `series_english_name`
, `si`.`series_mark` `series_mark`
, `si`.`series_box_spec` `series_box_spec`
, `si`.`series_case_spec` `series_case_spec`
, `si`.`series_hidden_prob` `series_hidden_prob`
, `si`.`series_hidden_number` `series_hidden_number`
, `si`.`series_ip_name` `series_ip_name`
, `si`.`series_joint_ip_name` `series_joint_ip_name`
, `si`.`series_oversea_ip_name` `series_oversea_ip_name`
, `si`.`series_1st_cat_name` `series_1st_cat_name`
FROM
  ((((`ns`.`item` `item`
LEFT JOIN `dw`.`dim_ns_category_info` `cat` ON (`cat`.`item_cat_2nd_id` = `item`.`class`))
LEFT JOIN `dw`.`dim_ns_item_ip_info` `ip` ON (`item`.`id` = `ip`.`item_id`))
LEFT JOIN `ns`.`customrecord_pop_oversea_ip` `oip` ON (`item`.`custitem_pop_oversea_ip` = `oip`.`id`))
LEFT JOIN `dw`.`dim_ns_series_info` `si` ON (`item`.`custitem_pm_item_series` = `si`.`series_id`))



----------------------------------------------------- 视图--dim_ns_category_info----------------------------------
 CREATE VIEW `dw`.`dim_ns_category_info` AS SELECT
  `a`.`id` `item_cat_2nd_id`
, `b`.`id` `item_cat_1st_id`
, `a`.`name` `item_cat_2nd_name`
, `b`.`name` `item_cat_1st_name`
, `a`.`fullname` `item_cat_2nd_fullname`
, `b`.`fullname` `item_cat_1st_fullname`
, `a`.`custrecord_pm_class_name_cn` `item_cat_2nd_name_cn`
, `b`.`custrecord_pm_class_name_cn` `item_cat_1st_name_cn`
, `a`.`custrecord_pm_class_name_en` `item_cat_2nd_name_en`
, `b`.`custrecord_pm_class_name_en` `item_cat_1st_name_en`
FROM
  (`ns`.`classification` `a`
LEFT JOIN `ns`.`classification` `b` ON (`a`.`parent` = `b`.`id`))
WHERE ((`a`.`custrecord_pm_parent_class` <> 'T') OR (`a`.`custrecord_pm_parent_class` IS NULL))

----------------------------------------------------- 视图--dim_ns_item_ip_info----------------------------------
 CREATE VIEW `dw`.`dim_ns_item_ip_info` AS WITH
  tmp AS (
   SELECT
     `a`.`mapone` `item_id`
   , `ip_id`
   , `ns`.`first_value`(`ip_id`) OVER (PARTITION BY `mapone` ORDER BY `maptwo` ASC) `first_ip_id`
   , `ns`.`first_value`(`ip_name`) OVER (PARTITION BY `mapone` ORDER BY `maptwo` ASC) `first_ip_name`
   , `ns`.`first_value`(`iptype_name`) OVER (PARTITION BY `mapone` ORDER BY `maptwo` ASC) `first_iptype_name`
   , `ip_name`
   , `iptype_name`
   , `update_datetime` `update_datetime`
   FROM
     (`ns`.`map_item_custitem_pm_item_ipicon` `a`
   LEFT JOIN `dw`.`dim_ns_ip_info` `b` ON (`a`.`maptwo` = `b`.`ip_id`))
) 
SELECT
  `a`.`item_id` `item_id`
, `a`.`first_ip_id` `first_ip_id`
, `a`.`first_ip_name` `first_ip_name`
, `a`.`first_iptype_name` `first_iptype_name`
, `a`.`num_of_ips` `num_of_ips`
, `a`.`ip_list` `ip_list`
, `a`.`update_datetime`
, `b`.`iptype_list` `iptype_list`
FROM
  ((
   SELECT
     `item_id`
   , `first_ip_id`
   , `first_ip_name`
   , `first_iptype_name`
   , `array_join_separator`(`array_agg`(`ip_name`)) `ip_list`
   , `ns`.`count`(*) `num_of_ips`
   , `ns`.`max`(COALESCE(`update_datetime`, '1900-01-01 00:00:00')) `update_datetime`
   FROM
     (
      SELECT *
      FROM
        `tmp`
      ORDER BY `item_id` ASC, `ip_id` ASC
   ) 
   GROUP BY 1, 2, 3, 4
)  `a`
LEFT JOIN (
   SELECT
     `item_id`
   , `array_join_separator`(`array_agg`(`iptype_name`)) `iptype_list`
   FROM
     (
      SELECT DISTINCT
        `item_id`
      , `iptype_name`
      FROM
        `tmp`
      ORDER BY `item_id` ASC, `iptype_name` ASC
   ) 
   GROUP BY 1
)  `b` ON (`a`.`item_id` = `b`.`item_id`))

 CREATE VIEW `dw`.`dim_ns_ip_info` AS SELECT
  `a`.`id` `ip_id`
, `a`.`name` `ip_name`
, `a`.`owner` `owner`
, `a`.`custrecord_pm_ip_company` `custrecord_pm_ip_company`
, `a`.`custrecord_pm_ip_china_contact` `custrecord_pm_ip_china_contact`
, `a`.`custrecord_pm_ip_vendor_contact` `custrecord_pm_ip_vendor_contact`
, `a`.`custrecord_pm_ip_country_of_origin` `custrecord_pm_ip_country_of_origin`
, `a`.`custrecord_pm_ip_contract_lastmodified` `update_datetime`
, `b`.`name` `iptype_name`
FROM
  (`ns`.`customrecord_pm_ip_icon` `a`
LEFT JOIN `ns`.`customlist_pm_ip_type` `b` ON ((`b`.`id` = `a`.`custrecord_pm_ip_type`) AND (`b`.`isinactive` = 'F')))


----------------------------------------------------- 视图--dim_ns_series_info----------------------------------
 CREATE VIEW `dw`.`dim_ns_series_info` AS SELECT
  `se`.`id` `series_id`
, `se`.`lastmodified` `last_update_datetime`
, `se`.`lastmodifiedby` `last_update_by`
, `se`.`custrecord_pm_series_up_date` `series_launch_date`
, `se`.`custrecord_pm_series_main` `main_series_code`
, `se`.`custrecord_pm_series_product_model` `series_product_model`
, `se`.`custrecord_pm_series_product_properties` `series_product_properties`
, `se`.`custrecord_pm_series_product_line` `series_product_line`
, `se`.`custrecord_pm_series_product_team` `series_product_team`
, `se`.`custrecord_pm_series_powersupplytype` `series_power_supply_type`
, `se`.`custrecord_pm_series_brand` `series_brand`
, `se`.`custrecord_pm_series_goods_properties` `series_goods_properties`
, `se`.`custrecord_pm_series_goods_class` `series_class_code`
, `se`.`custrecord_pm_series_business_sector` `series_business_sector`
, `se`.`custrecord_pm_series_play_method` `series_play_method`
, `se`.`custrecord_pm_series_batterycnt` `series_battery_cnt`
, `se`.`custrecord_pm_series_batterytype` `series_battery_type`
, `se`.`custrecord_pm_series_code` `series_code`
, `se`.`custrecord_pm_series_name` `series_name`
, `se`.`custrecord_pm_series_ename` `series_english_name`
, `se`.`custrecord_pm_series_mark` `series_mark`
, `se`.`custrecord_pm_series_box` `series_box_spec`
, `se`.`custrecord_pm_series_case` `series_case_spec`
, `se`.`custrecord_pm_series_hidden_probability` `series_hidden_prob`
, `se`.`custrecord_pm_series_hidden_number` `series_hidden_number`
, `ipar`.`name` `series_ip_name`
, `iparj`.`name` `series_joint_ip_name`
, `oip`.`name` `series_oversea_ip_name`
, `cls`.`name` `series_1st_cat_name`
FROM
  ((((`ns`.`customrecord_pm_series` `se`
LEFT JOIN `ns`.`customrecord_pm_ip_archive` `ipar` ON ((`se`.`custrecord_pm_series_ip` = `ipar`.`id`) AND (`ipar`.`isinactive` = 'F')))
LEFT JOIN `ns`.`customrecord_pm_ip_archive` `iparj` ON ((`se`.`custrecord_pm_series_joint_ip` = `iparj`.`name`) AND (`iparj`.`isinactive` = 'F')))
LEFT JOIN `ns`.`customrecord_pop_oversea_ip` `oip` ON (`se`.`custrecord_pm_series_oversea_ip` = `oip`.`id`))
LEFT JOIN `ns`.`classification` `cls` ON (`se`.`custrecord_pm_series_oversea_class` = `cls`.`id`))
WHERE (`se`.`isinactive` = 'F')
