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
CUSTOMER_2ND_CAT_NAME IN ('ROBOshop' ) AND  CUSTRECORD_BI_BUDGET_ORDER_TYPE=1 AND
 TRAN_DATE >='${begindate}'
  AND TRAN_DATE  <='${ENDdate}' 
	
	)
	SELECT 
	    ITEM_NAME,
    ITEM_CODE
  
    ,PRODUCT_COUNT,

	INCL_TAX_RMB_AMOUNT
    ,name
	,海鼎大类,
	海鼎中类,
	海鼎小类,
	海外一级,
	海外二级,
	商业一级,
	商业二级,
	商业三级
	FROM(
    SELECT 
       ITEM_NAME,
    ITEM_CODE
  
    ,PRODUCT_COUNT,

	INCL_TAX_RMB_AMOUNT
    ,name
   ,ZBIGTYPE_TXT      AS 海鼎大类,
	ZMIDDLETYPE_TXT   AS 海鼎中类,
	ZLITTLETYPE_TXT   AS 海鼎小类,
	FIRST_CLASS_NAME  AS 海外一级,
	SECOND_CLASS_NAME AS 海外二级,
	ZBUSINESS1_TXT    AS 商业一级,
	ZBUSINESS2_TXT    AS 商业二级,
	ZBUSINESS3_TXT    AS 商业三级
    FROM
    (SELECT 
    ITEM_NAME,
    ITEM_CODE
   
    ,PRODUCT_COUNT,

	INCL_TAX_RMB_AMOUNT
    FROM(
SELECT 
	
	ITEM_NAME,
      ITEM_CODE,
	  	
	SUM(PRODUCT_COUNT) AS PRODUCT_COUNT,
	
	SUM(INCL_TAX_RMB_AMOUNT) AS INCL_TAX_RMB_AMOUNT
from (
SELECT ITEM_NAME,
      ITEM_CODE,
	  CUSTOMER_NAME  AS 机器人ID,
	自营加盟,
	国家地区,
	PRODUCT_COUNT,
	INCL_TAX_RMB_AMOUNT
	FROM 
	temp_oversea_detail)AAA
	where 
	 1=1 ${if(jiqirenid == '',"","and  机器人ID in ('" + jiqirenid + "')")}	 
   AND 1=1 ${if(GUOJIA == '',"","and  国家地区 in ('" + GUOJIA + "')")}	 
    AND 1=1 ${if(ziyi == '',"","and  自营加盟 in ('" + ziyi + "')")}
	GROUP BY 
      ITEM_CODE,
    ITEM_NAME
    )AAA) A
    LEFT JOIN  
    (SELECT 
     DISTINCT 
A.name,B.fullname
FROM 
NS.CUSTOMRECORD_PM_IP_ICON A
LEFT JOIN 
NS.dim_oversea_item B
ON A.id =B.custitem_pm_item_ipicon 
LEFT JOIN 
NS.item C
ON B.fullname=C.itemid) B
ON A.ITEM_CODE=B.fullname
LEFT JOIN 
(select 
                    ITEMID,
                    ZBIGTYPE_TXT,
                    ZMIDDLETYPE_TXT,
                    ZLITTLETYPE_TXT,
                    ZBUSINESS1_TXT,
                    ZBUSINESS2_TXT,
                    ZBUSINESS3_TXT,
                    IP_TYPE,
                    FIRST_CLASS_NAME_CN as FIRST_CLASS_NAME,
                    SECOND_CLASS_NAME_CN as SECOND_CLASS_NAME,
                    IP_NAME as IP
                FROM 
                    ns.dim_oversea_item
                ) D
				ON  A.ITEM_CODE=D.ITEMID
)AA 
WHERE
 1=1 ${if(IP == '',"","and  name in ('" + IP + "')")}	 
    AND 1=1 ${if(SKU == '',"","and   ITEM_NAME in ('" + SKU + "')")} 
	AND 1=1 ${if(haidingdalei == '',"","and  海鼎大类 in ('" + haidingdalei + "')")}	 
    AND 1=1 ${if(haidingxiaolei == '',"","and   海鼎小类 in ('" + haidingxiaolei + "')")}
	AND 1=1 ${if(haidingzhonglei == '',"","and   海鼎中类 in ('" + haidingzhonglei + "')")}
	AND 1=1 ${if(shangyeyiji == '',"","and  商业一级 in ('" + shangyeyiji + "')")}	 
    AND 1=1 ${if(shangyeerji == '',"","and  商业二级 in ('" + shangyeerji + "')")}
	AND 1=1 ${if(shangyesanji == '',"","and 商业三级 in ('" + shangyesanji + "')")}
	AND 1=1 ${if(haiwaiyiji == '',"","and  海外一级 in ('" + haiwaiyiji + "')")}
	AND 1=1 ${if(haiwaierji == '',"","and 海外二级 in  ('" + haiwaierji + "')")}
