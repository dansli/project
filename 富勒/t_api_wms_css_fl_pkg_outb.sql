-- --------------------------------------------- 
-- Subject:WMS_api_包裹信息(富勒-出库)
-- Author: 郭婧 
-- Create: 2025-06-10 
-- Update: 更新时间  姓名  更改内容
 -- ---------------------------------------------
-- create table dw.t_api_wms_css_fl_pkg_outb
-- (
--     id	         varchar	   COMMENT'发运订单编码',
--     order_no varchar	comment'订单号',
--     document_type varchar	comment'单据类型',
--     express_no varchar	comment'快递单号',
--     express_com varchar	comment'快递公司',
--     total_qty	bigint	comment'数量',
--     theo_weight varchar 	comment'理论重量（kg）',
--     act_weight varchar 	comment'实际重量（kg）',
--     video_file_name varchar	comment'视频',
--     hando_time	varchar	comment'交接时间',
--     receipt_time varchar	comment'收货时间',
--     ord_tail_status varchar	comment'订单尾状态',
--     exc_reason varchar	comment'异常原因',
--     wms_sys varchar	comment'WMS系统(FU、TTX)',
--     order_status varchar	comment'订单状态(出库、入库)',
--     etl_time   TIMESTAMP	 COMMENT '插入日期',
--     primary key (id)
-- )comment'wms_api_包裹信息(富勒-出库)';

REPLACE INTO  dw.t_api_wms_css_fl_pkg_outb
select  
    t1.id,
	t1.order_no    				as order_no ,	    -- 上游单号
	t1.document_type 			as document_type ,  -- 单据类型
	t1.express_no  				as express_no, 	    -- 物流单号
	t1.express_com 	     					as express_com	,    -- 快递公司
	SUM(t1.goods_qty)		 	 	as total_qty,	    -- 数量
	SUM(t1.weight)      as theo_weight,	    -- 理论重量（kg）
	'' 		 		    		as act_weight,	    -- 实际重量（kg）
	t_v.video_file_name 		as video_file_name ,-- 视频文件名    
	t1.hando_time 				as hando_time, -- 交接时间 
	'' 							as receipt_time,	-- 收货时间	
	t1.ord_tail_status 		as ord_tail_status ,-- 订单状态
	''		 					as exc_reason,	 -- 异常原因
	'FL' 		 			 	as wms_sys	 ,	    -- WMS系统(FL、TTX)
	'出库'				 		as order_type ,
	SYSDATE() AS etl_time -- 插入日期
FROM dw.t_api_wms_css_fl_goods_outb t1
LEFT JOIN 
 ( -- 视频信息
	 SELECT
		orderNO,
		GROUP_CONCAT(concat(originalFileName,'.mp4')) as video_file_name
		-- GROUP_CONCAT(concat('https://images-wms-oss-online-prd1.oss-cn-beijing.aliyuncs.com/FLUX/',originalFileName,'.mp4')) as video_file_name
	FROM
		fule.bsm_attachment
	WHERE
		organizationid = 'POP'
		AND warehouseid = 'DGBP'
	 GROUP BY orderNO
 )t_v
 ON t_v.orderNO=t1.express_no
 GROUP BY 
		t1.id,
		t1.order_no ,
		t1.document_type ,
		t1.express_no,
		t_v.video_file_name,
		t1.ord_tail_status ,
		t1.hando_time,t1.express_com
 ;
	
-- 删除取消订单数据
DELETE FROM dw.t_api_wms_css_fl_pkg_outb 
WHERE id IN  (SELECT orderno
	FROM  fule.doc_order_header
	WHERE organizationid='POP'
		AND warehouseid='DGBP'
		AND carriername not like '%虚拟%'
		and soStatus=90) ;