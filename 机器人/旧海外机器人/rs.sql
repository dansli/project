WITH temp_oversea_customer_income AS (
  SELECT 
      cast(TRAN_DATE as DATE) as TRAN_DATE,
      SUBSIDIARY_NAME,
      SUBSIDIARY_COUNTRY,
      SUBSIDIARY_CONTINENT,
      CUSTOMER_CODE,
     REGEXP_SUBSTR(A.customer_name, 'R[A-Z0-9]{2}-[A-Z0-9]{4}', 1, 1) AS 机器人ID,
      concat(CUSTOMER_CODE," ",A.CUSTOMER_NAME) as CUSOTMER_NAME_NS,
      CUSTOMER_CITY,
      CUSTOMER_COUNTRY,
      CUSTOMER_CONTINENT,
      CUSTOMER_CATEGORY,
      CUSTOMER_2ND_CAT_NAME,
      CUSTOMER_3ND_CAT_NAME,
      SALE_COUNTRY,
      SALE_CONTINENT,
      MANAGMENT_PERFORMANCE,
      MANAGMENT_PERFORMANCE_RMB AS 人民币业绩,
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
   AND   LEFT(TRAN_DATE,4)=LEFT(CURDATE(),4)
   GROUP BY 
    CUSTOMER_NAME
  ) B
  on A.CUSTOMER_NAME=B.CUSTOMER_NAME AND A.IS_TARGET=B.chayi
WHERE CUSTOMER_2ND_CAT_NAME='ROBOshop' 
AND   LEFT(TRAN_DATE,4)=LEFT(CURDATE(),4) AND  LEFT(TRAN_DATE,7)=LEFT(CURDATE()- INTERVAL 1 MONTH,7)
 
  
)
,
JIQIRENZHUSHUJU AS ( SELECT 
     robo_id            
	,robo_countiy    
    ,机器人名称
	,robo_ctiy          
	,robo_weizhi        
	,robo_level         
	,robo_weizhileixing 
	,robo_moshi           
	,robo_cs           
	,robo_type         
	,开业时间
	,CASE WHEN 闭店时间  IS NULL THEN curdate()+interval 365 day ELSE 闭店时间 END AS 闭店时间
 FROM(
 SELECT 
     A.robo_no           
	,A.robo_id            
	,A.robo_countiy    
    ,A.机器人名称
	,A.robo_ctiy          
	,A.robo_weizhi        
	,A.robo_level         
	,A.robo_weizhileixing 
	,A.robo_moshi           
	,A.robo_cs           
	,A.robo_type         
	,A.robo_begindate AS 开业时间
	,B.robo_begindate AS 闭店时间
    ,A.月份
FROM
(SELECT     robo_no           
	,robo_id            
	,robo_countiy    
    ,robo_countiy||'-'||robo_ctiy||'-'||robo_weizhi||'-'||robo_level||'-'||right(robo_id,3) AS 机器人名称
	,robo_ctiy          
	,robo_weizhi        
	,robo_level         
	,robo_weizhileixing 
	,robo_moshi        
	,robo_begindate    
	,robo_cs           
	,robo_type         
	,robo_date 
    ,left(REPLACE(robo_begindate,'-',''),6) AS 月份
    FROM SDS_INT.robo_zhushuju) A
	LEFT JOIN 
	(SELECT     robo_no           
	,robo_id            
	,robo_countiy    
    ,robo_countiy||'-'||robo_ctiy||'-'||robo_weizhi||'-'||robo_level||'-'||right(robo_id,3) AS 机器人名称
	,robo_ctiy          
	,robo_weizhi        
	,robo_level         
	,robo_weizhileixing 
	,robo_moshi        
	,robo_begindate    
	,robo_cs           
	,robo_type         
	,robo_date 
    ,left(REPLACE(robo_begindate,'-',''),6) AS 月份
    FROM SDS_INT.robo_zhushuju
	where robo_cs ='2') B
	ON A.robo_id=B.robo_id AND A.robo_cs+1 =B.robo_cs  
	)AA)
 SELECT
         机器人名称
    ,  人民币业绩
    ,  TRADE_COUNT
        ,SALE_COUNTRY
        ,robo_weizhileixing 
    ,  PRODUCT_COUNT
	,地区排名
  ,CASE 
WHEN 机器业绩跑赢百分比>=0.95  THEN 'S' 
WHEN 机器业绩跑赢百分比>=0.80 AND 机器业绩跑赢百分比<0.95  THEN 'A' 
WHEN 机器业绩跑赢百分比>=0.50 AND 机器业绩跑赢百分比<0.80  THEN 'B' 
WHEN 机器业绩跑赢百分比<0.50  THEN 'C' 
END AS 机器等级
FROM(
	SELECT 
        机器人名称
    ,  人民币业绩
      ,SALE_COUNTRY
  ,robo_weizhileixing 
    ,  TRADE_COUNT
    ,  PRODUCT_COUNT
	,地区排名
    ,CASE WHEN (地区机器数量-1)=0 THEN 0 ELSE (地区排名-1)*1/(地区机器数量-1) END AS 机器业绩跑赢百分比
	FROM(
	SELECT 
    机器人名称
           ,SALE_COUNTRY
      ,robo_weizhileixing 
    ,  人民币业绩
    ,  TRADE_COUNT
    ,  PRODUCT_COUNT
	,ROW_NUMBER() OVER(ORDER  BY  人民币业绩 DESC) AS 排名
      ,ROW_NUMBER() OVER(PARTITION BY SALE_COUNTRY ORDER  BY  月平均业绩 ASC) AS 地区排名
   ,COUNT(*) OVER (PARTITION BY SALE_COUNTRY) AS 地区机器数量
    FROM(
    	SELECT 
	机器人名称
        ,SALE_COUNTRY
      ,robo_weizhileixing 
      ,COUNT(DISTINCT LEFT(TRAN_DATE,7) ) AS 几月
   ,SUM(人民币业绩) AS      人民币业绩
    ,SUM(TRADE_COUNT) AS    TRADE_COUNT
    ,SUM(PRODUCT_COUNT) AS  PRODUCT_COUNT
      ,CASE WHEN COUNT(DISTINCT LEFT(TRAN_DATE,7) ) =0 THEN 0 ELSE 
      SUM(人民币业绩)/COUNT(DISTINCT LEFT(TRAN_DATE,7) ) END AS 月平均业绩
    FROM(
	SELECT 
	 robo_id            
	,robo_countiy    
    ,机器人名称
	,开业时间
	,闭店时间,
      robo_weizhileixing ,
	TRAN_DATE,
   国家地区,
    SUBSIDIARY_COUNTRY,
    robo_ctiy,
	SUBSIDIARY_CONTINENT,
	CUSTOMER_CODE,
	机器人ID,
    CUSOTMER_NAME_NS,
    CUSTOMER_CITY,
    CUSTOMER_COUNTRY,
    CUSTOMER_CONTINENT,
    CUSTOMER_CATEGORY,
    CUSTOMER_2ND_CAT_NAME,
    CUSTOMER_3ND_CAT_NAME,
    SALE_COUNTRY,
    SALE_CONTINENT,
    MANAGMENT_PERFORMANCE,
   人民币业绩,
    TRADE_COUNT,
    PRODUCT_COUNT,
    自营加盟
	FROM(
SELECT 
	TRAN_DATE,
   SALE_COUNTRY as 国家地区,
    SUBSIDIARY_COUNTRY,
	SUBSIDIARY_CONTINENT,
	CUSTOMER_CODE,
 
    机器人ID,
    CUSOTMER_NAME_NS,
    CUSTOMER_CITY,
    CUSTOMER_COUNTRY,
    CUSTOMER_CONTINENT,
    CUSTOMER_CATEGORY,
    CUSTOMER_2ND_CAT_NAME,
    CUSTOMER_3ND_CAT_NAME,
    SALE_COUNTRY,
    SALE_CONTINENT,
    MANAGMENT_PERFORMANCE,
     人民币业绩,
    TRADE_COUNT,
    PRODUCT_COUNT,
    自营加盟
 from temp_oversea_customer_income
    )A
	LEFT JOIN  
	JIQIRENZHUSHUJU B 
	ON B.robo_id=A.机器人ID AND A.TRAN_DATE>=B.开业时间 AND A.TRAN_DATE<=B.闭店时间
    )AAA
       WHERE  
 1=1 ${if(ZIYING == '',"","and  自营加盟 in ('" + ZIYING + "')")}
 GROUP BY  
 机器人名称
 )AAA
 )AA
 )AAA




 WITH  JIQIRENZHUSHUJU AS (SELECT     robo_no           
	,robo_id            
	,CASE WHEN robo_countiy  ='中国台湾' THEN '台湾,中国'  
                          WHEN robo_countiy  ='中国香港' THEN '香港,中国'  
                          ELSE robo_countiy END  AS robo_countiy
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
国家地区
,machine_id
,总货道数
,COUNT(DISTINCT sku) AS SKU数量
,SUM(空货道数)-SUM(坏货道) AS 空货道数
,SUM(坏货道)   AS 坏货道
,CASE WHEN  总货道数=0 or (SUM(空货道数)-S
UM(坏货道))<=0    
THEN 0 ELSE (SUM(空货道数)-SUM(坏货道))/总货道数 END AS 空货道率
,SUBSTR(取数时间,1,10) AS 取数时间BY天
,SUBSTR(取数时间,1,7) AS 取数时间BY月
,WEEK(取数时间) AS 取数时间BY周
,取数时间
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
WHEN custom_id in ('USA','USA-AH','USA_LA528') THEN '美国'
WHEN custom_id in ('CAN_SYoung','CAN','CAN_Token','CAN_Mindzai') THEN '加拿大'
END AS 国家地区,
  machine_id, -- 机器ID
  sku, -- SKU
  extract_time,
  COUNT(machine_id) OVER(PARTITION  BY machine_id,extract_time) AS 总货道数
  ,case when quantity=0 THEN 1 ELSE 0 END AS 空货道数
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
,取数时间)
SELECT 
robo_id            
	,robo_countiy    
    ,机器人名称
	,robo_ctiy   
,robo_moshi,	
 国家地区
,machine_id
,总货道数
,SKU数量
,空货道数
,坏货道
,空货道率
,取数时间BY天
,取数时间BY月
,取数时间BY周
,取数时间
FROM(
 SELECT 
 robo_id            
	,robo_countiy    
    ,机器人名称
	,robo_ctiy   
,robo_moshi  ,	
 国家地区
,machine_id
,总货道数
,SKU数量
,空货道数
,坏货道
,空货道率
,取数时间BY天
,取数时间BY月
,取数时间BY周
,取数时间
 FROM 
 JIQIRENZHUSHUJU  A
LEFT JOIN 
 konghuodaolv  B 
 ON A.robo_id=B.machine_id
    )AAA
   WHERE 
    1=1 ${if(GUOJIA == '',"","and  国家地区 in ('" + GUOJIA + "')")}	
 AND  
 1=1 ${if(ROBO_ID == '',"","and  robo_id in ('" + ROBO_ID + "')")} 
   AND  
 1=1 ${if(ziying == '',"","and  robo_moshi in ('" + ziying + "')")}   1240325062 