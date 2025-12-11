WITH  JIQIRENZHUSHUJU AS (SELECT     robo_no           
	,robo_id            
	,robo_countiy    
    ,robo_countiy||'-'||robo_ctiy||'-'||robo_weizhi||'-'||robo_level||'-'||right(robo_id,3) AS 机器人名称
	,robo_ctiy          
	,robo_weizhi        
	,robo_level         
	,robo_weizhileixing 
	,case when  robo_moshi='直营店' THEN  '自营'
	 WHEN robo_countiy='中国台湾'  THEN  '自营'
	 WHEN  robo_moshi='代运营' THEN  '加盟' ELSE robo_moshi  END AS robo_moshi      
	,robo_begindate    
	,robo_cs           
	,robo_type         
	,robo_date 
    ,left(REPLACE(robo_begindate,'-',''),6) AS 月份
    FROM SDS_INT.robo_zhushuju
	WHERE  
robo_type='在业'  
	) ,
	konghuodaolv as (SELECT 
国家地区, -- 客户id
machine_id, -- 机器ID
slot_id, -- 货道ID
sku, -- 货道商品sku
name, -- 货道商品名称
quantity, -- 变化数量
操作日志 ,
type, -- 操作类型，remote_load：后台调整上货；load：上货 ; solve: 恢复BAD; unload :下货
notes, -- 操作备注信息
action_time -- 操作时间 
FROM(
select 
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
END AS 国家地区, -- 客户id
  machine_id, -- 机器ID
  slot_id, -- 货道ID
  sku, -- 货道商品sku
  name, -- 货道商品名称
  quantity, -- 变化数量
  CASE WHEN type='remote_load' THEN '后台调整上货' 
  WHEN type IN('Load(Outside)') THEN '上货至(货道备库)' 
   WHEN type IN('load_outside') AND 
slot_id ='' THEN '上货至(机器备库)' 
 WHEN type IN('unload_outside') AND 
slot_id ='' THEN '下货至(机器备库)' 
  WHEN type='load' THEN '上货' 
  WHEN type='solve' THEN '恢复BAD' 
  WHEN type='unload' THEN '下货' 
  WHEN type='Unload change to Outside' THEN '下货至备库'
  END AS 操作日志 ,
  type, -- 操作类型，remote_load：后台调整上货；load：上货 ; solve: 恢复BAD; unload :下货
  notes, -- 操作备注信息
  action_time -- 操作时间 
from sds.hy_get_stock_event 
where action_time >= curdate()-interval 30 day
AND action_time >='${begindate}' 
AND action_time <='${enddate}' 
  and custom_id in ('Thailand'
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
)
)AAA
)
 ,shangxiahuoshuliang as   
  ( SELECT 
   DISTINCT 
  robo_id            
	,robo_countiy    
    ,机器人名称
	,robo_ctiy   
,robo_moshi	
,国家地区
,上下货操作
,action_time, -- 操作时间 
 周
   FROM(
SELECT 
robo_id            
	,robo_countiy    
    ,机器人名称
	,robo_ctiy   
,robo_moshi,	
 国家地区
国家地区, -- 客户id
machine_id, -- 机器ID
slot_id, -- 货道ID
sku, -- 货道商品sku
name, -- 货道商品名称
quantity, -- 变化数量
操作日志 ,
type, -- 操作类型，remote_load：后台调整上货；load：上货 ; solve: 恢复BAD; unload :下货
notes, -- 操作备注信息
action_time, -- 操作时间 
 WEEKOFYEAR(action_time) AS 周,
 case when quantity<>0 then 1 else 0 end AS 上下货操作
FROM(
 SELECT 
 robo_id            
	,robo_countiy    
    ,机器人名称
	,robo_ctiy   
,robo_moshi  ,	
国家地区, -- 客户id
machine_id, -- 机器ID
slot_id, -- 货道ID
sku, -- 货道商品sku
name, -- 货道商品名称
quantity, -- 变化数量
操作日志 ,
type, -- 操作类型，remote_load：后台调整上货；load：上货 ; solve: 恢复BAD; unload :下货
notes, -- 操作备注信息
CAST(action_time AS DATE) AS action_time -- 操作时间 
  
 FROM 
 JIQIRENZHUSHUJU  A
LEFT JOIN 
 konghuodaolv  B 
 ON A.robo_id=B.machine_id
    )AAA
   WHERE  action_time IS NOT NULL AND  操作日志 LIKE '%上货%' AND 
 1=1 ${if(ziying == '',"","and  robo_moshi in ('" + ziying + "')")} 
)AAA)
,
konghuodaol as (SELECT 
国家地区
,machine_id
,总货道数
,COUNT(DISTINCT sku) AS SKU数量
,SUM(空货道数) AS 空货道数
,SUM(坏货道)   AS 坏货道
,CASE WHEN  总货道数=0 OR (SUM(空货道数)-SUM(坏货道))<=0 THEN 0 ELSE (SUM(空货道数)-SUM(坏货道) )/总货道数 END AS 空货道率
,SUBSTR(取数时间,1,10) AS 取数时间BY天
,SUBSTR(取数时间,1,7) AS 取数时间BY月
,WEEK(取数时间,3) AS 取数时间BY周
,取数时间
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
  ,CASE WHEN state<>'occupied' THEN 1 ELSE 0 END AS 坏货道
  ,CASE WHEN  custom_id IN('Australia-popmart','Australia-TOP-1')
              THEN              
  date_format(date_sub(extract_time,interval -2 hour),'%Y-%m-%d %H:00:00') 
  WHEN  custom_id IN('FRANCE-SOGEEK','France')
              THEN              
  date_format(date_sub(extract_time,interval 6 hour),'%Y-%m-%d %H:00:00')
   WHEN  custom_id IN('JAP_Milestone')
              THEN              
  date_format(date_sub(extract_time,interval -1 hour),'%Y-%m-%d %H:00:00')
    WHEN  custom_id IN('New-Zealand')
              THEN              
  date_format(date_sub(extract_time,interval -4 hour),'%Y-%m-%d %H:00:00')
  WHEN  custom_id IN('POPMARTUK')
              THEN              
  date_format(date_sub(extract_time,interval -7 hour),'%Y-%m-%d %H:00:00')
    ELSE extract_time END 
  as  取数时间 
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
WHERE  
SUBSTR(取数时间,1,10)>='${begindate}' 
and 
SUBSTR(取数时间,1,10)<='${enddate}' 
and 
hour(取数时间) in (10,12,15,18,21,23)
GROUP BY  
国家地区
,machine_id
,总货道数
,取数时间), SHANGPINTOP AS (SELECT 
CASE WHEN SALE_COUNTRY='香港,中国' THEN '中国香港'
WHEN SALE_COUNTRY='台湾,中国' THEN '中国台湾'
ELSE SALE_COUNTRY END AS SALE_COUNTRY
,ITEM_NAME
,ITEM_CODE
, PRODUCT_COUNT
,EXCL_TAX_RMB_AMOUNT
, 商品排名
  ,海鼎大类,
海鼎中类,
海鼎小类,
海外一级,
海外二级,
 商业一级,
 商业二级,
商业三级,
国内建议零售价
,custitem_pm_item_main_barcode
  ,name
FROM(
SELECT 
SALE_COUNTRY
,ITEM_NAME
,ITEM_CODE
, PRODUCT_COUNT
,EXCL_TAX_RMB_AMOUNT
  ,海鼎大类,
海鼎中类,
海鼎小类,
海外一级,
海外二级,
 商业一级,
 商业二级,
商业三级,
国内建议零售价
,custitem_pm_item_main_barcode
  ,name
,ROW_NUMBER() OVER(PARTITION BY  SALE_COUNTRY ORDER BY EXCL_TAX_RMB_AMOUNT DESC) AS 商品排名
FROM(
SELECT SALE_COUNTRY
,ITEM_NAME
,A.ITEM_CODE
  ,ZBIGTYPE_TXT      AS 海鼎大类,
	ZMIDDLETYPE_TXT   AS 海鼎中类,
	ZLITTLETYPE_TXT   AS 海鼎小类,
	FIRST_CLASS_NAME  AS 海外一级,
	SECOND_CLASS_NAME AS 海外二级,
	ZBUSINESS1_TXT    AS 商业一级,
	ZBUSINESS2_TXT    AS 商业二级,
	ZBUSINESS3_TXT    AS 商业三级,
	 CUSTITEM_PM_CHINA_PRICE AS 国内建议零售价
,custitem_pm_item_main_barcode
  ,name
,SUM(PRODUCT_COUNT) AS PRODUCT_COUNT
,SUM(EXCL_TAX_RMB_AMOUNT) AS EXCL_TAX_RMB_AMOUNT
from 
	ns.dws_oversea_order_v2_detail  A
    LEFT JOIN 
(SELECT 
     DISTINCT 
A.name,B.fullname,C.displayname,C.custitem_pm_item_main_barcode
FROM 
NS.CUSTOMRECORD_PM_IP_ICON A
LEFT JOIN 
NS.dim_oversea_item B
ON A.id =B.custitem_pm_item_ipicon 
LEFT JOIN 
NS.item C
ON B.fullname=C.itemid)  B
ON A. ITEM_CODE=B.fullname
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
                    IP_NAME as IP,
					 CUSTITEM_PM_UP_DATE,
 CUSTITEM_PM_CHINA_PRICE
                FROM 
                    ns.dim_oversea_item
                ) D
				ON  A.ITEM_CODE=D.ITEMID
    WHERE TRAN_DATE BETWEEN   DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) + 7 DAY)
    AND DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) + 1 DAY)
    GROUP  BY  
    SALE_COUNTRY
,ITEM_NAME
,A.ITEM_CODE,
  ZBIGTYPE_TXT    ,
	ZMIDDLETYPE_TXT  ,
	ZLITTLETYPE_TXT  ,
	FIRST_CLASS_NAME  ,
	SECOND_CLASS_NAME,
	ZBUSINESS1_TXT ,
	ZBUSINESS2_TXT,
	ZBUSINESS3_TXT,
	 CUSTITEM_PM_CHINA_PRICE

  ,name
)AAA
  WHERE (商业三级 NOT IN('毛绒玩偶（大）','毛绒玩偶其他') OR 海外二级 NOT IN ('MEGA400%','MEGA1000%')  ) 
)aaa
WHERE 商品排名<=20),
shangpinshouqin as (SELECT 
国家地区
,machine_id
,取数时间
, 取数时间BY天
,取数时间BY月
,取数时间BY周
,sum(售罄) AS 售罄
,CASE WHEN SKU数 =0 THEN 0 ELSE   sum(售罄)/count(DISTINCT sku) END as 售罄率
,sum(TOP上机) AS TOP上机
,sum(TOP上机)/20 AS TOP上机率
                    ,count(DISTINCT sku) as SKU数
FROM(
SELECT 
国家地区
,machine_id
,总货道数
,SKU数
,SUBSTR(取数时间,1,10) AS 取数时间BY天
,SUBSTR(取数时间,1,7) AS 取数时间BY月
,WEEK(取数时间,3) AS 取数时间BY周
,SUM(quantity)AS 数量
  ,CASE WHEN SUM(quantity)=0 THEN 1 ELSE 0 END AS 售罄
,取数时间
,sku
,B.custitem_pm_item_main_barcode
,CASE WHEN custitem_pm_item_main_barcode IS NOT NULL THEN 1 ELSE 0 END AS TOP上机
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
  COUNT(slot_id) OVER(PARTITION  BY machine_id,extract_time) AS 总货道数
   , COUNT(sku) OVER(PARTITION  BY machine_id,extract_time) AS SKU数
  ,case when quantity=0 THEN 1 ELSE 0 END AS 空货道数
  ,CASE WHEN state='bad' THEN 1 ELSE 0 END AS 坏货道
  ,CASE WHEN  custom_id IN('Australia-popmart','Australia-TOP-1')
              THEN              
  date_format(date_sub(extract_time,interval -2 hour),'%Y-%m-%d %H:00:00') 
  WHEN  custom_id IN('FRANCE-SOGEEK','France')
              THEN              
  date_format(date_sub(extract_time,interval 6 hour),'%Y-%m-%d %H:00:00')
   WHEN  custom_id IN('JAP_Milestone')
              THEN              
  date_format(date_sub(extract_time,interval -1 hour),'%Y-%m-%d %H:00:00')
    WHEN  custom_id IN('New-Zealand')
              THEN              
  date_format(date_sub(extract_time,interval -4 hour),'%Y-%m-%d %H:00:00')
  WHEN  custom_id IN('POPMARTUK')
              THEN              
  date_format(date_sub(extract_time,interval -7 hour),'%Y-%m-%d %H:00:00')
    ELSE extract_time END 
  as  取数时间 
  ,quantity
from sds.hy_get_machine_slots_info_recode 
where   sku IS NOT NULL AND  machine_id IN(SELECT    DISTINCT  robo_id 
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
)A
LEFT JOIN  
SHANGPINTOP B  
ON A.国家地区=B.SALE_COUNTRY AND A.SKU=B.custitem_pm_item_main_barcode
WHERE  sku is not null and 
SUBSTR(取数时间,1,10)>='${begindate}' 
and 
SUBSTR(取数时间,1,10)<='${enddate}' 
and 
hour(取数时间) in (10,12,15,18,21,23)
GROUP BY  
国家地区
,machine_id
,总货道数
,取数时间
,sku
,custitem_pm_item_main_barcode
)AAA
GROUP BY  
国家地区
,machine_id
,SKU数
,取数时间
, 取数时间BY天
,取数时间BY月
,取数时间BY周)


SELECT 
取数时间BY天
,取数时间BY周
,machine_id
,国家地区
, 空货道率
,MAX(取数时间BY天) OVER(PARTITION BY 取数时间BY周)||'~'||MIN(取数时间BY天) OVER(PARTITION BY 取数时间BY周) 
AS 每周 
FROM(
select 
取数时间BY天
,取数时间BY周
,machine_id
,国家地区
,AVG(空货道率) AS 空货道率
from konghuodaol
GROUP BY 
取数时间BY天
,取数时间BY周
,machine_id
,国家地区
)AAA
