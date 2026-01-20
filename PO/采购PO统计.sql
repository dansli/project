-- DWD dwd_po_detail
-- 与dwd_po_info的不同：1. type中的付费备品和免费备品分开，不再合并 2. 没有发货单相关信息 3. 备品分为免费和付费不进行合并
CREATE TABLE
    dw.dwd_po_detail (
        po_id double COMMENT 'PO单主键',
        major_po_code varchar COMMENT '主PO单号',
        pr_code varchar COMMENT 'PR单号',
        pr_create_time datetime COMMENT 'PR创建时间',
        po_num varchar COMMENT 'PO单序号',
        po_code varchar COMMENT 'PO单号',
        po_order_status varchar COMMENT 'PO单据状态',
        spu_code varchar COMMENT '系列编码',
        major_spu_code varchar COMMENT '主系列编码',
        sku_code varchar COMMENT '商品编码',
        sku_name varchar COMMENT '商品名称',
        play_way_code varchar COMMENT '玩具玩法代码(4-盲售-多款单码，3-其他，2-盲售，1-明售)',
        package_form_code varchar COMMENT '包装方式ID',
        package_form_name varchar COMMENT '包装方式名称：盲盒；明盒；陈列品；其他',
        type_code varchar COMMENT '商品类型',
        type_name varchar COMMENT '商品类型：BULK-大货；SPARE-备品；DISPLAY-陈列；RETAINED-留货',
        supplier_id double COMMENT '供应商ID',
        supplier_name varchar COMMENT '供应商名称',
        purchase_subject_id double COMMENT '采购主体ID',
        purchaser_id varchar COMMENT '采购员ID',
        purchaser_name varchar COMMENT '采购员名称',
        creator_name varchar COMMENT '创建人',
        purchase_cnt double COMMENT '采购数量',
        purchase_cnt_bom double COMMENT '部件采购数量',
        purchase_price_id double COMMENT '商品采购价ID',
        purchase_price double COMMENT '采购单价（含税）',
        purchase_amount double COMMENT '采购金额：单价（含税）* 数量',
        currency_code varchar COMMENT '币种代码',
        po_type varchar COMMENT 'PO单据类型：SPU-系列；SKU-商品',
        production_mode_en varchar COMMENT '生产模式英文',
        production_mode_cn varchar COMMENT '生产模式中文：FINISHED_PRODUCT-成品；COMPONENT-部件；ASSEMBLY_FEE-组装',
        po_create_time datetime COMMENT 'PO创建时间',
        po_order_amount double COMMENT 'PO单总金额',
        major_po_order_amount double COMMENT '主PO单总金额',
        PRIMARY KEY (po_id, sku_code)
    ) COMMENT = 'PO单模型：拆分成品和组件'
TRUNCATE TABLE dw.dwd_po_detail;

INSERT INTO
    dw.dwd_po_detail
SELECT
    t_sku.id AS po_id -- PO单ID
,
    t_info.major_po_code AS major_po_code -- 主PO单号
,
    t_po_rel.pr_code AS pr_code -- PR单号
,
    t_pr.create_time as pr_create_time -- PR创建时间
,
    CONCAT (serial_info.order_category, serial_info.serial_no) as po_num -- PO单序号
,
    t_info.po_code AS po_code -- PO单号
,
    t_info.order_status AS po_order_status -- PO单据状态
,
    t_sku.spu_code AS spu_code -- 系列编码
,
    t_sku.major_spu_code AS major_spu_code -- 主系列编码
,
    t_sku.sku_hd_code AS sku_code -- 商品编码
,
    t_code.sku_name AS sku_name -- 商品名称
,
    spu.play_way_code as play_way_code -- 玩具玩法代码(4-盲售-多款单码，3-其他，2-盲售，1-明售)
,
    t_code.package_form_code AS package_form_code -- 包装方式ID
,
    decode (
        t_code.package_form_code,
        '1',
        '盲盒',
        '2',
        '明盒',
        '3',
        '陈列品',
        '其他'
    ) AS package_form_name -- 包装方式名称
,
    t_sku.type AS type_code -- 商品类型
,
    DECODE (
        t_sku.type,
        'BULK',
        '大货',
        'FREE_SPARE',
        '免费备品',
        'PAY_SPARE',
        '付费备品',
        'DISPLAY',
        '陈列',
        'RETAINED',
        '留货',
        t_sku.type
    ) AS type_name -- 商品类型名称
,
    t_info.supplier_id AS supplier_id -- 供应商ID
,
    CASE
        WHEN LENGTH (t_sup.abbr_name) > 1 THEN t_sup.abbr_name
        ELSE t_sup.name
    END AS supplier_name -- 供应商名称
,
    t_info.purchase_subject_id AS purchase_subject_id -- 采购主体ID
,
    t_info.purchaser_id AS purchaser_id -- 采购员ID
,
    user.name as purchaser_name -- 采购员名称
,
    t_info.creator_name AS creator_name -- 创建人
,
    CAST(t_sku.quantity AS VARCHAR) AS purchase_cnt -- 采购数量
,
    0 as purchase_cnt_bom -- 部件采购数量
,
    t_sku.purchase_price_id AS purchase_price_id -- 商品采购价ID
,
    t_sku.purchase_price as purchase_price -- 采购单价（含税）
    -- ,case when t_info.production_mode ='FINISHED_PRODUCT' then t_sku.purchase_price else  bom.bom_purchase_price end  AS purchase_price       -- 采购单价（含税）
,
    t_sku.quantity * t_sku.purchase_price AS purchase_amount -- 采购金额（含税）
,
    t_sku.currency_code as currency_code -- 币种代码
,
    t_info.order_type as po_type -- PO单据类型
,
    t_info.production_mode as production_mode_en -- 生产类型
,
    DECODE (
        t_info.production_mode,
        'FINISHED_PRODUCT',
        '成品',
        'COMPONENT',
        '部件',
        'ASSEMBLY_FEE',
        '组装',
        t_info.production_mode
    ) as production_mode_cn -- 生产类型名称
,
    t_info.create_time as po_create_time -- PO创建时间
,
    t_info.order_amount as po_order_amount -- PO单总金额
    -- ,bom.proportion as bom_proportion   -- 组装配比
,
    t_major.major_po_order_amount -- 主PO单总金额
FROM
    po.purchase_order_info t_info -- PO单信息表
    JOIN po.purchase_order_sku_info t_sku -- PO单商品信息表
    ON t_info.po_code = t_sku.po_code
    AND t_sku.data_status = 1
    LEFT JOIN po.base_sku_info t_code -- 商品信息
    ON t_sku.sku_hd_code = t_code.sku_hd_code
    LEFT JOIN po.base_supplier_info t_sup -- PO单供应商信息
    ON t_info.supplier_id = t_sup.id
    AND t_sup.data_status = 1
    LEFT JOIN po.purchase_requirement_related_purchase_order_info t_po_rel -- PR和PO单关系信息表
    ON t_info.po_code = t_po_rel.po_code
    AND t_po_rel.data_status = 1
    left join sds.r_user_wx as user -- 采购员
    on user.feishu_user_id = t_info.purchaser_id
    left join po.order_serial_no_info as serial_info on serial_info.spu_code = t_sku.spu_code
    and serial_info.order_category = 'PO'
    and serial_info.order_code = t_sku.po_code
    and serial_info.data_status = 1
    left join po.purchase_requirement_info as t_pr on t_po_rel.pr_code = t_pr.pr_code
    and t_pr.data_status = 1
    left join po.base_spu_info as spu on t_sku.spu_code = spu.spu_code
    and spu.data_status = 1
    left join (
        select
            major_po_code,
            sum(order_amount) as major_po_order_amount
        from
            po.purchase_order_info
        where
            data_status = 1
        group by
            major_po_code
    ) as t_major on t_major.major_po_code = t_info.major_po_code
WHERE
    t_info.data_status = 1
    AND t_info.order_status <> 'CANCELED'
    and t_info.production_mode = 'FINISHED_PRODUCT'
union all
SELECT
    t_sku.id AS po_id -- PO单ID
,
    t_info.major_po_code AS major_po_code -- 主PO单号
,
    t_po_rel.pr_code AS pr_code -- PR单号
,
    t_pr.create_time as pr_create_time -- PR创建时间
,
    CONCAT (serial_info.order_category, serial_info.serial_no) as po_num -- PO单序号
,
    t_info.po_code AS po_code -- PO单号
,
    t_info.order_status AS po_order_status -- PO单据状态
,
    t_sku.spu_code AS spu_code -- 系列编码
,
    t_sku.major_spu_code AS major_spu_code -- 主系列编码
,
    t_sku.sku_hd_code AS sku_code -- 商品编码
,
    t_code.sku_name AS sku_name -- 商品名称
,
    spu.play_way_code as play_way_code -- 玩具玩法代码(4-盲售-多款单码，3-其他，2-盲售，1-明售)
,
    t_code.package_form_code AS package_form_code -- 包装方式ID
,
    decode (
        t_code.package_form_code,
        '1',
        '盲盒',
        '2',
        '明盒',
        '3',
        '陈列品',
        '其他'
    ) AS package_form_name -- 包装方式
,
    t_sku.type AS type_code -- 商品类型
,
    DECODE (
        t_sku.type,
        'BULK',
        '大货',
        'FREE_SPARE',
        '免费备品',
        'PAY_SPARE',
        '付费备品',
        'DISPLAY',
        '陈列',
        'RETAINED',
        '留货',
        t_sku.type
    ) AS type_name -- 商品类型名称
,
    t_info.supplier_id AS supplier_id -- 供应商ID
,
    CASE
        WHEN LENGTH (t_sup.abbr_name) > 1 THEN t_sup.abbr_name
        ELSE t_sup.name
    END AS supplier_name -- 供应商名称
,
    t_info.purchase_subject_id AS purchase_subject_id -- 采购主体ID
,
    t_info.purchaser_id AS purchaser_id -- 采购员ID
,
    user.name as purchaser_name -- 采购员名称
,
    t_info.creator_name AS creator_name -- 创建人
,
    CAST(t_sku.quantity AS VARCHAR) AS purchase_cnt -- 采购数量
,
    t_bom.quantity AS purchase_cnt_bom -- 部件采购数量
,
    t_sku.purchase_price_id AS purchase_price_id -- 商品采购价ID
,
    t_bom.bom_purchase_price AS purchase_price -- 采购单价（含税）
    -- ,t_bom.quantity*t_bom.bom_purchase_price  AS  purchase_amount  -- 采购金额（含税）
,
    t_sku.quantity * t_sku.purchase_price AS purchase_amount -- 采购金额（含税）
,
    'CNY' as currency_code -- 币种代码 部件组装默认CNY
,
    t_info.order_type as po_type -- PO单据类型
,
    t_info.production_mode as production_mode_en -- 生产类型
,
    DECODE (
        t_info.production_mode,
        'FINISHED_PRODUCT',
        '成品',
        'COMPONENT',
        '部件',
        'ASSEMBLY_FEE',
        '组装',
        t_info.production_mode
    ) as production_mode_cn -- 生产类型名称
,
    t_info.create_time as po_create_time -- PO创建时间
,
    t_info.order_amount as po_order_amount -- PO单总金额
    -- ,bom.proportion as bom_proportion   -- 组装配比
,
    t_major.major_po_order_amount -- 主PO单总金额
FROM
    po.purchase_order_info t_info -- PO单信息表
    JOIN po.purchase_order_sku_info t_sku -- PO单商品信息表
    ON t_info.po_code = t_sku.po_code
    AND t_sku.data_status = 1
    LEFT JOIN po.base_sku_info t_code -- 商品信息
    ON t_sku.sku_hd_code = t_code.sku_hd_code
    LEFT JOIN po.base_supplier_info t_sup -- PO单供应商信息
    ON t_info.supplier_id = t_sup.id
    AND t_sup.data_status = 1
    LEFT JOIN po.purchase_requirement_related_purchase_order_info t_po_rel -- PR和PO单关系信息表
    ON t_info.po_code = t_po_rel.po_code
    AND t_po_rel.data_status = 1
    left join sds.r_user_wx as user -- 采购员
    on user.feishu_user_id = t_info.purchaser_id
    left join po.order_serial_no_info as serial_info on serial_info.spu_code = t_sku.spu_code
    and serial_info.order_category = 'PO'
    and serial_info.order_code = t_sku.po_code
    and serial_info.data_status = 1
    left join po.purchase_requirement_info as t_pr on t_po_rel.pr_code = t_pr.pr_code
    and t_pr.data_status = 1
    left join (
        select
            bom.po_code,
            bom.sku_hd_code,
            sku.type,
            -- component_type, 
            -- sum(purchase_price) as bom_purchase_price,
            avg(bom.purchase_price) as bom_purchase_price,
            sum(bom.proportion * sku.quantity) as quantity
        from
            po.purchase_order_sku_bom_info as bom
            left join po.purchase_order_sku_info as sku on sku.po_code = bom.po_code
            and sku.sku_hd_code = bom.sku_hd_code
        where
            bom.data_status = 1
            -- and sku.po_code='PO10783515251671041' 
            -- and sku.sku_hd_code='1250224032'
        group by
            bom.po_code,
            bom.sku_hd_code,
            sku.type
            -- ,component_type
    ) as t_bom on t_bom.po_code = t_sku.po_code
    -- and t_bom.component_type=t_info.production_mode 
    and t_bom.sku_hd_code = t_sku.sku_hd_code
    and t_bom.type = t_sku.type
    -- left join 
    -- (select 
    -- po_code,
    -- sku_hd_code,
    -- -- component_type,
    -- -- proportion,
    -- avg(purchase_price) as bom_purchase_price
    -- from po.purchase_order_sku_bom_info
    -- where data_status=1
    -- group by 
    -- po_code,sku_hd_code
    -- -- ,component_type
    -- -- ,proportion
    -- ) as bom
    -- on bom.po_code = t_sku.po_code 
    -- -- and bom.component_type=t_info.production_mode
    -- and bom.sku_hd_code=t_sku.sku_hd_code 
    left join po.base_spu_info as spu on t_sku.spu_code = spu.spu_code
    and spu.data_status = 1
    left join (
        select
            major_po_code,
            sum(order_amount) as major_po_order_amount
        from
            po.purchase_order_info
        where
            data_status = 1
        group by
            major_po_code
    ) as t_major on t_major.major_po_code = t_info.major_po_code
WHERE
    t_info.data_status = 1
    AND t_info.order_status <> 'CANCELED'
    and t_info.production_mode != 'FINISHED_PRODUCT';

-------------------------------------------
-------------------------------------------
-- DWS dws_po_detail
-- drop TABLE dw.dws_po_detail
CREATE TABLE
    dw.dws_po_detail (
        purchase_subject_id bigint COMMENT '采购主体ID',
        spu_code varchar COMMENT '系列编码',
        sku_code varchar COMMENT '商品编码',
        box_spec varchar COMMENT '包装规格',
        retail_price double COMMENT '零售价',
        supplier_name varchar COMMENT '供应商名称',
        po_code varchar COMMENT 'PO单号',
        po_type varchar COMMENT 'PO单据类型：SPU-系列；SKU-商品',
        purchaser_name varchar COMMENT '采购员名称',
        production_mode_cn varchar COMMENT '生产模式中文：FINISHED_PRODUCT-成品；COMPONENT-部件；ASSEMBLY_FEE-组装',
        pr_create_time datetime COMMENT 'PR创建时间',
        po_create_time datetime COMMENT 'PO创建时间',
        po_num varchar COMMENT 'PO单序号',
        purchase_price_blind double COMMENT '盲盒采购单价',
        purchase_price_clear double COMMENT '明盒采购单价',
        purchase_price_other double COMMENT '非盲售采购单价',
        currency_code varchar COMMENT '币种代码',
        purchase_cnt_box double COMMENT '采购数量（盒）',
        purchase_cnt double COMMENT '采购数量',
        purchase_cnt_blind_bulk_box double COMMENT '盲盒大货采购数量（盒）',
        purchase_cnt_blind_bulk double COMMENT '盲盒大货采购数量',
        purchase_cnt_clear_bulk_box double COMMENT '明盒大货采购数量（盒）',
        purchase_cnt_clear_bulk double COMMENT '明盒大货采购数量',
        purchase_cnt_bulk double COMMENT '大货采购数量',
        purchase_cnt_retained_box double COMMENT '留货采购数量（盒）',
        purchase_cnt_retained double COMMENT '留货采购数量',
        purchase_cnt_display_box double COMMENT '陈列采购数量（盒）',
        purchase_cnt_display double COMMENT '陈列采购数量',
        purchase_cnt_pay_spare double COMMENT '付费备品采购数量',
        purchase_cnt_free_spare double COMMENT '免费备品采购数量',
        po_order_amount double COMMENT 'PO单总金额',
        purchase_amount double COMMENT 'PO产品金额',
        major_po_order_amount double COMMENT '一品多厂PO总金额',
        price_diff_pcs double COMMENT '明盲盒差价（PCS）',
        PRIMARY KEY (po_code, sku_code)
    ) COMMENT = 'PO单汇总：拆分成品和组件'
TRUNCATE TABLE dw.dws_po_detail;

INSERT INTO
    dw.dws_po_detail
    -- 按SKU下单
select
    purchase_subject_id,
    spu_code,
    sku_code,
    box_spec,
    retail_price,
    supplier_name,
    po_code,
    po_type,
    purchaser_name,
    production_mode_cn,
    pr_create_time,
    po_create_time,
    -- year(po_create_time) as po_create_year,
    po_num,
    avg(
        case
            when package_form_code = 1 then purchase_price
            else null
        end
    ) as purchase_price_blind,
    avg(
        case
            when package_form_code = 2 then purchase_price
            else null
        end
    ) as purchase_price_clear,
    SUM(
        case
            when play_way_code not in (2, 4) then purchase_price
            else 0
        end
    ) as purchase_price_other, -- 非盲售
    currency_code,
    null as purchase_cnt_box,
    sum(purchase_cnt) - sum(
        case
            when type_code = 'FREE_SPARE' then purchase_cnt
            else 0
        end
    ) as purchase_cnt,
    null as purchase_cnt_blind_bulk_box,
    sum(
        case
            when package_form_code = 1
            and type_code = 'BULK' then purchase_cnt
            else 0
        end
    ) as purchase_cnt_blind_bulk,
    null as purchase_cnt_clear_bulk_box,
    sum(
        case
            when package_form_code = 2
            and type_code = 'BULK' then purchase_cnt
            else 0
        end
    ) as purchase_cnt_clear_bulk,
    sum(
        case
            when type_code = 'BULK' then purchase_cnt
            else 0
        end
    ) as purchase_cnt_bulk,
    null as purchase_cnt_retained_box,
    sum(
        case
            when type_code = 'RETAINED' then purchase_cnt
            else 0
        end
    ) as purchase_cnt_retained,
    -- sum(case when package_form_code= 2 and type_code = 'RETAINED' then purchase_cnt else 0 end) as purchase_cnt_clear_box_retained,
    null as purchase_cnt_display_box,
    sum(
        case
            when type_code = 'DISPLAY' then purchase_cnt
            else 0
        end
    ) as purchase_cnt_display,
    sum(
        case
            when type_code = 'PAY_SPARE' then purchase_cnt
            else 0
        end
    ) as purchase_cnt_pay_spare,
    sum(
        case
            when type_code = 'FREE_SPARE' then purchase_cnt
            else 0
        end
    ) as purchase_cnt_free_spare,
    avg(po_order_amount) as po_order_amount, -- PO单金额
    sum(purchase_amount) as purchase_amount, -- PO产品金额
    avg(major_po_order_amount) as major_po_order_amount, -- 一品多厂PO总金额
    null as price_diff_pcs -- 明盲盒差价（PCS）
    -- (avg(case when package_form_code= 2 then purchase_price else null end)- avg(case when package_form_code= 1 then purchase_price else null end))*box_spec as price_diff -- 明盲盒差价（盒）
from
    dw.dwd_po_detail
where
    po_type = 'SKU'
group by
    purchase_subject_id,
    spu_code,
    sku_code,
    box_spec,
    supplier_name,
    po_code,
    po_type,
    purchaser_name,
    production_mode_cn,
    pr_create_time,
    po_create_time,
    po_num,
    currency_code,
    retail_price
union all
-- 按系列下单
select
    po.purchase_subject_id,
    po.spu_code,
    null as sku_code,
    po.box_spec,
    po.retail_price,
    po.supplier_name,
    po.po_code,
    po.po_type,
    po.purchaser_name,
    po.production_mode_cn,
    po.pr_create_time,
    po.po_create_time,
    -- year(po.po_create_time) as po_create_year,
    po.po_num,
    -- sum(case when package_form_code= 1 then purchase_price else 0 end) as purchase_price_blind_box,
    avg(
        case
            when po.package_form_code = 1 then po.purchase_price
            else null
        end
    ) as purchase_price_blind,
    avg(
        case
            when po.package_form_code = 2 then po.purchase_price
            else null
        end
    ) as purchase_price_clear,
    SUM(
        case
            when po.play_way_code not in (2, 4) then po.purchase_price
            else 0
        end
    ) as purchase_price_other, -- 非盲售
    po.currency_code,
    sum(spu.quantity) - sum(
        case
            when type_code = 'FREE_SPARE' then spu.quantity
            else 0
        end
    ) as purchase_cnt_box,
    sum(po.purchase_cnt_bom) - sum(
        case
            when po.type_code = 'FREE_SPARE' then po.purchase_cnt_bom
            else 0
        end
    ) as purchase_cnt,
    sum(
        case
            when po.package_form_code = 1
            and po.type_code = 'BULK' then spu.quantity
            else 0
        end
    ) as purchase_cnt_blind_bulk_box,
    sum(
        case
            when po.package_form_code = 1
            and po.type_code = 'BULK' then po.purchase_cnt
            else 0
        end
    ) as purchase_cnt_blind_bulk,
    sum(
        case
            when po.package_form_code = 2
            and po.type_code = 'BULK' then spu.quantity
            else 0
        end
    ) as purchase_cnt_clear_bulk_box,
    sum(
        case
            when po.package_form_code = 2
            and po.type_code = 'BULK' then po.purchase_cnt
            else 0
        end
    ) as purchase_cnt_clear_bulk,
    sum(
        case
            when po.type_code = 'BULK' then po.purchase_cnt
            else 0
        end
    ) as purchase_cnt_bulk,
    sum(
        case
            when po.type_code = 'RETAINED' then spu.quantity
            else 0
        end
    ) as purchase_cnt_retained_box,
    sum(
        case
            when po.type_code = 'RETAINED' then po.purchase_cnt
            else 0
        end
    ) as purchase_cnt_retained,
    -- sum(case when package_form_code= 2 and type_code = 'RETAINED' then purchase_cnt else 0 end) as purchase_cnt_clear_box_retained,
    sum(
        case
            when po.type_code = 'DISPLAY' then spu.quantity
            else 0
        end
    ) as purchase_cnt_display_box,
    sum(
        case
            when po.type_code = 'DISPLAY' then po.purchase_cnt
            else 0
        end
    ) as purchase_cnt_display,
    sum(
        case
            when po.type_code = 'PAY_SPARE' then po.purchase_cnt
            else 0
        end
    ) as purchase_cnt_pay_spare,
    sum(
        case
            when po.type_code = 'FREE_SPARE' then po.purchase_cnt
            else 0
        end
    ) as purchase_cnt_free_spare,
    avg(po.po_order_amount) as po_order_amount, -- PO单金额
    sum(po.purchase_amount) as purchase_amount, -- PO产品金额
    avg(po.major_po_order_amount) as major_po_order_amount, -- 一品多厂PO总金额
    avg(
        case
            when po.package_form_code = 2 then po.purchase_price
            else null
        end
    ) - avg(
        case
            when po.package_form_code = 1 then po.purchase_price
            else null
        end
    ) as price_diff_pcs -- 明盲盒差价（PCS）
from
    dw.dwd_po_detail as po
    left join po.purchase_order_spu_info as spu on po.po_code = spu.po_code
    and po.type_code = spu.type
    and po.spu_code = spu.spu_code
where
    po_type = 'SPU'
    -- and po_code='PO10783515251671041'
group by
    po.purchase_subject_id,
    po.spu_code,
    po.box_spec,
    po.supplier_name,
    po.po_code,
    po.po_type,
    po.purchaser_name,
    po.production_mode_cn,
    po.pr_create_time,
    po.po_create_time,
    po.po_num,
    po.currency_code,
    po.retail_price
    --------------------------------------------
    --------------------------------------------
    -- ADS dw.ads_po_detail
    -- drop TABLE dw.ads_po_detail
    -- drop TABLE dw.ads_po_detail
CREATE TABLE
    dw.ads_po_detail (
        purchase_subject_id bigint COMMENT '采购主体ID',
        spu_code varchar COMMENT '系列编码',
        sku_code varchar COMMENT '商品编码',
        box_spec varchar COMMENT '包装规格',
        retail_price double COMMENT '零售价',
        supplier_name varchar COMMENT '供应商名称',
        po_code varchar COMMENT 'PO单号',
        po_type varchar COMMENT 'PO单据类型：SPU-系列；SKU-商品',
        purchaser_name varchar COMMENT '采购员名称',
        production_mode_cn varchar COMMENT '生产模式中文：FINISHED_PRODUCT-成品；COMPONENT-部件；ASSEMBLY_FEE-组装',
        pr_create_time datetime COMMENT 'PR创建时间',
        po_create_time datetime COMMENT 'PO创建时间',
        po_create_year bigint COMMENT '下PO年份',
        first_sl_create_time datetime COMMENT '首批交付日期',
        po_confirm_time datetime COMMENT '确认货期日期',
        first_bulk_days bigint COMMENT '首批大货生产周期',
        last_sl_create_time datetime COMMENT '交付完成日期',
        last_bulk_days bigint COMMENT '最后大货生产周期',
        po_num varchar COMMENT 'PO单序号',
        purchase_price_blind double COMMENT '盲盒采购单价',
        purchase_price_clear double COMMENT '明盒采购单价',
        purchase_price_other double COMMENT '非盲售采购单价',
        currency_code varchar COMMENT '币种代码',
        exchangerate double COMMENT '汇率',
        purchase_cnt_box double COMMENT '采购数量（盒）',
        purchase_cnt double COMMENT '采购数量',
        purchase_cnt_blind_bulk_box double COMMENT '盲盒大货采购数量（盒）',
        purchase_cnt_blind_bulk double COMMENT '盲盒大货采购数量',
        purchase_cnt_clear_bulk_box double COMMENT '明盒大货采购数量（盒）',
        purchase_cnt_clear_bulk double COMMENT '明盒大货采购数量',
        purchase_cnt_bulk double COMMENT '大货采购数量',
        purchase_cnt_retained_box double COMMENT '留货采购数量（盒）',
        purchase_cnt_retained double COMMENT '留货采购数量',
        purchase_cnt_display_box double COMMENT '陈列采购数量（盒）',
        purchase_cnt_display double COMMENT '陈列采购数量',
        purchase_cnt_pay_spare double COMMENT '付费备品采购数量',
        purchase_cnt_free_spare double COMMENT '免费备品采购数量',
        po_order_amount double COMMENT 'PO单总金额',
        po_order_amount_cny double COMMENT 'PO单总金额（CNY）',
        purchase_amount double COMMENT 'PO产品金额',
        purchase_amount_cny double COMMENT 'PO产品金额（CNY）',
        major_po_order_amount double COMMENT '一品多厂PO总金额',
        price_diff_pcs double COMMENT '明盲盒差价（PCS）',
        price_diff double COMMENT '明盲盒差价（盒）',
        gross_profit double COMMENT '盲盒毛利（PCS）',
        gross_margin double COMMENT '毛利率',
        PRIMARY KEY (po_code, sku_code)
    ) COMMENT = '采购PO统计表'
TRUNCATE TABLE dw.ads_po_detail;

INSERT INTO
    dw.ads_po_detail
select
    po.purchase_subject_id,
    po.spu_code,
    po.sku_code,
    po.box_spec,
    po.retail_price,
    po.supplier_name,
    po.po_code,
    po.po_type, -- PO单据类型：SPU-系列；SKU-商品
    po.purchaser_name, -- PO单采购员
    po.production_mode_cn, -- 生产类型
    po.pr_create_time, -- PR创建时间
    po.po_create_time, -- PO创建时间
    -- po_create_year,
    year (po.po_create_time) as po_create_year, -- 下PO年份
    first_sl.first_sl_create_time as first_sl_create_time, -- 首批交付日期
    log.confirm_time as po_confirm_time, -- 确认货期日期
    (first_sl.first_sl_create_time - po_create_time) as first_bulk_days, -- 首批大货生产周期
    first_sl.last_sl_create_time as last_sl_create_time, -- 交付完成日期
    (first_sl.last_sl_create_time - po_create_time) as last_bulk_days, -- 系列生产总周期
    po_num,
    purchase_price_blind,
    purchase_price_clear,
    purchase_price_other, -- 非盲售
    currency_code,
    case
        when currency_code = 'CNY' then 1
        else rate.EXCHANGE_RATE
    end as exchangerate, -- 汇率
    (spu.quantity - spu.free_spare_quantity) as purchase_cnt_box,
    purchase_cnt,
    spu.blind_bulk_quantity as purchase_cnt_blind_bulk_box,
    purchase_cnt_blind_bulk,
    spu.clear_bulk_quantity as purchase_cnt_clear_bulk_box,
    purchase_cnt_clear_bulk,
    purchase_cnt_bulk,
    retained_quantity as purchase_cnt_retained_box,
    purchase_cnt_retained,
    spu.display_quantity as purchase_cnt_display_box,
    purchase_cnt_display,
    purchase_cnt_pay_spare,
    purchase_cnt_free_spare,
    po_order_amount, -- PO单金额
    (
        case
            when currency_code = 'CNY' then 1
            else rate.EXCHANGE_RATE
        end
    ) * po_order_amount as po_order_amount_cny, -- PO单金额（CNY）
    purchase_amount, -- PO产品金额
    (
        case
            when currency_code = 'CNY' then 1
            else rate.EXCHANGE_RATE
        end
    ) * purchase_amount as purchase_amount_cny, -- PO产品金额（CNY）
    major_po_order_amount, -- 一品多厂PO总金额
    price_diff_pcs, -- 明盲盒差价（PCS）
    price_diff_pcs * box_spec as price_diff, -- 明盲盒差价（盒）
    retail_price - purchase_price_blind as gross_profit, -- 盲盒毛利（PCS）
    ((purchase_cnt * retail_price) - purchase_amount) / NULLIF(purchase_cnt * retail_price, 0) as gross_margin -- 毛利率
from
    dw.dws_po_detail as po
    left join dw.v_stg_cur_exchange_rate as rate on rate.BASE_CUR_NAME = po.currency_code
    and date_format (po.po_create_time, 'yyyy-MM-dd') = rate.EFF_DATE
    and TRANS_CUR_NAME = 'CNY'
    left join (
        select
            business_code,
            min(create_time) as confirm_time
        from
            po.operation_log
        where
            operate_type = 'CONFIRM'
        group by
            business_code
    ) as log on log.business_code = po.po_code
    left join (
        select
            po_sl.po_code,
            sku.spu_code,
            min(inv.sl_first_create_time) as first_sl_create_time, -- 首批交付日期
            max(inv.sl_last_create_time) as last_sl_create_time -- 交付完成日期
        from
            po.purchase_order_related_shipping_list_detail as po_sl
            left join po.base_sku_info as sku on po_sl.sku_hd_code = sku.sku_hd_code
            left join (
                select
                    related_code,
                    min(create_time) as sl_first_create_time,
                    max(create_time) as sl_last_create_time
                from
                    po.invoice_info
                where
                    related_type = 'SL'
                group by
                    related_code
            ) as inv on po_sl.sl_code = inv.related_code
        group by
            po_sl.po_code,
            sku.spu_code
    ) as first_sl on first_sl.po_code = po.po_code
    and first_sl.spu_code = po.spu_code
    left join (
        SELECT
            po_code,
            spu_code,
            SUM(quantity) AS quantity,
            SUM(
                CASE
                    WHEN package_form_code = 1
                    and type = 'BULK' THEN quantity
                    ELSE 0
                END
            ) AS blind_bulk_quantity,
            SUM(
                CASE
                    WHEN package_form_code = 2
                    and type = 'BULK' THEN quantity
                    ELSE 0
                END
            ) AS clear_bulk_quantity,
            SUM(
                CASE
                    WHEN type = 'RETAINED' THEN quantity
                    ELSE 0
                END
            ) AS retained_quantity,
            SUM(
                CASE
                    WHEN type = 'DISPLAY' THEN quantity
                    ELSE 0
                END
            ) AS display_quantity,
            SUM(
                CASE
                    WHEN type = 'FREE_SPARE' THEN quantity
                    ELSE 0
                END
            ) AS free_spare_quantity
        FROM
            po.purchase_order_spu_info
        WHERE
            data_status = 1
        GROUP BY
            po_code,
            spu_code
    ) as spu on po.po_code = spu.po_code
    and po.spu_code = spu.spu_code
    -- and po.type_code=spu.type and spu.package_form_code=po.package_form_code 
    and po.po_type = 'SPU'







select 
distinct 
    sub.name as 采购主体,  
    g.pro_cat_name1 as 商品一级分类,
    g.pro_cat_name2 as 商品二级分类,
    g.pro_cat_name3 as 商品三级分类,
    g.pro_type as 产品线,
    g.department_full_name as 产品部门,
    g.ip_name as IP名称,
    g.series_name as 系列名称,
    g.main_series_code as 主系列编码,
    po.spu_code as 系列编码,
    po.sku_code as 商品编码,
    case when po.po_type='SPU' then null else g.sku_name end as 商品名称,
    po.box_spec as 盒规,
    g.launch_date as 上市日期,
    po.retail_price as 零售价,
    po.supplier_name as 供应商名称,
    po.po_code as PO单号,
    po.po_type as PO单据类型,
    po.purchaser_name as 采购员,
    po.production_mode_cn as 生产模式,
    po.pr_create_time as PR创建时间,
    po.po_create_time as PO创建时间,
    po.po_create_year as 下PO年份,
    po.first_sl_create_time as 首批交付日期,
    po.po_confirm_time as  确认货期日期,
    po.first_bulk_days as 首批大货生产周期,
    po.last_sl_create_time as 交付完成日期,
    po.last_bulk_days as 系列生产总周期,
    po.po_num as 订单序号,
    round(po.purchase_price_blind,2) as 产品单价盲盒,
    round(po.purchase_price_clear,2) as 产品单价明盒,
    -- po.price_diff as 明盲盒差价,
    po.purchase_price_other as 产品单价非盲售,
    po.currency_code as 币种,
    po.exchangerate as 汇率,
    nvl(po.purchase_cnt_box,0) as 付费数量套,
    po.purchase_cnt as 付费数量个,
    nvl(po.purchase_cnt_blind_bulk_box,0) as 盲盒大货数量套,
    po.purchase_cnt_blind_bulk as 盲盒大货数量个,
    nvl(po.purchase_cnt_clear_bulk_box,0) as 明盒大货数量套,
    po.purchase_cnt_clear_bulk as 明盒大货数量个,
    po.purchase_cnt_bulk as 系列大货数量个,
    nvl(po.purchase_cnt_retained_box,0) as 系列留货数量套,
    po.purchase_cnt_retained as 系列留货数量个,
    po.purchase_cnt_clear_retained as 明盒留货数量个,
    nvl(po.purchase_cnt_display_box,0) as 系列陈列数量套,
    po.purchase_cnt_display as 系列陈列数量个,
    po.purchase_cnt_pay_spare as 付费备品数量个,
    po.purchase_cnt_free_spare as 免费备品数量个,
    po.purchase_cnt_blind_pay_spare as 付费备品盲盒数量个,
    po.purchase_cnt_blind_free_spare as 免费备品盲盒数量个,
    po.po_order_amount as PO单金额,
    po_order_amount_cny as PO单金额CNY,
    po.purchase_amount as PO产品金额,
    -- purchase_amount_cny as PO产品金额CNY,
    nvl(po.major_po_order_amount,'-') as 一品多厂PO总金额,
    case when po.purchase_price_blind is not null 
    and po.purchase_price_clear is not null 
    then round(ABS(po.purchase_price_blind-po.purchase_price_clear),3)
    else '-' end as 明盲盒差价PCS,
    case when po.purchase_price_blind is not null 
    and po.purchase_price_clear is not null 
    then round(po.purchase_cnt_clear,0) else '-' end as 明盒数量个,
    case when po.purchase_price_blind is not null 
    and po.purchase_price_clear is not null 
    then abs(po.purchase_price_blind*(po.purchase_cnt_blind_bulk+po.purchase_cnt_retained-
    po.purchase_cnt_clear_retained+po.purchase_cnt_blind_pay_spare)-
    po.purchase_price_clear*(po.purchase_cnt_clear_bulk+po.purchase_cnt_clear_retained+
    po.purchase_cnt_display+po.purchase_cnt_pay_spare-po.purchase_cnt_blind_free_spare)) 
    else '-' end as PO产品明盲盒差价,
    -- po.gross_profit as 盲盒毛利,
    case when po.retail_price!=0 then po.gross_margin else '-' end as 吊牌毛利
from dw.ads_po_detail as po
LEFT JOIN dw.dim_goods as g
  ON (
       (po.po_type = 'SKU' AND g.sku_code = po.sku_code)
       OR
       (po.po_type ='SPU' AND g.series_code = po.spu_code)
     ) and g.packaging_form !='模具'
left join po.base_purchase_subject_info as sub
on sub.id=po.purchase_subject_id
where 1=1
${if(len(name)=0,""," and sub.name in ('"+replace(name,"\n","','")+"')")} -- 采购主体
${if(len(supplier_name)=0,""," and po.supplier_name in ('"+replace(supplier_name,"\n","','")+"')")} -- 供应商名称
${if(len(series_name)=0,""," and g.series_name in ('"+replace(series_name,"\n","','")+"')")} -- 系列名称
${if(len(main_series_code)=0,""," and g.main_series_code in ('"+replace(main_series_code,"\n","','")+"')")} -- 主系列编码
${if(len(spu_code)=0,""," and spu_code in ('"+replace(spu_code,"\n","','")+"')")} -- 系列编码
${if(len(sku_code)=0,""," and po.sku_code in ('"+replace(sku_code,"\n","','")+"')")} -- 商品编码
${if(len(sku_name)=0,""," and g.sku_name in ('"+replace(sku_name,"\n","','")+"')")} -- 商品名称
${if(len(purchaser_name)=0,""," and po.purchaser_name in ('"+replace(purchaser_name,"\n","','")+"')")} -- PO单采购员
${if(len(pro_cat_name1)=0,""," and g.pro_cat_name1 in ('"+replace(pro_cat_name1,"\n","','")+"')")} -- 商品一级分类
${if(len(pro_cat_name2)=0,""," and g.pro_cat_name2 in ('"+replace(pro_cat_name2,"\n","','")+"')")} -- 商品二级分类
${if(len(pro_cat_name3)=0,""," and g.pro_cat_name3 in ('"+replace(pro_cat_name3,"\n","','")+"')")} -- 商品三级分类
${if(len(start)=0,""," and po.po_create_time >= '"+start+"'")}
${if(len(end)=0,""," and po.po_create_time <= '"+end+"'")}
${if(len(pro_type)=0,""," and g.pro_type in ('"+replace(pro_type,"\n","','")+"')")} -- 产品线
${if(len(ip_name)=0,""," and g.ip_name in ('"+replace(ip_name,"\n","','")+"')")} -- IP
${if(len(po_code)=0,""," and po.po_code in ('"+replace(po_code,"\n","','")+"')")} -- PO单
order by po.po_create_time,po.po_code,po.sku_code,po.spu_code desc





select 
distinct 
    sub.name as 采购主体,  
    g.pro_cat_name1 as 商品一级分类,
    g.pro_cat_name2 as 商品二级分类,
    g.pro_cat_name3 as 商品三级分类,
    g.pro_type as 产品线,
    g.department_full_name as 产品部门,
    g.ip_name as IP名称,
    g.series_name as 系列名称,
    g.main_series_code as 主系列编码,
    po.spu_code as 系列编码,
    po.sku_code as 商品编码,
    case when po.po_type='SPU' then null else g.sku_name end as 商品名称,
    po.box_spec as 盒规,
    g.launch_date as 上市日期,
    po.retail_price as 零售价,
    po.supplier_name as 供应商名称,
    po.po_code as PO单号,
    po.po_type as PO单据类型,
    po.purchaser_name as 采购员,
    po.production_mode_cn as 生产模式,
    po.pr_create_time as PR创建时间,
    po.po_create_time as PO创建时间,
    po.po_create_year as 下PO年份,
    po.first_sl_create_time as 首批交付日期,
    po.po_confirm_time as  确认货期日期,
    po.first_bulk_days as 首批大货生产周期,
    po.last_sl_create_time as 交付完成日期,
    po.last_bulk_days as 系列生产总周期,
    po.po_num as 订单序号,
    round(po.purchase_price_blind,2) as 产品单价盲盒,
    round(po.purchase_price_clear,2) as 产品单价明盒,
    -- po.price_diff as 明盲盒差价,
    po.purchase_price_other as 产品单价非盲售,
    po.currency_code as 币种,
    po.exchangerate as 汇率,
    -- nvl(po.purchase_cnt_box,0) as 付费数量套,
    po.purchase_cnt as 付费数量个,
    -- nvl(po.purchase_cnt_blind_bulk_box,0) as 盲盒大货数量套,
    po.purchase_cnt_blind_bulk as 盲盒大货数量个,
    -- nvl(po.purchase_cnt_clear_bulk_box,0) as 明盒大货数量套,
    po.purchase_cnt_clear_bulk as 明盒大货数量个,
    po.purchase_cnt_bulk as 系列大货数量个,
    -- nvl(po.purchase_cnt_retained_box,0) as 系列留货数量套,
    po.purchase_cnt_retained as 系列留货数量个,
    po.purchase_cnt_clear_retained as 明盒留货数量个,
    -- nvl(po.purchase_cnt_display_box,0) as 系列陈列数量套,
    po.purchase_cnt_display as 系列陈列数量个,
    po.purchase_cnt_pay_spare as 付费备品数量个,
    po.purchase_cnt_free_spare as 免费备品数量个,
    po.purchase_cnt_blind_pay_spare as 付费备品盲盒数量个,
    po.purchase_cnt_blind_free_spare as 免费备品盲盒数量个,
    po.po_order_amount as PO单金额,
    po_order_amount_cny as PO单金额CNY,
    -- po.purchase_amount as PO产品金额,
    -- purchase_amount_cny as PO产品金额CNY,
    nvl(po.major_po_order_amount,'-') as 一品多厂PO总金额,
    case when po.purchase_price_blind is not null 
    and po.purchase_price_clear is not null 
    then round(ABS(po.purchase_price_blind-po.purchase_price_clear),3)
    else '-' end as 明盲盒差价PCS,
    case when po.purchase_price_blind is not null 
    and po.purchase_price_clear is not null 
    then round(po.purchase_cnt_clear,0) else '-' end as 明盒数量个,
    case when po.purchase_price_blind is not null 
    and po.purchase_price_clear is not null 
    then abs(po.purchase_price_blind*(po.purchase_cnt_blind_bulk+po.purchase_cnt_retained-
    po.purchase_cnt_clear_retained+po.purchase_cnt_blind_pay_spare)-
    po.purchase_price_clear*(po.purchase_cnt_clear_bulk+po.purchase_cnt_clear_retained+
    po.purchase_cnt_display+po.purchase_cnt_pay_spare-po.purchase_cnt_blind_free_spare)) 
    else '-' end as PO产品明盲盒差价,
    -- po.gross_profit as 盲盒毛利,
    case when po.retail_price!=0 then po.gross_margin else '-' end as 吊牌毛利
from dw.ads_po_detail as po
LEFT JOIN dw.dim_goods as g
  ON (
       (po.po_type = 'SKU' AND g.sku_code = po.sku_code)
       OR
       (po.po_type ='SPU' AND g.series_code = po.spu_code)
     ) and g.packaging_form !='模具'
left join po.base_purchase_subject_info as sub
on sub.id=po.purchase_subject_id
where 1=1
${if(len(name)=0,""," and sub.name in ('"+replace(name,"\n","','")+"')")} -- 采购主体
${if(len(supplier_name)=0,""," and po.supplier_name in ('"+replace(supplier_name,"\n","','")+"')")} -- 供应商名称
${if(len(series_name)=0,""," and g.series_name in ('"+replace(series_name,"\n","','")+"')")} -- 系列名称
${if(len(main_series_code)=0,""," and g.main_series_code in ('"+replace(main_series_code,"\n","','")+"')")} -- 主系列编码
${if(len(spu_code)=0,""," and spu_code in ('"+replace(spu_code,"\n","','")+"')")} -- 系列编码
${if(len(sku_code)=0,""," and po.sku_code in ('"+replace(sku_code,"\n","','")+"')")} -- 商品编码
${if(len(sku_name)=0,""," and g.sku_name in ('"+replace(sku_name,"\n","','")+"')")} -- 商品名称
${if(len(purchaser_name)=0,""," and po.purchaser_name in ('"+replace(purchaser_name,"\n","','")+"')")} -- PO单采购员
${if(len(pro_cat_name1)=0,""," and g.pro_cat_name1 in ('"+replace(pro_cat_name1,"\n","','")+"')")} -- 商品一级分类
${if(len(pro_cat_name2)=0,""," and g.pro_cat_name2 in ('"+replace(pro_cat_name2,"\n","','")+"')")} -- 商品二级分类
${if(len(pro_cat_name3)=0,""," and g.pro_cat_name3 in ('"+replace(pro_cat_name3,"\n","','")+"')")} -- 商品三级分类
${if(len(start)=0,""," and po.po_create_time >= '"+start+"'")}
${if(len(end)=0,""," and po.po_create_time <= '"+end+"'")}
${if(len(pro_type)=0,""," and g.pro_type in ('"+replace(pro_type,"\n","','")+"')")} -- 产品线
${if(len(ip_name)=0,""," and g.ip_name in ('"+replace(ip_name,"\n","','")+"')")} -- IP
${if(len(po_code)=0,""," and po.po_code in ('"+replace(po_code,"\n","','")+"')")} -- PO单
order by po.po_create_time,po.po_code,po.sku_code,po.spu_code desc

union 

select 
purchase_subject as 采购主体,
pro_cat_name1 as 商品一级分类,
pro_cat_name2 as 商品二级分类,
pro_cat_name3 as 商品三级分类,
pro_type as 产品线,
department_full_name as 产品部门,
ip_name as IP名称,
series_name as 系列名称,
main_series_code as 主系列编码,
spu_code as 系列编码,
sku_code as 商品编码,
sku_name as 商品名称,
box_spec as 盒规,
launch_date as 上市日期,
retail_price as 零售价,
supplier_name as 供应商名称,
po_code as PO单号,
po_type as PO单据类型,
purchaser_name as 采购员,
production_mode_cn as 生产模式,
pr_create_time as PR创建时间,
po_create_time as PO创建时间,
po_create_year as 下PO年份,
first_sl_create_time as 首批交付日期,
po_confirm_time as 确认货期日期,
first_bulk_days as 首批大货生产周期,
last_sl_create_time as 交付完成日期,
last_bulk_days as 系列生产总周期,
po_num as 订单序号,
purchase_price_blind as 产品单价盲盒,
purchase_price_clear as 产品单价明盒,
purchase_price_other as  产品单价非盲售,
currency_code as 币种,
exchangerate as 汇率,
purchase_cnt as 付费数量个,
purchase_cnt_blind_bulk as 盲盒大货数量个,
purchase_cnt_clear_bulk as 明盒大货数量个,
purchase_cnt_bulk as 系列大货数量个,
purchase_cnt_retained as 系列留货数量个,
purchase_cnt_clear_retained as 明盒留货数量个,
purchase_cnt_display as 系列陈列数量个,
purchase_cnt_pay_spare as 付费备品数量个,
purchase_cnt_free_spare as 免费备品数量个,
purchase_cnt_blind_pay_spare as 盲盒付费备品数量个,
purchase_cnt_blind_free_spare as 盲盒免费备品数量个,
po_order_amount as PO单总金额,
po_order_amount_cny as PO单总金额CNY,
-- purchase_amount as PO产品总金额,
major_po_order_amount as 一品多厂PO总金额,
price_diff_pcs as 明盲盒差价PCS,
purchase_cnt_clear as 明盒数量个,
price_diff as 明盲盒差价,
nvl(gross_margin,'-') as 吊牌毛利
from dw.po_detail_manual
where 1=1
${if(len(name)=0,""," and purchase_subject in ('"+replace(name,"\n","','")+"')")} -- 采购主体
${if(len(supplier_name)=0,""," and supplier_name in ('"+replace(supplier_name,"\n","','")+"')")} -- 供应商名称
${if(len(series_name)=0,""," and series_name in ('"+replace(series_name,"\n","','")+"')")} -- 系列名称
${if(len(main_series_code)=0,""," and main_series_code in ('"+replace(main_series_code,"\n","','")+"')")} -- 主系列编码
${if(len(spu_code)=0,""," and spu_code in ('"+replace(spu_code,"\n","','")+"')")} -- 系列编码
${if(len(sku_code)=0,""," and sku_code in ('"+replace(sku_code,"\n","','")+"')")} -- 商品编码
${if(len(sku_name)=0,""," and sku_name in ('"+replace(sku_name,"\n","','")+"')")} -- 商品名称
${if(len(purchaser_name)=0,""," and purchaser_name in ('"+replace(purchaser_name,"\n","','")+"')")} -- PO单采购员
${if(len(pro_cat_name1)=0,""," and pro_cat_name1 in ('"+replace(pro_cat_name1,"\n","','")+"')")} -- 商品一级分类
${if(len(pro_cat_name2)=0,""," and pro_cat_name2 in ('"+replace(pro_cat_name2,"\n","','")+"')")} -- 商品二级分类
${if(len(pro_cat_name3)=0,""," and pro_cat_name3 in ('"+replace(pro_cat_name3,"\n","','")+"')")} -- 商品三级分类
${if(len(start)=0,""," and po_create_time >= '"+start+"'")}
${if(len(end)=0,""," and po_create_time <= '"+end+"'")}
${if(len(pro_type)=0,""," and pro_type in ('"+replace(pro_type,"\n","','")+"')")} -- 产品线
${if(len(ip_name)=0,""," and ip_name in ('"+replace(ip_name,"\n","','")+"')")} -- IP
${if(len(po_code)=0,""," and po_code in ('"+replace(po_code,"\n","','")+"')")} -- PO单
order by po_create_time,po_code,sku_code,spu_code desc