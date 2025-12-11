-- --------------------------------------------- 
-- Subject:NS-财务域-NS客户预算
-- Author: 郭婧 
-- Create: 2025-06-17
-- Update: 更新时间  姓名  更改内容
-- 以每一个销售单、每一个商品、每个科目为最小颗粒度进行
 -- ---------------------------------------------
-- CREATE TABLE dw.dwd_ns_fin_budget
-- (
-- 	 id					bigint	COMMENT'ID'
-- 	,cus_2nd_cat_id 	bigint	COMMENT'预算客户二级分类名称'
-- 	,cus_2nd_cat_name	varchar	COMMENT'预算客户二级分类id'
-- 	,cus_id				bigint	COMMENT'客户id'
-- 	,cus_name			varchar	COMMENT'客户名称'
-- 	,sub_id				bigint	COMMENT'主体id'
-- 	,sub_name			varchar	COMMENT'主体名称'
-- 	,cur_id				bigint	COMMENT'货币id'
-- 	,cur_name			varchar	COMMENT'货币名称'
-- 	,ord_type_id		bigint	COMMENT'单据类型id'
-- 	,ord_type_name		varchar	COMMENT'单据类型名称'
-- 	,bgt_amt 			double	COMMENT'人民币预算'
-- 	,exchange_rate		double	COMMENT'汇率'
-- 	,local_amt 			double	COMMENT'外币预算'
-- 	,bgt_date 			varchar	COMMENT'日期(yyyy-mm-dd)'
-- 	,PRIMARY KEY (id)
-- )COMMENT'NS客户预算';

TRUNCATE TABLE dw.dwd_ns_fin_budget;
INSERT INTO dw.dwd_ns_fin_budget
 SELECT
	 t_bgt.id					-- ID
	,t_bgt.cus_2nd_cat_id 		-- 二级分类ID
	,t_cat2.cus_2nd_cat_name 	-- 二级分类名称
	,t_bgt.cus_id 				-- 客户ID
	,t_cus.cus_name 			-- 客户名称
	,t_bgt.sub_id 				-- 主体ID
	,t_sub.sub_name 			-- 主体名称
	,t_bgt.cur_id 				-- 货币ID
	,t_cur.cur_name 			-- 货币名称
	,t_bgt.ord_type_id 			-- 订单类型ID
	,t_ord.ord_type_name 		-- 订单类型名称
	,t_bgt.bgt_amt 				-- 人民币预算
	,t_bgt.exchange_rate 		-- 汇率
	,t_bgt.local_amt 			-- 外币预算 
	,t_bgt.bgt_date 			-- 预算日期
FROM 
(
	SELECT 
	    id
	   ,custrecord_bi_budget_2nd_class 			AS cus_2nd_cat_id 	-- 二级分类ID
	   ,custrecord_bi_budget_month 				AS bgt_date 		-- 预算日期
	   ,custrecord_bi_budget_amount 			AS bgt_amt 			-- 预算金额
	   ,custrecord_bi_budget_exchangerate 		AS exchange_rate 	-- 税率
	   ,custrecord_bi_budget_amtlocalcurreny	AS local_amt 		-- 当地货币金额 
	   ,custrecord_bi_budget_customer 			AS cus_id 			-- 客户id
	   ,custrecord_bi_budget_subsidiary 		AS sub_id 			-- 主体id
	   ,custrecord_bi_budget_currency 			AS cur_id 			-- 货币ID
	   ,custrecord_bi_budget_order_type 		AS ord_type_id 		-- 订单类型
	FROM ns.customrecord_pm_bi_budget
	WHERE isinactive = 'F'
)t_bgt -- 预算表
LEFT JOIN 
(-- 二级分类
	SELECT id,name AS cus_2nd_cat_name
	FROM ns.customlist_pm_customer_2nd_cat 
)t_cat2 
	ON t_bgt.cus_2nd_cat_id = t_cat2.id
LEFT JOIN
( -- 客户信息
	SELECT id,altname AS cus_name
	FROM ns.customer 
)t_cus 
	ON t_bgt.cus_id = t_cus.id
LEFT JOIN
( -- 国家
	SELECT id,fullname AS sub_name
	FROM ns.subsidiary
)t_sub 
	ON t_bgt.sub_id = t_sub.id
LEFT JOIN
(
	SELECT id,name AS cur_name
	FROM ns.currency
)t_cur 
	ON t_bgt.cur_id = t_cur.id
LEFT JOIN 
( -- 订单类型名称
	SELECT id,name AS ord_type_name
	FROM ns.customlist763
)t_ord
   ON t_bgt.ord_type_id = t_ord.id
;

