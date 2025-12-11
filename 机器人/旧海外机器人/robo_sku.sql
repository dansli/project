with temp_oversea_detail as (
  select 
	TRAN_DATE,
	TRAN_DAY,
	SUBSIDIARY_NAME,
    SUBSIDIARY_COUNTRY,
	SALE_COUNTRY as 国家地区,
	CUSTOMER_ID,
	CUSTOMER_CODE,
	REGEXP_SUBSTR(customer_name, 'R[A-Z0-9]{2}-[A-Z0-9]{4}', 1, 1)  as CUSTOMER_NAME,
	CUSTOMER_CITY,
	CUSTOMER_COUNTRY,
	CUSTOMER_CONTINENT,
	CUSTOMER_CATEGORY,
	CUSTOMER_2ND_CAT_NAME,
	CUSTOMER_3ND_CAT_NAME,
	SALE_COUNTRY,
	ITEM_CODE,
	ITEM_NAME,
	PRODUCT_COUNT,
	RMB_AMOUNT,
	INCL_TAX_RMB_AMOUNT,
 CASE WHEN IS_TARGET =1  THEN '自营' ELSE  '加盟' END  AS 自营加盟
from 
	ns.dws_oversea_order_v2_detail
WHERE 
CUSTOMER_2ND_CAT_NAME IN ('ROBOshop') 
AND CUSTRECORD_BI_BUDGET_ORDER_TYPE=1 
AND tran_date between '${start}' and '${end}')



SELECT 
i.tran_date,
iii.SUBSIDIARY_REGIONAL_SEGMENTATION as subsidiary_country,
i.customer_code,
i.customer_name,
i.customer_country,
i.customer_city,
i.customer_2nd_cat_name,
i.item_code,
i.item_name,
ii.ZBIGTYPE_TXT,
 ii.ZMIDDLETYPE_TXT,
 ii.ZLITTLETYPE_TXT,
 ii.ZBUSINESS1_TXT,
 ii.ZBUSINESS2_TXT,
 ii.ZBUSINESS3_TXT,
 ii.FIRST_CLASS_NAME_CN,
 ii.SECOND_CLASS_NAME_CN,
 ii.IP_NAME,
 i.PRODUCT_COUNT,
 i.INCL_TAX_RMB_AMOUNT
from
temp_oversea_detail as i
left JOIN 
(SELECT 
 itemid,
 ZBIGTYPE_TXT,
 ZMIDDLETYPE_TXT,
 ZLITTLETYPE_TXT,
 ZBUSINESS1_TXT,
 ZBUSINESS2_TXT,
 ZBUSINESS3_TXT,
 FIRST_CLASS_NAME_CN,
 SECOND_CLASS_NAME_CN,
 oversea_ip_name as IP_NAME
from ns.dim_oversea_item) as ii
on i.item_code = ii.itemid
left JOIN 
(select entityid,SUBSIDIARY_REGIONAL_SEGMENTATION from ns.zods_customer) as iii
on i.customer_code = iii.entityid
where 
1 = 1 
    ${if(jiqirenid == '', "", "AND 机器人ID IN ('" + jiqirenid + "')")} 
AND 1 = 1 
    ${if(GUOJIA == '', "", "AND 国家地区 IN ('" + GUOJIA + "')")} 
AND 1 = 1 
    ${if(ziyi == '', "", "AND 自营加盟 IN ('" + ziyi + "')")} 
 and 1 = 1 
    ${if(IP == '', "", "AND IP_NAME IN ('" + IP + "')")} 
    AND 1 = 1 
    ${if(SKU == '', "", "AND ITEM_NAME IN ('" + SKU + "')")} 
    AND 1 = 1 
    ${if(haidingdalei == '', "", "AND 海鼎大类 IN ('" + haidingdalei + "')")} 
    AND 1 = 1 
    ${if(haidingxiaolei == '', "", "AND 海鼎小类 IN ('" + haidingxiaolei + "')")} 
    AND 1 = 1 
    ${if(haidingzhonglei == '', "", "AND 海鼎中类 IN ('" + haidingzhonglei + "')")} 
    AND 1 = 1 
    ${if(shangyeyiji == '', "", "AND 商业一级 IN ('" + shangyeyiji + "')")} 
    AND 1 = 1 
    ${if(shangyeerji == '', "", "AND 商业二级 IN ('" + shangyeerji + "')")} 
    AND 1 = 1 
    ${if(shangyesanji == '', "", "AND 商业三级 IN ('" + shangyesanji + "')")} 
    AND 1 = 1 
    ${if(haiwaiyiji == '', "", "AND 海外一级 IN ('" + haiwaiyiji + "')")} 
    AND 1 = 1 
    ${if(haiwaierji == '', "", "AND 海外二级 IN ('" + haiwaierji + "')")}



SELECT
    国家地区,
    ITEM_NAME, 
    ITEM_CODE, 
    PRODUCT_COUNT, 
    INCL_TAX_RMB_AMOUNT, 
    name, 
    海鼎大类, 
    海鼎中类, 
    海鼎小类, 
    海外一级, 
    海外二级, 
    商业一级, 
    商业二级, 
    商业三级 
FROM (
    SELECT 
        ITEM_NAME, 
        ITEM_CODE, 
        PRODUCT_COUNT, 
        INCL_TAX_RMB_AMOUNT, 
        name,
        国家地区, 
        ZBIGTYPE_TXT AS 海鼎大类, 
        ZMIDDLETYPE_TXT AS 海鼎中类, 
        ZLITTLETYPE_TXT AS 海鼎小类, 
        FIRST_CLASS_NAME AS 海外一级, 
        SECOND_CLASS_NAME AS 海外二级, 
        ZBUSINESS1_TXT AS 商业一级, 
        ZBUSINESS2_TXT AS 商业二级, 
        ZBUSINESS3_TXT AS 商业三级 
    FROM (
        SELECT 
            ITEM_NAME, 
            ITEM_CODE, 
            PRODUCT_COUNT, 
            INCL_TAX_RMB_AMOUNT,
            国家地区 
        FROM (
            SELECT 
                ITEM_NAME, 
                ITEM_CODE, 
                SUM(PRODUCT_COUNT) AS PRODUCT_COUNT, 
                SUM(INCL_TAX_RMB_AMOUNT) AS INCL_TAX_RMB_AMOUNT,
                国家地区 
            FROM (
                SELECT 
                    ITEM_NAME, 
                    ITEM_CODE, 
                    CUSTOMER_NAME AS 机器人ID, 
                    自营加盟, 
                    国家地区, 
                    PRODUCT_COUNT, 
                    INCL_TAX_RMB_AMOUNT 
                FROM temp_oversea_detail
            ) AAA 
            WHERE 
                1 = 1 
                ${if(jiqirenid == '', "", "AND 机器人ID IN ('" + jiqirenid + "')")} 
                AND 1 = 1 
                ${if(GUOJIA == '', "", "AND 国家地区 IN ('" + GUOJIA + "')")} 
                AND 1 = 1 
                ${if(ziyi == '', "", "AND 自营加盟 IN ('" + ziyi + "')")} 
            GROUP BY 
                ITEM_CODE, 
                ITEM_NAME
        ) AAA
    ) A 
    LEFT JOIN (
        SELECT DISTINCT 
            A.name, 
            B.fullname 
        FROM NS.CUSTOMRECORD_PM_IP_ICON A 
        LEFT JOIN NS.dim_oversea_item B ON A.id = B.custitem_pm_item_ipicon 
        LEFT JOIN NS.item C ON B.fullname = C.itemid
    ) B ON A.ITEM_CODE = B.fullname 
    LEFT JOIN (
        SELECT 
            ITEMID, 
            ZBIGTYPE_TXT, 
            ZMIDDLETYPE_TXT, 
            ZLITTLETYPE_TXT, 
            ZBUSINESS1_TXT, 
            ZBUSINESS2_TXT, 
            ZBUSINESS3_TXT, 
            IP_TYPE, 
            FIRST_CLASS_NAME_CN AS FIRST_CLASS_NAME, 
            SECOND_CLASS_NAME_CN AS SECOND_CLASS_NAME, 
            IP_NAME AS IP 
        FROM ns.dim_oversea_item
    ) D ON A.ITEM_CODE = D.ITEMID
) AA 
WHERE 
    1 = 1 
    ${if(IP == '', "", "AND name IN ('" + IP + "')")} 
    AND 1 = 1 
    ${if(SKU == '', "", "AND ITEM_NAME IN ('" + SKU + "')")} 
    AND 1 = 1 
    ${if(haidingdalei == '', "", "AND 海鼎大类 IN ('" + haidingdalei + "')")} 
    AND 1 = 1 
    ${if(haidingxiaolei == '', "", "AND 海鼎小类 IN ('" + haidingxiaolei + "')")} 
    AND 1 = 1 
    ${if(haidingzhonglei == '', "", "AND 海鼎中类 IN ('" + haidingzhonglei + "')")} 
    AND 1 = 1 
    ${if(shangyeyiji == '', "", "AND 商业一级 IN ('" + shangyeyiji + "')")} 
    AND 1 = 1 
    ${if(shangyeerji == '', "", "AND 商业二级 IN ('" + shangyeerji + "')")} 
    AND 1 = 1 
    ${if(shangyesanji == '', "", "AND 商业三级 IN ('" + shangyesanji + "')")} 
    AND 1 = 1 
    ${if(haiwaiyiji == '', "", "AND 海外一级 IN ('" + haiwaiyiji + "')")} 
    AND 1 = 1 
    ${if(haiwaierji == '', "", "AND 海外二级 IN ('" + haiwaierji + "')")}





    (CASE 
    WHEN CUSTOMER_3ND_CAT_NAME = '总部跨境电商' THEN '总部跨境电商' 
    WHEN categoryname2 IN ('Agency', 'Retail') AND SUBSIDIARY IN (1, 10) AND COUNTRY_CODE <> 'HK' AND CUSTOMER_CONTINENT = '东亚区域' THEN '东亚KA' 
    WHEN ((((categoryname2 IN ('Agency', 'Retail')) AND (SUBSIDIARY IN (1, 10))) AND (NOT (COUNTRY_CODE IN ('HK', 'FR')))) AND (CUSTOMER_CONTINENT = '欧洲区域')) THEN '欧洲KA' 
    WHEN ((((categoryname2 IN ('Agency', 'Retail')) AND (SUBSIDIARY = 29)) AND (COUNTRY_CODE <> 'FR')) AND (CUSTOMER_CONTINENT = '欧洲区域')) THEN '欧洲KA' 
    WHEN ((((categoryname2 IN ('Agency', 'Retail')) AND (SUBSIDIARY IN (1, 10))) AND (COUNTRY_CODE <> 'HK')) AND (CUSTOMER_CONTINENT = '澳新区域')) THEN '澳新KA' 
    WHEN ((((categoryname2 IN ('Agency', 'Retail')) AND (SUBSIDIARY IN (1, 10))) AND (COUNTRY_CODE <> 'HK')) AND (CUSTOMER_CONTINENT = '北美区域')) THEN '北美KA' 
    WHEN ((((categoryname2 IN ('Agency', 'Retail')) AND (SUBSIDIARY IN (1, 10))) AND (COUNTRY_CODE <> 'HK')) AND (CUSTOMER_CONTINENT = '东南亚区域')) THEN '东南亚KA' 
    WHEN (country_name = '香港,中国') THEN '中国香港' 
    WHEN (country_name = '台湾,中国') THEN '中国台湾' 
    WHEN (country_name = '澳门') THEN '中国澳门' 
    ELSE country_name END) SUBSIDIARY_REGIONAL_SEGMENTATION
