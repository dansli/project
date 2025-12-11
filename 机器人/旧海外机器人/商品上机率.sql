with temp_oversea_detail as (
  select 
	SALE_COUNTRY,
	ITEM_CODE,
	ITEM_NAME,
   CUSTOMER_2ND_CAT_NAME,
  customer_name,
  REGEXP_SUBSTR(customer_name, 'R[A-Z0-9]{2}-[A-Z0-9]{4}', 1, 1) AS rs_id,
	CASE WHEN  IS_TARGET =1  THEN PRODUCT_COUNT ELSE 0 END                           AS qty,
	CASE WHEN  IS_TARGET =1  THEN RMB_AMOUNT ELSE 0 END                              AS sales,
  CASE WHEN CUSTRECORD_BI_BUDGET_ORDER_TYPE=1   AND   CUSTOMER_2ND_CAT_NAME IN ('ROBOshop') THEN PRODUCT_COUNT ELSE 0 END  AS qty_rs,
  CASE WHEN CUSTRECORD_BI_BUDGET_ORDER_TYPE=1   AND   CUSTOMER_2ND_CAT_NAME IN ('ROBOshop') THEN RMB_AMOUNT ELSE 0 END     AS sales_rs
from 
	ns.dws_oversea_order_v2_detail
WHERE 
 TRAN_DATE between '${start}' and '${end}'
  AND SALE_COUNTRY IN  (select 
  DISTINCT
	SALE_COUNTRY
from 
	ns.dws_oversea_order_v2_detail
WHERE 
CUSTOMER_2ND_CAT_NAME IN ('ROBOshop' ) AND 
 TRAN_DATE between '${start}' and '${end}'
	)
  AND  
    1=1 ${if(country == '',"","and  SALE_COUNTRY in ('" + country + "')")}
	)


,stock_inside_rs as (
select 
  custom_id,
CASE 
WHEN custom_id='Thailand'   THEN   '泰国'
WHEN custom_id='SOK'        THEN   '韩国'
WHEN custom_id='SGP'         THEN    '新加坡'
WHEN custom_id='POPMART_TAIWAN'THEN'中国台湾'
WHEN custom_id='POPMARTUK'THEN'英国'
WHEN custom_id='POPMARTMACAO'THEN'中国澳门'
WHEN custom_id='New-Zealand'THEN'新西兰'
WHEN custom_id='Malaysia'THEN'马来西亚'
WHEN custom_id='JAP_Milestone'THEN'日本'
WHEN custom_id='HKMCTW'THEN'中国香港'
WHEN custom_id='France'THEN'法国'
WHEN custom_id='FRANCE-SOGEEK'THEN'法国'
WHEN custom_id='Australia-popmart'THEN'澳大利亚'
WHEN custom_id='Australia-TOP-1'THEN'澳大利亚'
WHEN custom_id in ('USA','USA-AH','USA_LA528') THEN '美国'
WHEN custom_id in ('CAN_SYoung','CAN','CAN_Token','CAN_Mindzai') THEN '加拿大'
END AS country,
  machine_id, -- 机器ID
  sku, -- SKU
  quantity,
  extract_time
from sds.hy_get_machine_slots_info_recode 
where  machine_id IN(SELECT DISTINCT robo_id 
    FROM SDS_INT.robo_zhushuju
	WHERE robo_type ='在业'
	) AND   custom_id in ('Thailand'
,'SOK'
,'SGP'
,'POPMART_TAIWAN'
,'POPMARTUK'
,'POPMARTMACAO'
,'New-Zealand'
,'Malaysia'
,'JAP_Milestone'
,'HKMCTW'
,'France'
,'FRANCE-SOGEEK'
,'Australia-popmart'
,'Australia-TOP-1'
,'USA','USA-AH','CAN_SYoung','CAN','USA_LA528','CAN_Token','CAN_Mindzai'                          
)
and extract_time='${end}'
)

,sku_sales AS (
  SELECT
    SALE_COUNTRY,
    ITEM_CODE,
    ITEM_NAME,
    CUSTOMER_2ND_CAT_NAME,
    customer_name,
    rs_id,
    SUM(sales) AS sales,
    SUM(qty) AS qty,
    SUM(qty_rs) AS qty_rs,
    SUM(sales_rs) AS sales_rs
  FROM temp_oversea_detail
  GROUP BY
    SALE_COUNTRY,
    ITEM_CODE,
    ITEM_NAME,
    CUSTOMER_2ND_CAT_NAME,
    customer_name,
    rs_id
)

,top20_sku as(select * from (SELECT *,
    ROW_NUMBER() OVER (PARTITION BY SALE_COUNTRY ORDER BY sales DESC) AS rank
FROM sku_sales
where sales > 0 AND sales_rs > 0)
where rank <= 20)





select 
    SALE_COUNTRY,
    rank,
    ITEM_NAME,
    qty,
    qty_rs,
    qty_rs/qty as proportion,
    count(distinct rs_id) as sku_on_rs
from top20_sku
where ITEM_NAME in (select sku from stock_inside_rs)
AND rs_id in (SELECT DISTINCT robo_id 
    FROM SDS_INT.robo_zhushuju
	WHERE  robo_type ='在业'
	)
group by     SALE_COUNTRY,
    rank,
    ITEM_NAME


SELECT 
	i.SALE_COUNTRY,
	i.ITEM_CODE,
	i.ITEM_NAME,
	qty,
	sales,
	qty_rs,
	sales_rs,
  proportion,
	rank,
	all_rs_num,
	ISNULL(rs_num,0) sku_on_rs_num,
  all_rs_num-ISNULL(rs_num,0) AS 有货未上机数,
    case when all_rs_num=0 then 0 else ISNULL(rs_num,0)/all_rs_num end  AS 上机率
from 
(select * ,
CASE WHEN qty=0 THEn 0 ELSE qty_rs/qty END  AS proportion
from top20_sku) as i
left join 
(SELECT 
  country,
  itemid,
  COUNT(DISTINCT machine_id) AS rs_num
  FROM(
SELECT
country,
sku,
machine_id
,itemid,
displayname 
  FROM  
    stock_inside_rs  A 
    LEFT JOIN (
SELECT  custitem_pm_item_main_barcode,
itemid,
displayname  FROM NS.ITEM) B  
ON A.sku=B.custitem_pm_item_main_barcode
) AAA
GROUP  BY  
 country,
  itemid) as ii
  on i.SALE_COUNTRY=ii.country and i.ITEM_CODE=ii.itemid
left join 
(select 
	SALE_COUNTRY,
	COUNT(DISTINCT customer_name) AS all_rs_num
from 
	temp_oversea_detail
	WHERE CUSTOMER_2ND_CAT_NAME IN ('ROBOshop') 
  GROUP BY 
  SALE_COUNTRY) iii
  ON  i.SALE_COUNTRY=iii.SALE_COUNTRY
WHERE  
 1=1 ${if(CODE == '',"","and  A.ITEM_CODE in ('" + CODE + "')")}	 
  ORDER BY  
i. SALE_COUNTRY,
rank
