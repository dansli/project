WITH JIQIRENXIAOLIANG AS (
  SELECT 
CUSOTMER_NAME_NS
,SUM(PRODUCT_COUNT) AS 销量
FROM(
 SELECT 
      cast(TRAN_DATE as DATE) as TRAN_DATE,
      SUBSIDIARY_NAME,
      SUBSIDIARY_COUNTRY,
      SUBSIDIARY_CONTINENT,
      CUSTOMER_CODE,
      A.CUSTOMER_NAME,
   REGEXP_SUBSTR(A.customer_name, 'R[A-Z0-9]{2}-[A-Z0-9]{4}', 1, 1) as CUSOTMER_NAME_NS,
      CUSTOMER_CITY,
      CUSTOMER_COUNTRY,
      CUSTOMER_CONTINENT,
      CUSTOMER_CATEGORY,
      CUSTOMER_2ND_CAT_NAME,
      CUSTOMER_3ND_CAT_NAME,
      SALE_COUNTRY,
      SALE_CONTINENT,
      MANAGMENT_PERFORMANCE,
      MANAGMENT_PERFORMANCE_RMB,
      TRADE_COUNT,
      PRODUCT_COUNT,
      CASE WHEN IS_TARGET =1  THEN '自营' ELSE  '加盟' END  AS 自营加盟
     ,chayi
  from 
      ns.dm_oversea_customer_income_day A
  INNER  JOIN  
  (SELECT DISTINCT  CUSTOMER_NAME,MAX(IS_TARGET) AS chayi  FROM 
   ns.dm_oversea_customer_income_day
  WHERE CUSTOMER_2ND_CAT_NAME='ROBOshop' 
 AND   TRAN_DATE>=CURDATE() - INTERVAL 30 DAY
  AND TRAN_DATE<=CURDATE()
   GROUP BY 
    CUSTOMER_NAME
  ) B
  on A.CUSTOMER_NAME=B.CUSTOMER_NAME AND A.IS_TARGET=B.chayi
WHERE CUSTOMER_2ND_CAT_NAME='ROBOshop' 
AND   TRAN_DATE>=CURDATE() - INTERVAL 30 DAY
  AND TRAN_DATE<=CURDATE())AAA
  GROUP  BY  
 CUSOTMER_NAME_NS),
 JIQIRENKUCUN  AS (
SELECT 
国家地区
,A.machine_id
,总货道数
,上机SKU数量
,空货道数
,坏货道
,取数时间BY天
,取数时间BY月
,取数时间BY周
,取数时间
,上机总库存
FROM
(SELECT 
国家地区
,machine_id
,总货道数
,COUNT(DISTINCT sku) AS 上机SKU数量
,SUM(空货道数) AS 空货道数
,SUM(坏货道)   AS 坏货道
,SUBSTR(取数时间,1,10) AS 取数时间BY天
,SUBSTR(取数时间,1,7) AS 取数时间BY月
,WEEK(取数时间,3) AS 取数时间BY周
,取数时间
,sum(quantity) AS  上机总库存
FROM(
select 
CASE 
WHEN custom_id='Thailand'   THEN   '泰国'
WHEN custom_id='SOK'        THEN   '韩国'
WHEN custom_id='SGP'         THEN    '新加坡'
WHEN custom_id='POPMART_TAIWAN'THEN'中国台湾'
WHEN custom_id='POPMARTUK'THEN'英国'
WHEN custom_id='POPMARTMACAO'THEN'澳门'
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
END AS 国家地区,
  machine_id, -- 机器ID
  sku, -- SKU
  extract_time,
  COUNT(machine_id) OVER(PARTITION  BY machine_id,extract_time) AS 总货道数
  ,case when quantity=0  AND state<>'bad'  THEN 1 ELSE 0 END AS 空货道数
  ,CASE WHEN state='bad' THEN 1 ELSE 0 END AS 坏货道
  ,extract_time
  as  取数时间 
  ,quantity
from sds.hy_get_machine_slots_info_recode 
where  machine_id IN(SELECT    DISTINCT  robo_id 
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
)AAA

GROUP BY  
国家地区
,machine_id
,总货道数
,取数时间) A
INNER JOIN  

(SELECT 
 machine_id,
                  MAX(extract_time) AS extract_time  
				  FROM sds.hy_get_machine_slots_info_recode 
 WHERE  custom_id in ('Thailand'
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
GROUP BY  
 machine_id)  B
 ON A.machine_id=B.machine_id AND A.取数时间=B.extract_time)
 SELECT 
 *,CASE WHEN SKU宽度=0 THEN 0 ELSE  上机SKU数量/SKU宽度 END AS 上机率
 ,CASE WHEN 销量=0 THEN 0 ELSE  总库存数量/销量 END AS 存销
 FROM(
 SELECT CUSOTMER_NAME_NS,
销量,国家地区
,machine_id
,总货道数
,上机SKU数量
,空货道数
,坏货道
,取数时间BY天
,取数时间BY月
,取数时间BY周
,取数时间
,上机总库存
,总库存数量
,SKU宽度
FROM JIQIRENXIAOLIANG  A
right JOIN  
 JIQIRENKUCUN  B  
ON A.CUSOTMER_NAME_NS=B.machine_id
LEFT JOIN  
(SELECT 
库存名称 AS 
,Count(ITEM_CODE) as SKU宽度
,SUM(QUANTITYONHAND) AS 总库存数量
FROM
(SELECT 
 CASE WHEN REGEXP_SUBSTR(A.LOCATION_TXT, 'R[A-Z0-9]{2}-[A-Z0-9]{4}', 1, 1)
  IS  NULL THEN 
A.LOCATION_TXT ELSE REGEXP_SUBSTR(A.LOCATION_TXT, 'R[A-Z0-9]{2}-[A-Z0-9]{4}', 1, 1) END   AS 库存名称
 ,LOCATIONTYPE
 ,ITEM_CODE
 ,BARCODE
 ,QUANTITYONHAND 
 FROM 
 NS.ZMM_DMV013   A 
 INNER JOIN  
 (SELECT LOCATION_TXT AS 库存名称,MAX(ZCALDAY) AS 最大时间 
  from NS.ZMM_DMV013   GROUP  BY LOCATION_TXT ) B 
 ON  A.LOCATION_TXT=B.库存名称 AND A.ZCALDAY=B.最大时间
 WHERE A.LOCATIONTYPE='robo shop'  AND A.QUANTITYONHAND >0)
AAA
GROUP BY  
库存名称
 )C
  ON B.machine_id=C.库存名称
  )AAA
