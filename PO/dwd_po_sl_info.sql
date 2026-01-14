
-- 单据类型为SKU

select 
	po_sl.po_code, -- PO单号
	sl.sl_code, -- 发货单号
	sl.supplier_id, -- 供应商ID
	CASE WHEN LENGTH(sup.abbr_name) >1 THEN sup.abbr_name ELSE sup.name END AS supplier_name, -- 供应商名称
	sl.purchase_subject_id, -- 采购主体ID
	sl.batch_number, -- 出货批次
	sl.shipping_time, -- 出货时间
	sl.order_type, -- 单据类型：SPU-系列；SKU-商品
	sl.order_status, -- 发货单状态
	sl.production_mode as production_mode_en, -- 生产类型
	DECODE(sl.production_mode,'FINISHED_PRODUCT','成品','COMPONENT','部件','ASSEMBLY_FEE','组装',sl.production_mode) as production_mode_cn, -- 生产类型名称
	sl.order_total_quantity_of_set, -- 发货总套数
	sl.new_order_flag, -- 	新增单据提醒标识：0-未提醒；1-已提醒
	decode(sl.new_order_flag,'0','未提醒','1','已提醒',new_order_flag) as new_order_flag_name,
	sl.creator_id, -- 创建人ID
	sl.creator_name, -- 创建人名称
	sl.last_updater_id, -- 更新人ID
	sl.last_updater_name, -- 更新人名称
	sl.create_time, -- 创建时间
	sl.update_time, -- 更新时间
	sl_sku.related_spu_uuid, -- 关联SPU UUID
	sl_sku.spu_code, -- 系列编码
	sl_sku.major_spu_code, -- 	主系列编码
	sl_sku.sku_hd_code as sku_code, -- 商品编码
	sl_sku.type as type_code, -- 	商品类型：BULK-大货；FREE_SPARE-免费备品；PAY_SPARE-付费备品；DISPLAY-陈列；RETAINED-留货
	decode(sl_sku.type,'BULK','大货','FREE_SPARE','免费备品','PAY_SPARE','付费备品','DISPLAY','陈列','RETAINED','留货',sl_sku.type) as type_name, -- 商品类型名称
	sl_sku.channel_code, -- 销售渠道编码
	sl_sku.default_receive_area_source, -- 默认收货区域来源：HD_H6-[海鼎-H6]；ORACLE_NS-[Oracle-NS]；BS_E3_PLUS-[百胜-E3+]
	sl_sku.default_receive_area_type, -- 	默认收货区域类型：STORE-门店；WAREHOUSE-仓位
	sl_sku.default_receive_area_code, -- 默认收货区域编码
	sl_sku.transit_receive_area_source, -- 内部交易中转收货区域来源：HD_H6-[海鼎-H6]；ORACLE_NS-[Oracle-NS]；BS_E3_PLUS-[百胜-E3+]
	sl_sku.transit_receive_area_type, -- 内部交易中转收货区域类型：STORE-门店；WAREHOUSE-仓位
	sl_sku.transit_receive_area_code, -- 内部交易中转收货区域代码
	sl_sku.quantity, -- 出货数量
	-- sl_sku.purchase_price, -- 	含税采购单价
	-- sl_sku.currency_code, -- 币种代码
	-- sl_sku.unit, -- 单位
	-- sl_sku.spec, -- 规格
	-- sl_sku.tax_rate, -- 税率
	-- sl_sku.hidden_probability_code, -- 隐藏概率编码
	-- sl_sku.box_spec, -- 盒规
	sl_sku.quantity/sl_sku.box_spec as box_quantity -- 出货套数
from po.shipping_list_info as sl
inner join po.shipping_list_sku_info as sl_sku
on sl.sl_code = sl_sku.sl_code 
-- and sl.order_type='SKU'
left join po.base_supplier_info sup -- PO单供应商信息
ON sl.supplier_id=sup.id AND sup.data_status=1  
left join po.purchase_order_related_shipping_list_info as po_sl
on sl.sl_code=po_sl.sl_code and po_sl.data_status=1 
left join po.base_sku_info as code -- 商品信息
on sl_sku.sku_hd_code=code.sku_hd_code 
-- and sl.order_type=po_sl.type and sl.sku_hd_code=po_sl.supplier_id
where sl.data_status=1 and sl.order_status !='CANCELED' and sl.order_type='SKU'

union all  

select 
	po_sl.po_code, -- PO单号
	sl.sl_code, -- 发货单号
	sl.supplier_id, -- 供应商ID
	CASE WHEN LENGTH(sup.abbr_name) >1 THEN sup.abbr_name ELSE sup.name END AS supplier_name, -- 供应商名称
	sl.purchase_subject_id, -- 采购主体ID
	sl.batch_number, -- 出货批次
	sl.shipping_time, -- 出货时间
	sl.order_type, -- 单据类型：SPU-系列；SKU-商品
	sl.order_status, -- 发货单状态
	sl.production_mode as production_mode_en, -- 生产类型
	DECODE(sl.production_mode,'FINISHED_PRODUCT','成品','COMPONENT','部件','ASSEMBLY_FEE','组装',sl.production_mode) as production_mode_cn, -- 生产类型名称
	sl.order_total_quantity_of_set, -- 发货总套数
	sl.new_order_flag, -- 	新增单据提醒标识：0-未提醒；1-已提醒
	decode(sl.new_order_flag,'0','未提醒','1','已提醒',new_order_flag) as new_order_flag_name,
	sl.creator_id, -- 创建人ID
	sl.creator_name, -- 创建人名称
	sl.last_updater_id, -- 更新人ID
	sl.last_updater_name, -- 更新人名称
	sl.create_time, -- 创建时间
	sl.update_time, -- 更新时间
	sl_spu.uuid as related_spu_uuid, -- 关联SPU UUID
	sl_spu.spu_code, -- 系列编码
	code.major_spu_code, -- 主系列编码
	null as sku_code, -- 商品编码
	sl_spu.type as type_code, -- 	商品类型：BULK-大货；FREE_SPARE-免费备品；PAY_SPARE-付费备品；DISPLAY-陈列；RETAINED-留货
	decode(sl_spu.type,'BULK','大货','FREE_SPARE','免费备品','PAY_SPARE','付费备品','DISPLAY','陈列','RETAINED','留货',sl_spu.type) as type_name, -- 商品类型名称
	sl_spu.channel_code, -- 销售渠道编码
	sl_spu.default_receive_area_source, -- 默认收货区域来源：HD_H6-[海鼎-H6]；ORACLE_NS-[Oracle-NS]；BS_E3_PLUS-[百胜-E3+]
	sl_spu.default_receive_area_type, -- 	默认收货区域类型：STORE-门店；WAREHOUSE-仓位
	sl_spu.default_receive_area_code, -- 默认收货区域编码
	sl_spu.transit_receive_area_source, -- 内部交易中转收货区域来源：HD_H6-[海鼎-H6]；ORACLE_NS-[Oracle-NS]；BS_E3_PLUS-[百胜-E3+]
	sl_spu.transit_receive_area_type, -- 内部交易中转收货区域类型：STORE-门店；WAREHOUSE-仓位
	sl_spu.transit_receive_area_code, -- 内部交易中转收货区域代码
	sl_spu.quantity, -- 出货数量
	-- sl_spu.purchase_price, -- 	含税采购单价
	-- sl_spu.currency_code, -- 币种代码
	-- sl_spu.unit, -- 单位
	-- sl_spu.spec, -- 规格
	-- sl_spu.tax_rate, -- 税率
	-- sl_spu.hidden_probability_code, -- 隐藏概率编码
	-- sl_spu.box_spec, -- 盒规
	sl_spu.quantity as box_quantity -- 出货套数
from po.shipping_list_info as sl
inner join po.shipping_list_spu_info as sl_spu
on sl.sl_code = sl_spu.sl_code 
-- and sl.order_type='SKU'
left join po.base_supplier_info sup -- PO单供应商信息
ON sl.supplier_id=sup.id AND sup.data_status=1  
left join po.purchase_order_related_shipping_list_info as po_sl
on sl.sl_code=po_sl.sl_code and po_sl.data_status=1 
left join po.base_spu_info as code -- 商品信息
on sl_spu.spu_code=code.spu_code 
-- and sl.order_type=po_sl.type and sl.sku_hd_code=po_sl.supplier_id
where sl.data_status=1 and sl.order_status !='CANCELED' and sl.order_type='SPU'




CREATE TABLE dw.dwd_po_sl_info (
    po_code                         VARCHAR COMMENT 'PO单号',
    sl_code                         VARCHAR COMMENT '发货单号',
    supplier_id                     BIGINT  COMMENT '供应商ID',
    supplier_name                   VARCHAR COMMENT '供应商名称',
    purchase_subject_id             BIGINT  COMMENT '采购主体ID',
    batch_number                    VARCHAR COMMENT '出货批次',
    shipping_time                   DATETIME COMMENT '出货时间',
    order_type                      VARCHAR COMMENT '单据类型：SPU / SKU',
    order_status                    VARCHAR COMMENT '发货单状态',
    production_mode_en              VARCHAR COMMENT '生产类型英文',
    production_mode_cn              VARCHAR COMMENT '生产类型中文',
    order_total_quantity_of_set     DOUBLE COMMENT '发货总套数',
    new_order_flag                  BIGINT      COMMENT '新增单据提醒标识：0-未提醒；1-已提醒',
    new_order_flag_name             VARCHAR  COMMENT '新增单据提醒标识名称',
    creator_id                      BIGINT       COMMENT '创建人ID',
    creator_name                    VARCHAR  COMMENT '创建人名称',
    last_updater_id                 BIGINT   COMMENT '更新人ID',
    last_updater_name               VARCHAR  COMMENT '更新人名称',
    create_time                     DATETIME     COMMENT '创建时间',
    update_time                     DATETIME     COMMENT '更新时间',
    related_spu_uuid                VARCHAR  COMMENT '关联SPU UUID',
    spu_code                        VARCHAR  COMMENT '系列编码',
    major_spu_code                  VARCHAR  COMMENT '主系列编码',
    sku_code                        VARCHAR  COMMENT '商品编码（SKU维度有值）',
    type_code                       VARCHAR  COMMENT '商品类型编码',
    type_name                       VARCHAR  COMMENT '商品类型名称',
    channel_code                    VARCHAR  COMMENT '销售渠道编码',
    default_receive_area_source     VARCHAR  COMMENT '默认收货区域来源',
    default_receive_area_type       VARCHAR  COMMENT '默认收货区域类型',
    default_receive_area_code       VARCHAR  COMMENT '默认收货区域编码',
    transit_receive_area_source     VARCHAR  COMMENT '中转收货区域来源',
    transit_receive_area_type       VARCHAR  COMMENT '中转收货区域类型',
    transit_receive_area_code       VARCHAR  COMMENT '中转收货区域编码',
    quantity                        DOUBLE COMMENT '出货数量',
    box_quantity                    DOUBLE COMMENT '出货套数',
	PRIMARY KEY (sl_code, sku_code,spu_code,production_mode_en,type_code,channel_code)

)
COMMENT='PO出货单明细'



-- inv这个表需要拆到channle或者是仓 
-- LEFT JOIN 
-- (select 
-- 	i.related_code,
-- 	max(i.real_delivery_time) as real_delivery_time,
-- 	max(ii.create_time) as inv_create_time
-- from po.invoice_info as i 
-- left join po.invoice_receive_detail as ii 
-- on i.in_code=ii.in_code 
-- where i.related_type='SL'
-- group by 
-- 	i.related_code) as inv

--  找sl 连sl的仓和channel


 -- --------------------------------------------- 
-- Subject:PO最新货期
-- Author: 王思卓 
-- Create: 2025-09-08 
-- Update: 更新时间  姓名  更改内容
 -- ---------------------------------------------


-- create table dw.dws_po_delivery_schedule(
--     pr_num              VARCHAR  COMMENT 'PR序号',
--     supplier_name       VARCHAR  COMMENT '供应商',
--     purchaser_name      VARCHAR  COMMENT '采购员',
--     creator_name        VARCHAR  COMMENT '计划负责人',
-- 	   order_type		 VARCHAR  COMMENT '单据类型：SPU / SKU',
--     major_spu_code      VARCHAR COMMENT '主系列编码',
--     spu_code            VARCHAR COMMENT '系列编码',
-- 	   sku_code            VARCHAR  COMMENT '商品编码',
--     pr_code             VARCHAR  COMMENT 'PR单',
-- 	   po_code             VARCHAR  COMMENT 'PO单',
--     production_mode_en  VARCHAR  COMMENT '生产类型英文',
--     production_mode_cn  VARCHAR  COMMENT '生产类型中文',
-- 	   channel_code		VARCHAR  COMMENT '销售渠道编码',
-- 	   default_receive_area_code VARCHAR  COMMENT '默认收货区域编码',
--     type_code        VARCHAR  COMMENT '商品类型编码',
-- 	   type_name 	  VARCHAR  COMMENT '商品类型名称',
--     pr_create_time      DATETIME      COMMENT 'PR创建日期',
--     po_confirm_time     DATETIME      COMMENT 'PO确认时间',
--     demand_time         DATETIME      COMMENT '需求到货时间',
--     promised_shipping_time     DATETIME      COMMENT '供应商承诺发货时间',
--     sl_shipping_time     DATETIME      COMMENT '出货清单发货时间',
--     real_delivery_time  DATETIME      COMMENT '发货单实际发货时间',
--     inv_create_time     DATETIME      COMMENT '收货时间',
--     batch_number        VARCHAR   COMMENT '批次',
--     req_cnt             DOUBLE           COMMENT '数量个',
--     req_cnt_box         DOUBLE           COMMENT '数量套',
--     PRIMARY KEY (po_code,spu_code,sku_code,production_mode_en,type_code,channel_code,
-- default_receive_area_code,batch_number) 
-- ) COMMENT='货期总表-出货清单维度';

TRUNCATE TABLE dw.dws_po_delivery_schedule;
insert into dw.dws_po_delivery_schedule
select 
	pr.pr_num,
	sl.supplier_name,
	po.purchaser_name,
	pr.creator_name, -- 计划负责人
	sl.order_type,
	sl.major_spu_code,
	sl.spu_code,
	sl.sku_code,
	pr.pr_code,
	sl.po_code,
    sl.sl_code,
	sl.production_mode_en,
	sl.production_mode_cn,
	sl.channel_code,
    sl.default_receive_area_code,
	sl.type_code,
	sl.type_name,
    pr.batch_number,-- 出货批次
	max(pr.create_time) as pr_create_time, -- PR创建时间
	max(log.confirm_time) as po_confirm_time, -- PO确认时间
	max(pr_plan.demand_time) as demand_time,-- 需求到货时间
	max(nvl(plan.shipping_time,t_plan.shipping_time)) as promised_shipping_time,-- 供应商承诺发货时间
	max(sl.shipping_time) as sl_shipping_time, -- 出货清单发货时间
	max(inv.real_delivery_time) as real_delivery_time,-- 发货单实际发货时间
	max(inv.inv_create_time) as inv_create_time,-- 收货时间
	sum(sl.quantity) as req_cnt,
	sum(sl.box_quantity) as req_cnt_box
from dw.dwd_po_sl_info as sl 
left join (select 
	pr_code,
	pr_num,
	po_code,
	sku_code,
	type_code,
	channel_code,
    creator_name,
	max(batch_number) as batch_number,
    max(demand_time) as demand_time,
    max(create_time) as create_time
from dw.dwd_pr_info
group by 
	pr_code,
	pr_num,
	po_code,
	sku_code,
	type_code,
	channel_code
) as pr  
on sl.po_code=pr.po_code 
and sl.sku_code=pr.sku_code
and sl.channel_code=pr.channel_code
left join 
(select 
pr_code,
sku_hd_code, 
max(demand_time) as demand_time
from po.purchase_requirement_demand_plan_info
group by 
pr_code,
sku_hd_code) as pr_plan 
on pr_plan.sku_hd_code=pr.sku_code and pr_plan.pr_code=pr.pr_code
left join 
(select 
    purchaser_name,
    po_code,
    sku_code,
    type_code
from dw.dwd_po_detail
group by 
  purchaser_name,
  po_code,
  sku_code,
  type_code) as po 
on po.po_code=sl.po_code 
and po.sku_code=sl.sku_code
and po.type_code=sl.type_code
left join 
(select 
	business_code,
	min(create_time) as confirm_time
from po.operation_log 
where operate_type='CONFIRM' 
and business_type='PURCHASE_ORDER'
group by 
    business_code) as log 
on log.business_code=sl.po_code
left join po.purchase_order_delivery_plan_info as plan
on plan.po_code=sl.po_code 
and plan.sku_hd_code=sl.sku_code
and plan.type=sl.type_code and plan.type !='SPARE'
and plan.data_status=1 
left join po.purchase_order_delivery_plan_info as t_plan
on t_plan.po_code=sl.po_code 
and t_plan.sku_hd_code=sl.sku_code 
and t_plan.type ='SPARE'
and t_plan.data_status=1 
LEFT JOIN 
(select 
	i.related_code,
	iii.default_receive_area_code,
	max(i.real_delivery_time) as real_delivery_time,
	max(ii.create_time) as inv_create_time
from po.invoice_info as i 
left join po.invoice_receive_detail as ii 
on i.in_code=ii.in_code 
left join dw.dwd_po_sl_info as iii 
on iii.sl_code=i.related_code
where i.related_type='SL'
group by 
	i.related_code,
	iii.default_receive_area_code) as inv
ON inv.related_code=sl.sl_code
and inv.default_receive_area_code=sl.default_receive_area_code
where sl.order_type='SKU'
-- and sl.sl_code='SL10945461020114944'
--   and sl.po_code='PO10683301249654784'
group by 
	pr.pr_num,
	sl.supplier_name,
	po.purchaser_name,
	pr.creator_name, -- 计划负责人
	sl.order_type,
	sl.major_spu_code,
	sl.spu_code,
	sl.sku_code,
	pr.pr_code,
	sl.po_code,
    sl.sl_code,
	sl.production_mode_en,
	sl.production_mode_cn,
	sl.channel_code,
    sl.default_receive_area_code,
	sl.type_code,
	sl.type_name,
    pr.batch_number

union all  

select 
	pr.pr_num,
	sl.supplier_name,
	po.purchaser_name,
	pr.creator_name, -- 计划负责人
	sl.order_type,
	sl.major_spu_code,
	sl.spu_code,
	sl.sku_code,
	pr.pr_code,
	sl.po_code,
    sl.sl_code,
	sl.production_mode_en,
	sl.production_mode_cn,
	sl.channel_code,
    sl.default_receive_area_code,
	sl.type_code,
	sl.type_name,
    pr.batch_number,-- 出货批次
	max(pr.create_time) as pr_create_time, -- PR创建时间
	max(log.confirm_time) as po_confirm_time, -- PO确认时间
	max(pr_plan.demand_time) as demand_time,-- 需求到货时间
	max(nvl(plan.shipping_time,t_plan.shipping_time)) as promised_shipping_time,-- 供应商承诺发货时间
	max(sl.shipping_time) as sl_shipping_time, -- 出货清单发货时间
	max(inv.real_delivery_time) as real_delivery_time,-- 发货单实际发货时间
	max(inv.inv_create_time) as inv_create_time,-- 收货时间
	sum(sl.quantity) as req_cnt,
	sum(sl.box_quantity) as req_cnt_box
from dw.dwd_po_sl_info as sl 
left join (select 
	pr_code,
	pr_num,
	po_code,
	spu_code,
	type_code,
	channel_code,
    creator_name,
	max(batch_number) as batch_number,
    -- max(demand_time) as demand_time,
    max(create_time) as create_time
from dw.dwd_pr_info
group by 
	pr_code,
	pr_num,
	po_code,
	spu_code,
	type_code,
	channel_code
) as pr 
on sl.po_code=pr.po_code 
and sl.spu_code=pr.spu_code
and sl.channel_code=pr.channel_code
left join 
(select 
pr_code,
spu_code, 
max(demand_time) as demand_time
from po.purchase_requirement_demand_plan_info
group by 
pr_code,
spu_code) as pr_plan 
on pr_plan.spu_code=pr.spu_code and pr_plan.pr_code=pr.pr_code
left join 
(select 
    purchaser_name,
    po_code,
    spu_code,
    type_code
from dw.dwd_po_detail
group by 
  purchaser_name,
  po_code,
  spu_code,
  type_code) as po 
on po.po_code=sl.po_code 
and po.spu_code=sl.spu_code
and po.type_code=sl.type_code
left join 
(select 
	business_code,
	min(create_time) as confirm_time
from po.operation_log 
where operate_type='CONFIRM' 
and business_type='PURCHASE_ORDER'
group by 
    business_code) as log 
on log.business_code=sl.po_code
left join po.purchase_order_delivery_plan_info as plan
on plan.po_code=sl.po_code 
and plan.spu_code=sl.spu_code
and plan.type=sl.type_code and plan.type !='SPARE'
and plan.data_status=1 
left join po.purchase_order_delivery_plan_info as t_plan
on t_plan.po_code=sl.po_code 
and t_plan.spu_code=sl.spu_code 
and t_plan.type ='SPARE'
and t_plan.data_status=1 
LEFT JOIN 
(select 
	i.related_code,
	iii.default_receive_area_code,
	max(i.real_delivery_time) as real_delivery_time,
	max(ii.create_time) as inv_create_time
from po.invoice_info as i 
left join po.invoice_receive_detail as ii 
on i.in_code=ii.in_code 
left join dw.dwd_po_sl_info as iii 
on iii.sl_code=i.related_code
where i.related_type='SL'
group by 
	i.related_code,
	iii.default_receive_area_code) as inv
ON inv.related_code=sl.sl_code
and inv.default_receive_area_code=sl.default_receive_area_code
where sl.order_type='SPU'
--   and sl.sl_code='SL10945461020114944'
  -- and sl.channel_code='CH125'
group by 
	pr.pr_num,
	sl.supplier_name,
	po.purchaser_name,
	pr.creator_name, -- 计划负责人
	sl.order_type,
	sl.major_spu_code,
	sl.spu_code,
	sl.sku_code,
	pr.pr_code,
	sl.po_code,
    sl.sl_code,
	sl.production_mode_en,
	sl.production_mode_cn,
	sl.channel_code,
    sl.default_receive_area_code,
	sl.type_code,
	sl.type_name, 
    pr.batch_number


SELECT 
	pr_num,           
	supplier_name,   
	purchaser_name,   
	creator_name,     
	order_type,		 
	major_spu_code,   
	spu_code,         
	sku_code,        
	pr_code,          
	po_code,          
	sl_code,          
	production_mode_en, 
	production_mode_cn,  
	channel_code,
	channel.name as channel_name,		
	default_receive_area_code,
	type_code,        
	type_name, 	  
	batch_number,        
	pr_create_time,      
	po_confirm_time,     
	demand_time,         
	promised_shipping_time,
	CASE
		WHEN real_delivery_time IS NOT NULL THEN real_delivery_time -- 优先取实际发货时间
		ELSE CASE -- 没有实际发货时间，取 3 个计划时间的最大值
		WHEN GREATEST(
				COALESCE(demand_time, '1900-01-01'),
				COALESCE(promised_shipping_time, '1900-01-01'),
				COALESCE(sl_shipping_time, '1900-01-01')
			) < CURRENT_DATE() -- 如果最大时间小于今天，自动用今天
			THEN CURRENT_DATE()
		ELSE GREATEST(
				COALESCE(demand_time, '1900-01-01'),
				COALESCE(promised_shipping_time, '1900-01-01'),
				COALESCE(sl_shipping_time, '1900-01-01')
			)
		END
	END AS latest_delivery_date,
	sl_shipping_time,     
	real_delivery_time,  
	inv_create_time,     
	req_cnt,             
	req_cnt_box        
FROM dw.dws_po_delivery_schedule as sl
left join po.base_channel_info as channel
on sl.channel_code=channel.code




LEFT JOIN cnt
 ON base.pr_code = cnt.pr_code
 AND base.spu_code = cnt.spu_code
 AND base.major_spu_code = cnt.major_spu_code
 AND base.channel_code = cnt.channel_code
--  and base.box_spec = cnt.box_spec
AND base.type_code = cnt.type_code
-- and base.batch_number = cnt.batch_number
LEFT JOIN po 
  ON base.pr_code = po.pr_code
  AND base.spu_code = po.spu_code
  AND base.major_spu_code = po.major_spu_code
  AND base.channel_code = po.channel_code
  AND base.type_code=po.type_code
LEFT JOIN po.order_serial_no_info AS SERIAL
  ON base.pr_code = SERIAL.order_code
  AND base.spu_code=SERIAL.spu_code
  AND order_category='PR'
LEFT JOIN po.base_spu_info AS spu
ON base.spu_code = spu.spu_code
LEFT JOIN sds.r_user_wx AS USER -- 采购员
  ON USER.feishu_user_id=po.purchaser_id
