-- --------------------------------------------- 
-- Subject:WMS_api_商品信息(富勒-出库) 
-- Author: 郭婧 
-- Create: 2025-06-10 
-- Update: 更新时间  姓名  更改内容
 -- ---------------------------------------------
-- create table dw.t_api_wms_css_fl_goods_outb
-- (
--     id	            varchar	   COMMENT'发运订单编码',	
--     lineNo	        bigint	    COMMENT'行号',	
-- 	order_no	 	 varchar	COMMENT'订单号',
-- 	document_type	 varchar	COMMENT'单据类型',
-- 	express_no	 	 varchar	COMMENT'快递单号',
-- 	goods_code	 	 varchar	COMMENT'货品编码',
-- 	goods_barcode	 varchar	COMMENT'商品条码',
-- 	goods_name	 	 varchar	COMMENT'商品名称',
-- 	goods_qty	 	 bigint 	COMMENT'商品数量',
-- 	unit	 		 varchar	COMMENT'单位',
-- 	unit_spec	 	 varchar 	COMMENT'单位规格',
-- 	unit_qty	 	 varchar 	COMMENT'单位数量',
-- 	unit_spec_ratio	 varchar 	COMMENT'单位规格比例',
-- 	unit_qty_ratio	 varchar 	COMMENT'单位数量比例',
-- 	inv_status	     varchar	COMMENT'库存状态',
-- 	exc_reason	     varchar	COMMENT'异常原因',
--     weight           double     COMMENT'理论重量（kg）' ,
--    ord_tail_status varchar	COMMENT'订单尾状态',
-- 	wms_sys	         varchar	COMMENT'WMS系统(FL、TTX)',
-- 	order_status	 varchar	COMMENT'订单状态(出库、入库)',
--     etl_time   TIMESTAMP	 COMMENT '插入日期',
-- 	hando_time	varchar	comment'交接时间',
-- express_com varchar	comment'快递公司',
--     primary key (id,lineNo)
-- )comment'wms_api_商品信息(富勒-出库)';
REPLACE INTO  dw.t_api_wms_css_fl_goods_outb
SELECT
    th.id ,
    td.orderlineno ,
    th.order_no    	    	as order_no, 		-- 订单号
	t_type.document_type  	as document_type, 	-- 单据类型
	th.express_no  		    as express_no, 		-- 快递单号
	td.goods_code  			as goods_code, 		-- 货品编码
	'' 					    as goods_barcode,	-- 商品条码
	td.goods_name 			as goods_name, 		-- 商品名称
	td.goods_qty    		AS goods_qty, 		-- 商品数量
	'' 					    as unit,	 		-- 单位
	'' 					    as unit_spec,	 	-- 单位规格
	'' 					    as unit_qty,	 	-- 单位数量
	'' 					    as unit_spec_ratio,	-- 单位规格比例
	'' 					    as unit_qty_ratio,	-- 单位数量比例
	''  					as inv_status,	 	-- 库存状态
	'' 	                    as exc_reason, 		-- 异常原因
	ROUND(td.goods_qty*t_sku.weight,2) as weight ,          -- 理论重量（kg） 
	t_status.ord_tail_status as ord_tail_status,  -- 订单尾状态
	'FL'					as wms_sys	,		-- WMS系统(FL、TTX)
    '出库'				    as order_type ,
     SYSDATE() AS etl_time ,-- 插入日期
	 addtime as  hando_time, -- 交接时间
	 th.express_com
FROM 
( -- 发运订单
	SELECT 
		orderno 	 as id ,
		ordertype  	 as order_type,
		soreference1 as order_no,
		deliveryno   as express_no , -- 快递单号
		soStatus,
		carriername as express_com,
		addtime
	FROM fule.doc_order_header
	WHERE organizationid='POP'
		AND warehouseid='DGBP'
		AND carriername not like '%虚拟%'
)th 
JOIN 
( -- 发运单明细
	SELECT 
	    sku     as goods_code, 		-- 货品编码 
	    dedi05  as goods_name, 		-- 商品名称 
	    customerId,
	    orderno,
	    orderlineno ,
        cast(qtyshipped_each as bigint) as goods_qty -- 商品数量
	FROM fule.doc_order_details
	WHERE organizationid='POP'
		AND warehouseid='DGBP'
)td
ON  th.id=td.orderno
LEFT JOIN 
(
  SELECT 
		sku, customerId,
		(grossWeight) AS weight  -- 重量 
  FROM fule.bas_sku
  WHERE organizationId='POP'
) t_sku 
ON td.customerId=t_sku.customerId
	AND td.goods_code=t_sku.sku
JOIN 
( -- 单据类型
  SELECT codeId,
		codedescr as document_type 	-- 单据类型
  FROM fule.bsm_code_ml
  WHERE  codeType='SO_TYP'-- ASN_TYP入库/'SO_TYP' -- 出库
	and languageId='zh_CN'
) t_type 
ON t_type.codeId=th.order_type
JOIN 
( -- 状态
  SELECT codeId,codedescr as ord_tail_status
  FROM fule.bsm_code_ml
  WHERE codeType='SO_STS'-- 出库/'ASN_STS' -- 入库
	AND languageId='zh_CN'
 	AND codedescr NOT LIKE '%取消%'
)  t_status  
ON t_status.codeId=th.soStatus
;

-- 删除取消订单数据
DELETE FROM dw.t_api_wms_css_fl_goods_outb 
WHERE id IN  (SELECT orderno
	FROM  fule.doc_order_header
	WHERE organizationid='POP'
		AND warehouseid='DGBP'
		AND carriername not like '%虚拟%'
		and soStatus=90) ;