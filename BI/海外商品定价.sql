SELECT
    b.hd_item_id AS SKU,
    b.item_displayname AS "商品名称",
    b.item_english_name AS "英文名称",
    b.sku_name_jp AS "日语名称",
    b.sku_name_kr AS "韩语名称",
    b.sku_name_trad AS "繁体名称",
    b.sku_name_vn AS "越南语名称",
    c.series_code AS "系列编码",
    c.series_name AS "系列名称",
    b.item_main_barcode AS "商品条码",
    b.item_business_1st_class_name AS "商业一级",
    b.item_business_2nd_class_name AS "商业二级",
    b.item_business_3rd_class_name AS "商业三级",
    b.item_price_cn AS "吊牌价",
    b.item_box_spec AS "盒规",
    b.item_case_spec AS "箱规",
    c.series_ip_name AS IP,
    b.item_launch_date AS "上市日期",
    d.name AS "销售国家",
    a.is_tax AS "是否含税",
    a.price AS "对应国家含税价格",
    e.custrecord_pm_69_main_barcode
FROM
    ( -- 商品是否含税
        SELECT
            custrecord_link_item AS item_id -- 商品ID
,
            custrecord_item_rrp_included_tax AS is_tax -- 是否含税
,
            custrecord_item_rrp_country_region AS country_id -- 国家ID
,
            custrecord_link_itemcode AS itemcode,
            NVL (
                custrecord_link_item_price,
                custrecord_item_rrp_suggest_price
            ) as price,
            custrecord_item_rrp_suggest_price
        FROM
            ns.customrecord_item_rrp
        WHERE
            isinactive = 'F'
    ) a
    LEFT JOIN ( -- 商品信息
        SELECT
            id AS item_id -- 商品ID
,
            itemid AS hd_item_id -- SKU
,
            custitem_pm_item_main_barcode AS item_main_barcode -- 商品条码
,
            displayname AS item_displayname -- 商品名称
,
            custitem_pm_english_name AS item_english_name -- 英文名称
,
            TO_DATE (custitem_pm_up_date) AS item_launch_date -- 上市日期
,
            custitem_pm_item_case AS item_box_spec -- 盒规
,
            custitem_pm_item_box AS item_case_spec -- 箱规
,
            custitem_pm_china_price AS item_price_cn -- 吊牌价
,
            custitem_pm_item_series AS series_id -- 系列ID
,
            custitem_pm_business_1st_class AS item_business_1st_class_name -- 商业一级
,
            custitem_pm_business_2nd_class AS item_business_2nd_class_name -- 商业二级
,
            custitem_pm_business_3rd_class AS item_business_3rd_class_name -- 商业三级
,
            custitem_pm_japanese_name AS sku_name_jp -- 商品日语名称
,
            custitem_pm_korea_name AS sku_name_kr -- 商品韩语名称
,
            custitem_pm_traditional_name AS sku_name_trad -- 商品繁体中文名称
,
            custitem_pm_vietnamese_name AS sku_name_vn -- 商品越南语名称		
        FROM
            ns.item
    ) b ON a.item_id = b.item_id
    LEFT JOIN ( -- 系列信息
        SELECT
            se.id AS series_id -- 系列ID
,
            se.custrecord_pm_series_code AS series_code -- 系列编码
,
            se.custrecord_pm_series_name AS series_name -- 系列名称
,
            ipar.name AS series_ip_name -- IP
        FROM
            ns.customrecord_pm_series se
            LEFT JOIN ns.customrecord_pm_ip_archive ipar ON se.custrecord_pm_series_ip = ipar.id
            AND ipar.isinactive = 'F'
    ) c ON b.series_id = c.series_id
    LEFT JOIN ( -- 国家信息
        SELECT
            custrecord_hc_tc_name_en,
            name
        FROM
            ns.customrecord_hc_trading_country
        WHERE
            isinactive = 'F'
    ) d ON a.country_id = d.custrecord_hc_tc_name_en
    LEFT JOIN ns.customrecord_pm_item_code_list e ON a.itemcode = e.id
WHERE
    e.custrecord_pm_69_main_barcode = 'T'
SELECT
    r.sku_code,
    g.sku_barcode,
    g.sku_name,
    g.sku_name_en,
    g.sku_name_trad,
    g.sku_name_jp,
    g.sku_name_kr,
    g.sku_name_vn,
    g.launch_date,
    g.bus_cat_dis_name1,
    g.bus_cat_name2,
    g.bus_cat_name3,
    g.series_code,
    g.series_name,
    g.box_spec,
    g.case_spec,
    g.retail_price,
    r.country_name,
    r.included_tax,
    r.suggest_price
FROM
    dw.dim_item_rrp AS r
    LEFT JOIN dw.dim_goods AS g ON r.sku_code = g.sku_code
WHERE
    (
        '${fine_username}' = '706265205'
        AND r.country_name = '越南'
    )
    OR (
        '${fine_username}' = '191487743'
        AND r.country_name = '越南'
    )
    OR (
        '${fine_username}' = '189089211'
        AND r.country_name = '日本'
    )
    OR (
        '${fine_username}' = '710038002'
        AND r.country_name = '印度尼西亚'
    )
    OR (
        '${fine_username}' NOT IN (
            '706265205',
            '191487743',
            '189089211',
            '710038002'
        )
    )