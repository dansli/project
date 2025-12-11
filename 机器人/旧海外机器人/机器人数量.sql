SELECT 
CURRENT_TIMESTAMP
AS 标题,
SUM(机器人在业数量) AS  机器人数量
,SUM(自营机器人)     AS 自营机器人
,SUM(加盟机器人)     AS 加盟机器人
,SUM(门店数量)       AS  门店数量
FROM(
SELECT 
robo_countiy AS 国家
,COUNT(DISTINCT robo_id) AS 机器人在业数量
,SUM(自营机器人) AS 自营机器人
,SUM(加盟机器人) AS 加盟机器人
,0 AS 门店数量
FROM(
SELECT     robo_no           
	,robo_id            
	,robo_countiy    
    ,robo_countiy||'-'||robo_ctiy||'-'||robo_weizhi||'-'||robo_level||'-'||right(robo_id,3) AS 机器人名称
	,robo_ctiy          
	,robo_weizhi        
	,robo_level    
    ,CASE WHEN (CASE WHEN robo_countiy='中国台湾' THEN '自营' ELSE robo_moshi END )='直营店'
	OR (CASE WHEN robo_countiy='中国台湾' THEN '自营' ELSE robo_moshi END) ='自营' THEN  1 ELSE 0 END   AS 自营机器人
	
	,CASE WHEN (CASE WHEN robo_countiy='中国台湾' THEN '自营' ELSE robo_moshi END) ='加盟'
	OR (CASE WHEN robo_countiy='中国台湾' THEN '自营' ELSE robo_moshi END) ='代运营' THEN  1 ELSE 0 END AS 加盟机器人
	,robo_weizhileixing 
	,robo_moshi        
	,robo_begindate    
	,robo_cs           
	,robo_type         
	,robo_date 
    ,left(REPLACE(robo_begindate,'-',''),6) AS 月份
    FROM SDS_INT.robo_zhushuju
   )AAA
WHERE robo_type='在业'
   GROUP BY 
   robo_countiy
 UNION  ALL   
   SELECT 
   md_country AS 国家
	,0 AS 机器人在业数量
	  ,0 AS 自营机器人
   ,0 AS 加盟机器人
	,COUNT( DISTINCT  md_name) AS 门店数量
  FROM( 
SELECT     md_name
  , md_type
  , zhiyingjiameng
  , md_cengji
  , md_mj
  , md_date
  , md_begiondate
  , md_enddate, 
md_level
  , md_country
  , md_city
  , md_dizhi
  , md_shenpi
  , md_xuyue
  , mde_xuyuedate
  , md_fuze
  , md_bumen
  , md_beizhu
  , md_kaiyetype
  , date_zuqi
  , Update_time, id
    FROM   SDS_INT.Calendar_mendian
  where md_kaiyetype= '在业'
)AAA
GROUP BY  
md_country
)AAA
