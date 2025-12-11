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
,CASE WHEN  总货道数=0 or (SUM(空货道数)-SUM(坏货道))<=0    THEN 0 ELSE (SUM(空货道数)-SUM(坏货道))/总货道数 END AS 空货道率
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
WHEN custom_id in ('POPMART_TAIWAN','TAIWAN-temporary') THEN'中国台湾'
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
WHEN custom_id in ('Germany') THEN '德国'
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
  WHEN  custom_id IN('FRANCE-SOGEEK','France','Germany')
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
,'USA','USA-AH','CAN_SYoung','CAN','USA_LA528','CAN_Token','CAN_Mindzai'               ,'TAIWAN-temporary','Germany'        
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
 1=1 ${if(ziying == '',"","and  robo_moshi in ('" + ziying + "')")} 