 CREATE VIEW `ns`.`dm_oversea_customer_income_day` AS WITH
  t1 AS (
   SELECT
     `a`.`tran_date`
   , `a`.`subsidiary`
   , `a`.`subsidiary_name`
   , `a`.`subsidiary_country`
   , `a`.`subsidiary_continent`
   , `a`.`customer_id`
   , `a`.`customer_code`
   , `a`.`customer_name`
   , `a`.`customer_city`
   , `a`.`customer_country`
   , `a`.`customer_continent`
   , `a`.`customer_category`
   , `a`.`customer_2nd_cat_name`
   , `a`.`customer_3nd_cat_name`
   , `a`.`sale_country`
   , `a`.`subsidiary_continent` `sale_continent`
   , `ns`.`sum`(`INCL_TAX_FOREIGN_AMOUNT`) `managment_performance`
   , `ns`.`sum`(`INCL_TAX_RMB_AMOUNT`) `managment_performance_rmb`
   , 0 `trade_count`
   , `ns`.`sum`(`a`.`product_count`) `product_count`
   , `a`.`is_target`
   FROM
     `dws_oversea_order_v2_detail` `a`
   GROUP BY `tran_date`, `subsidiary`, `subsidiary_name`, `subsidiary_country`, `subsidiary_continent`, `customer_id`, `customer_code`, `customer_name`, `customer_city`, `customer_country`, `customer_continent`, `customer_category`, `customer_2nd_cat_name`, `customer_3nd_cat_name`, `sale_country`, 16, `is_target`
) 
, t2 AS (
   SELECT
     `a`.`tran_date`
   , `a`.`subsidiary`
   , `a`.`customer_id`
   , `sale_country`
   , `is_target`
   , `ns`.`sum`((CASE WHEN (`a`.`tran_type` = 0) THEN `custbody_hp_counter` ELSE 0 END)) `sale`
   , `ns`.`sum`((CASE WHEN (`a`.`tran_type` = 1) THEN `custbody_hp_counter` ELSE 0 END)) `retn`
   FROM
     (
      SELECT DISTINCT
        `a`.`tran_date`
      , `a`.`subsidiary`
      , `a`.`customer_id`
      , `a`.`transaction_id`
      , `a`.`tran_type`
      , `a`.`sale_country`
      , `is_target`
      , COALESCE(`custbody_hp_counter`, 1) `custbody_hp_counter`
      FROM
        `dws_oversea_order_v2_detail` `a`
   )  `a`
   GROUP BY 1, 2, 3, `a`.`sale_country`, 5
) 
SELECT
  `t1`.`tran_date`
, `t1`.`subsidiary`
, `t1`.`subsidiary_name`
, `t1`.`subsidiary_country`
, `t1`.`subsidiary_continent`
, `t1`.`customer_id`
, `t1`.`customer_code`
, `t1`.`customer_name`
, `t1`.`customer_city`
, `t1`.`customer_country`
, `t1`.`customer_continent`
, `t1`.`customer_category`
, `t1`.`customer_2nd_cat_name`
, `t1`.`customer_3nd_cat_name`
, `t1`.`sale_country`
, `t1`.`sale_continent`
, `t1`.`managment_performance`
, `t1`.`managment_performance_rmb`
, `t2`.`sale` `trade_count`
, `t1`.`product_count`
, `t1`.`is_target`
FROM
  (`t1`
LEFT JOIN `t2` ON (((((`t1`.`tran_date` = `t2`.`tran_date`) AND (`t1`.`subsidiary` = `t2`.`subsidiary`)) AND (`t1`.`customer_id` = `t2`.`customer_id`)) AND (`t1`.`sale_country` = `t2`.`sale_country`)) AND (`t1`.`is_target` = `t2`.`is_target`)))
