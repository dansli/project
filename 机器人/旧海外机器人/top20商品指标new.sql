with temp_oversea_detail as (
    select 
    SALE_COUNTRY,
    ITEM_CODE,
    ITEM_NAME,
     CUSTOMER_2ND_CAT_NAME,
    customer_name,
    REGEXP_SUBSTR(customer_name, 'R[A-Z0-9]{2}-[A-Z0-9]{4}', 1, 1) AS 机器人,
    CASE WHEN  IS_TARGET =1  THEN PRODUCT_COUNT ELSE 0 END                           AS 销售商品总数量,
    CASE WHEN  IS_TARGET =1  THEN RMB_AMOUNT ELSE 0 END                              AS 销售商品总金额,
     CASE WHEN CUSTRECORD_BI_BUDGET_ORDER_TYPE=1   AND   CUSTOMER_2ND_CAT_NAME IN ('ROBOshop') THEN PRODUCT_COUNT ELSE 0 END  AS 机器人销售商品总数量,
          CASE WHEN CUSTRECORD_BI_BUDGET_ORDER_TYPE=1   AND   CUSTOMER_2ND_CAT_NAME IN ('ROBOshop') THEN RMB_AMOUNT ELSE 0 END     AS 机器人销售商品总金额
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
      1=1 ${if(GUOJIA == '',"","and  SALE_COUNTRY in ('" + GUOJIA + "')")}	 
    )
    ,
    
    
    JIQINEIBUKUCUN AS (
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
  END AS 国家地区,
    machine_id, -- 机器ID
    sku, -- SKU
    quantity,
    extract_time,
    COUNT(machine_id) OVER(PARTITION  BY machine_id,extract_time) AS 总货道数
    ,case when quantity=0 THEN 1 ELSE 0 END AS 空货道数
    ,CASE WHEN state<>'occupied' THEN 1 ELSE 0 END AS 坏货道
    ,extract_time 
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
  ))
  ,
  

 
  
  
  SHANGJISHANGPIN AS (
  SELECT
  国家地区,
    machine_id, -- 机器ID
    sku, -- SKU
  数量
  FROM(
  SELECT A.国家地区,
    A.machine_id, -- 机器ID
    sku, -- SKU
    SUM(quantity) AS 数量
    FROM  
  JIQINEIBUKUCUN A 
    INNER  JOIN 
   (SELECT 国家地区,
  machine_id,extract_time FROM  
  JIQINEIBUKUCUN WHERE 
LEFT(取数时间,10) = LEFT('${end}',10) 
               GROUP  BY  
             国家地区  ,
  machine_id  
               ) B 
    ON  A.国家地区=B.国家地区 AND A.machine_id=B.machine_id
  WHERE   sku is not null 
  GROUP  BY  
  A.国家地区,
    A.machine_id, -- 机器ID
    sku
    )AAA
    HAVING 数量 > 0
    )
  
  
  
  
  
  
    SELECT 
    A.SALE_COUNTRY,
    A.ITEM_CODE,
    A.ITEM_NAME,
     销售商品总数量,
     销售商品总金额,
    机器人销售商品总数量,
    机器人销售商品总金额,
       销售占比,
    商品排名,
    机器人总数量,
    ISNULL(机器人数量,0) 上机机器人数量,
      机器人总数量-ISNULL(机器人数量,0) AS 有货未上机数,
      case when 机器人总数量=0 then 0 else ISNULL(机器人数量,0)/机器人总数量 end  AS 上级率
    FROM(
  SELECT 
    SALE_COUNTRY,
    ITEM_CODE,
    ITEM_NAME,
     销售商品总数量,
     销售商品总金额,
    机器人销售商品总数量,
    机器人销售商品总金额,
      CASE WHEN 销售商品总数量=0 THEn 0 ELSE 机器人销售商品总数量/销售商品总数量 END  AS 销售占比,
    商品排名
    FROM(
  SELECT 
      SALE_COUNTRY,
    ITEM_CODE,
    ITEM_NAME,
     销售商品总数量,
     销售商品总金额,
    机器人销售商品总数量,
    机器人销售商品总金额,
     ROW_NUMBER() OVER(PARTITION BY  SALE_COUNTRY ORDER BY 销售商品总数量 DESC) AS 商品排名
  FROM(
  select 
    SALE_COUNTRY,
    ITEM_CODE,
    ITEM_NAME,
    SUM(销售商品总数量) AS 销售商品总数量,
    SUM(销售商品总金额) AS 销售商品总金额,
    SUM(机器人销售商品总数量) AS 机器人销售商品总数量,
    SUM(机器人销售商品总金额) AS 机器人销售商品总金额
    
  from 
    temp_oversea_detail
    GROUP BY 
    SALE_COUNTRY,
    ITEM_CODE,
    ITEM_NAME
    )AAA
      WHERE 销售商品总金额>0 AND 机器人销售商品总金额>0
    )aaa
    WHERE 商品排名<=20
    )A
    LEFT JOIN (
   SELECT 
    国家地区,
    itemid,
    COUNT(DISTINCT machine_id) AS 机器人数量
    FROM(
  SELECT
  国家地区,
  sku,
    machine_id
    ,itemid,
  displayname 
    FROM  
      SHANGJISHANGPIN  A 
      LEFT JOIN (
  SELECT  custitem_pm_item_main_barcode,
  itemid,
  displayname  FROM NS.ITEM) B  
  ON A.sku=B.custitem_pm_item_main_barcode
  )AAA
  GROUP  BY  
   国家地区,
    itemid)  B
    ON  A.SALE_COUNTRY=B.国家地区 AND A.ITEM_CODE=B.itemid
  LEFT JOIN  
  (select 
    SALE_COUNTRY,
    COUNT(DISTINCT customer_name) AS 机器人总数量	
  from 
    temp_oversea_detail
    WHERE CUSTOMER_2ND_CAT_NAME IN ('ROBOshop') 
    GROUP BY 
    SALE_COUNTRY) C
    ON  A.SALE_COUNTRY=C.SALE_COUNTRY
    WHERE  
   1=1 ${if(CODE == '',"","and  A.ITEM_CODE in ('" + CODE + "')")}	 
    ORDER BY  
   A. SALE_COUNTRY,
   商品排名
  
  
  

  