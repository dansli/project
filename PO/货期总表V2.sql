 -- --------------------------------------------- 
-- Subject:PO最新货期
-- Author: 王思卓 
-- Create: 2025-09-08 
-- Update: 更新时间  姓名  更改内容
 -- ---------------------------------------------


-- create table dw.ads_po_delivery_date(
--     ord_no              VARCHAR  COMMENT '订单序号',
--     pro_cat_disp_name1  VARCHAR  COMMENT '商品一级分类',
--     pro_cat_disp_name2  VARCHAR  COMMENT '商品二级分类',
--     pro_cat_disp_name3  VARCHAR  COMMENT '商品三级分类',
--     pro_type            VARCHAR  COMMENT '产品线',
--     department_name     VARCHAR  COMMENT '产品部门',
--     supplier_name       VARCHAR  COMMENT '供应商',
--     user_name           VARCHAR  COMMENT '采购员',
--     creator_name        VARCHAR  COMMENT '计划负责人',
--     IP                  VARCHAR  COMMENT 'IP',
--     ip_type             VARCHAR  COMMENT '系列IP分类',
--     launch_date         DATE          COMMENT '上市日期',
--     series_name         VARCHAR COMMENT '系列名称',
--     major_spu_code      VARCHAR COMMENT '主系列编码',
--     spu_code            VARCHAR COMMENT '系列编码',
--     retail_price        DECIMAL(38,18) COMMENT '零售价',
--     box_spec            VARCHAR  COMMENT '盒规',
--     pr_code             VARCHAR  COMMENT 'PR单',
--     po_type             VARCHAR  COMMENT 'PO生产类型',
--     pr_create_time      DATE      COMMENT 'PR创建日期',
--     po_create_time      DATE      COMMENT 'PO确认时间',
--     demand_time         DATE      COMMENT '需求到货时间',
--     po_shiping_time     DATE      COMMENT '供应商承诺发货时间',
--     latest_delivery_date DATE    COMMENT '最新货期',
--     pr_shiping_time     DATE      COMMENT '出货清单发货时间',
--     real_delivery_date  DATE      COMMENT '发货单实际发货时间',
--     inv_create_time     DATE      COMMENT '收货时间',
--     batch_number        VARCHAR   COMMENT '批次',
--     type_name           VARCHAR   COMMENT '明细类型',
--     req_cnt             INT           COMMENT '数量个',
--     req_cnt_box         DOUBLE           COMMENT '数量套',
--     channel_code        VARCHAR   COMMENT '渠道代码',
--     PRIMARY KEY (pr_code, spu_code,po_create_time,pr_shiping_time,latest_delivery_date,real_delivery_date,inv_create_time,type_name,channel_code) 
-- ) COMMENT='货期总表';

TRUNCATE TABLE dw.ads_po_delivery_date;
INSERT INTO dw.ads_po_delivery_date
WITH base AS (
  SELECT
    DISTINCT
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    pr.pr_code,
    pr.creator_name,
    pr.type_code,
    pr.type_name,
    goods.pro_cat_name1,
    goods.pro_cat_name2,
    goods.pro_cat_name3,
    goods.pro_type,
    goods.department_full_name,
    goods.ip_name,
    goods.series_ip_type as ip_type,
    goods.launch_date,
    goods.series_name,
    goods.box_spec,
    MAX(pr.batch_number) AS batch_number,
    MAX(pr.demand_time) AS demand_time,
    MAX(pr.shipping_time) AS pr_shiping_time,
    MAX(inv.real_delivery_date) AS real_delivery_date,
    MAX(pr.create_time) AS pr_create_time,
    MAX(inv.create_time) AS inv_create_time
  FROM dw.dwd_pr_info pr
  LEFT JOIN po.purchase_requirement_related_shipping_list_detail pr_sl
    ON pr_sl.pr_code = pr.pr_code
   AND pr_sl.sku_hd_code = pr.sku_code
   AND pr_sl.type = pr.type_code
   AND pr_sl.channel_code = pr.channel_code
   AND pr_sl.sl_code = pr.sl_code
  LEFT JOIN dw.dwd_po_invoice inv
    ON inv.sl_code = pr_sl.sl_code
   AND inv.sku_code = pr_sl.sku_hd_code
   AND inv.type_code = pr_sl.type
   AND inv.channel_code = pr_sl.channel_code
LEFT JOIN dw.dim_goods goods
    ON goods.sku_code = pr.sku_code
  GROUP BY
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    pr.pr_code,
    pr.creator_name,
    pr.create_time,
    pr.type_code,
    pr.type_name,
    goods.pro_cat_name1,
    goods.pro_cat_name2,
    goods.pro_cat_name3,
    goods.pro_type,
    goods.department_full_name,
    goods.ip_name,
    goods.series_ip_type,
    goods.launch_date,
    goods.series_name,
    goods.box_spec
),
cnt AS (
  SELECT 
    pr_code,
    spu_code,
    major_spu_code,
    channel_code,
    type AS type_code,
    SUM(quantity) AS req_cnt
  FROM po.purchase_requirement_sku_info 
  GROUP BY 
    pr_code,
    spu_code,
    major_spu_code,
    channel_code,
    type
),
po AS (  
  SELECT
    DISTINCT
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    pr.pr_code,
    pr.creator_name,
    po.purchaser_id,
    po.supplier_name,
    po.type_code,
    MAX(po.shipping_time) AS po_shiping_time,
    MAX(sl_log.create_time) AS po_create_time
  FROM dw.dwd_pr_info pr
  LEFT JOIN dw.dwd_po_info po
   ON pr.pr_code = po.pr_code
   AND pr.sku_code = po.sku_code
   AND pr.type_code = po.type_code
  LEFT JOIN po.operation_log AS sl_log
  ON pr.po_code = sl_log.business_code 
  AND sl_log.operate_type='CONFIRM' 
  AND sl_log.business_type='PURCHASE_ORDER'
  GROUP BY 
    pr.major_spu_code,
    pr.spu_code,
    pr.channel_code,
    pr.channel_name,
    pr.pr_code,
    pr.creator_name,
    po.purchaser_id,
    po.supplier_name,
    po.type_code
)

SELECT 
  CONCAT(SERIAL.order_category, SERIAL.serial_no) AS ord_no,
  base.pro_cat_name1,
  base.pro_cat_name2,
  base.pro_cat_name3,
  base.pro_type,
  base.department_full_name as department_name,
  po.supplier_name,
  USER.name AS user_name,
  base.creator_name,
  base.ip_name AS IP,
  base.ip_type,
  date_format(base.launch_date, 'yyyy-MM-dd') as launch_date,
  base.series_name,
  base.major_spu_code,
  base.spu_code,
  spu.retail_price,
  base.box_spec,
  base.pr_code,
  -- base.po_code as PO单,
  '成品' AS po_type,
  DATE_FORMAT(base.pr_create_time, 'yyyy-MM-dd') AS pr_create_time,
  DATE_FORMAT(po.po_create_time, 'yyyy-MM-dd') AS po_create_time,
  DATE_FORMAT(base.demand_time, 'yyyy-MM-dd') AS demand_time,
  DATE_FORMAT(po.po_shiping_time, 'yyyy-MM-dd') AS po_shiping_time,
  CASE
    WHEN base.real_delivery_date IS NOT NULL THEN base.real_delivery_date -- 优先取实际发货时间
    ELSE CASE -- 没有实际发货时间，取 3 个计划时间的最大值
      WHEN GREATEST(
            COALESCE(base.demand_time, '1900-01-01'),
            COALESCE(po.po_shiping_time, '1900-01-01'),
            COALESCE(base.pr_shiping_time, '1900-01-01')
          ) < CURRENT_DATE() -- 如果最大时间小于今天，自动用今天
        THEN CURRENT_DATE()
      ELSE GREATEST(
            COALESCE(base.demand_time, '1900-01-01'),
            COALESCE(po.po_shiping_time, '1900-01-01'),
            COALESCE(base.pr_shiping_time, '1900-01-01')
          )
    END
  END AS latest_delivery_date,
  DATE_FORMAT(base.pr_shiping_time, 'yyyy-MM-dd') AS pr_shiping_time,
  DATE_FORMAT(base.real_delivery_date, 'yyyy-MM-dd') AS real_delivery_date,
  DATE_FORMAT(base.inv_create_time, 'yyyy-MM-dd') AS inv_create_time,
  base.batch_number,
  base.type_name,
  CAST(ROUND(cnt.req_cnt) AS INT) as req_cnt,
  cnt.req_cnt/base.box_spec AS req_cnt_box,
  base.channel_code
FROM base 
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
WHERE 
base.pr_code !='PR9331973608767488';





select 
    ord_no as 订单序号,
    pro_cat_disp_name1 as 商品一级分类,
    pro_cat_disp_name2 as 商品二级分类,
    pro_cat_disp_name3 as 商品三级分类,
    pro_type as 产品线,
    department_name as 产品部门,
    supplier_name as 供应商,
    user_name as 采购员,
    creator_name as 计划负责人,
    IP,
    ip_type as 系列IP分类,
    launch_date as 上市日期,
    series_name as 系列名称,
    major_spu_code as 主系列编码,
    spu_code as 系列编码,
    retail_price as 零售价,
    box_spec as 盒规,
    pr_code as PR单,
    po_type as PO生产类型,
    pr_create_time as PR创建日期,
    po_create_time as PO确认时间,
    demand_time as 需求到货时间,
    po_shiping_time as 供应商承诺发货时间,
    latest_delivery_date as 最新货期,
    pr_shiping_time as 出货清单发货时间,
    real_delivery_date as 发货单实际发货时间,
    inv_create_time as 收货时间,
    batch_number as 批次,
    type_name as 明细类型,
    req_cnt as 数量个,
    req_cnt_box as 数量套,
 -- 大中华区
  sum(case when channel_code='CH124' then coalesce(req_cnt,0) else 0 end) as 大中华区盲盒,
--   sum(case when base.channel_code='大中华区' and goods.box_spec>0 
--            then cast(coalesce(cnt.req_cnt,0) as double)/goods.box_spec else 0 end) as 大中华区_套,
--   -- 欧洲区
  sum(case when channel_code='CH133' then coalesce(req_cnt,0) else 0 end) as 欧洲区,
--   sum(case when base.channel_code='欧洲区' and goods.box_spec>0 
--            then cast(coalesce(cnt.req_cnt,0) as double)/goods.box_spec else 0 end) as 欧洲区_套,
  -- 美洲区
  sum(case when channel_code='CH125' then coalesce(req_cnt,0) else 0 end) as 美洲区盲盒,
  sum(case when channel_code='CH127' then coalesce(req_cnt,0) else 0 end) as 美洲区明盒,
--   sum(case when base.channel_code='美洲区' and goods.box_spec>0 
--            then cast(coalesce(cnt.req_cnt,0) as double)/goods.box_spec else 0 end) as 美洲区_套,
  -- 亚太区
  sum(case when channel_code='CH110' then coalesce(req_cnt,0) else 0 end) as 亚太区,
  sum(case when channel_code='CH122' then coalesce(req_cnt,0) else 0 end) as 市场宣传,
  sum(case when channel_code='CH130' then coalesce(req_cnt,0) else 0 end) as 抖音朗园,
  sum(case when channel_code='CH111' then coalesce(req_cnt,0) else 0 end) as 跨境电商盲盒,
  sum(case when channel_code='CH131' then coalesce(req_cnt,0) else 0 end) as 抖音懋隆,  
  sum(case when channel_code='CH121' then coalesce(req_cnt,0) else 0 end) as 泡泡乐园,
  sum(
  case 
    when channel_code is not null and type_name ='大货'
     and channel_code not in ('CH124','CH133','CH125','CH127','CH110','CH122','CH130','CH111','CH131','CH121')
    then coalesce(req_cnt,0) 
    else 0 
  end
) as 新增渠道
--   sum(case when base.channel_name='亚太区' and goods.box_spec>0 
--            then cast(coalesce(cnt.req_cnt,0) as double)/goods.box_spec else 0 end) as 亚太区_套
from dw.ads_po_delivery_date
where 1=1
${if(len(pro_type)=0,""," and pro_type in ('"+replace(pro_type,"\n","','")+"')")} -- 产品线
${if(len(creator_name)=0,""," and creator_name in ('"+replace(creator_name,"\n","','")+"')")} -- 计划负责人
${if(len(series_name)=0,""," and series_name in ('"+replace(series_name,"\n","','")+"')")} -- 系列名称
${if(len(major_spu_code)=0,""," and major_spu_code in ('"+replace(major_spu_code,"\n","','")+"')")} -- 主系列编码
${if(len(spu_code)=0,""," and spu_code in ('"+replace(spu_code,"\n","','")+"')")} -- 系列编码
${if(len(pr_code)=0,""," and pr_code in ('"+replace(pr_code,"\n","','")+"')")} -- PR单
${if(len(type_name)=0,""," and type_name in ('"+replace(type_name,"\n","','")+"')")} -- 明细类型
${if(len(po_type)=0,""," and po_type in ('"+replace(po_type,"\n","','")+"')")} -- PO生产类型
${if(len(start)=0,""," and latest_delivery_date >= '"+start+"'")}
${if(len(end)=0,""," and latest_delivery_date <= '"+end+"'")}
group by 
    ord_no,
    pro_cat_disp_name1,
    pro_cat_disp_name2,
    pro_cat_disp_name3,
    pro_type,
    department_name,
    supplier_name,
    user_name,
    creator_name,
    IP,
    ip_type,
    launch_date,
    series_name,
    major_spu_code,
    spu_code,
    retail_price,
    box_spec,
    pr_code,
    po_type,
    pr_create_time,
    po_create_time,
    demand_time,
    po_shiping_time,
    latest_delivery_date,
    pr_shiping_time,
    real_delivery_date,
    inv_create_time,
    batch_number,
    type_name,
    req_cnt,
    req_cnt_box