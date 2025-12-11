SELECT
  B.customerId AS货主,
  GROUP_CONCAT(DISTINCT(B.orderNo))   AS 订单号,
  -- B.orderNo AS 订单号,
  B.udf05 AS 合并单号,
  GROUP_CONCAT(DISTINCT(B.SOREFERENCE1))   AS 海鼎单号,
  -- B.soReference1 
  BW.warehouseId AS 发货方代码,
  B.waveNo AS 波次号,
  BW.warehouseDescr AS 发货方名称,
  BW.province AS 发货省,
  BW.city AS 发货市,
  BW.district AS 发货区,
  BW.address1 AS 发货地址,
  B.consigneeId AS 收货人ID,
  B.consigneeName AS 收货人名称,
  B.consigneeProvince AS 收货省,
  B.consigneeCity AS 收货市,
  B.consigneeDistrict AS 收货区,
  B.consigneeAddress1 AS 收货地址,
  GROUP_CONCAT(DISTINCT(B.orderType ))  AS 单据类型,
  '' AS 大类,
  FORMAT( SUM( A.QTY_EACH ), 2 ) AS 数量,
  FORMAT( SUM( A.QTY_EACH * C.reservedField08 ), 2 ) AS 总金额,
  FORMAT( SUM( A.QTY_EACH * C.cube ) / 1000000, 8 ) AS 总体积,
  FORMAT( SUM( A.QTY_EACH * C.grossWeight ), 8 ) AS 总重量,
  -- ( CASE WHEN A.udf07 = 'Y' THEN FORMAT( SUM( A.cubic ) / 1000000, 8 ) ELSE FORMAT( SUM( A.QTY_EACH  * C.cube ) / 1000000, 8 )END ) AS 箱体积,
  -- ( CASE WHEN A.udf07 = 'Y' THEN FORMAT( SUM( A.QTY_EACH * C.grossWeight ), 8 ) ELSE FORMAT( SUM( A.QTY_EACH * C.grossWeight), 8 )  END ) AS 箱重量,
  ( CASE WHEN A.udf07 = 'Y' THEN FORMAT( (ifnull((BC.length*BC.width*BC.height),SUM( A.cubic ))) / 1000000, 8 ) ELSE FORMAT(  ifnull((BC.length*BC.width*BC.height),SUM( A.QTY_EACH  * C.cube)) / 1000000, 8 )  END ) AS 箱体积A,
  ( CASE WHEN A.udf07 = 'Y' THEN FORMAT( SUM(A.QTY_EACH * C.grossWeight )+ifnull(BC.cartonWeight,0), 8 ) ELSE FORMAT( SUM( A.QTY_EACH * C.grossWeight)+ifnull(BC.cartonWeight,0), 8 )  END ) AS 箱重量A,
  GROUP_CONCAT(DISTINCT(B.addTime))   AS 创建时间,
  -- B.addTime 
  GROUP_CONCAT(DISTINCT(B.editTime))   AS 发货时间,
  -- B.editTime 
  '已发货' AS 状态,
  GROUP_CONCAT(DISTINCT(B.addWho))   AS 创建人,
  -- B.addWho 
  B.route AS 物流商,
  ML.UDF03 AS 运输时效,
  CASE WHEN   B.orderType='ROB' THEN A.DROPID ELSE A.pickToTraceId END AS 箱号,
  case when A.uom in ('IP','EA') then 'EA' else A.uom end AS 单位,
  ifnull(A.udf02,'') AS 物流单号,
  E.订单箱数 AS 订单箱数,--
  '' AS 运输费用,
  '' AS 计划发货,
  '' AS 计划到货,
  '' AS 实际提货时间,
  GROUP_CONCAT(DISTINCT(D.Edisendtime))   AS 实际签收,
  -- D.Edisendtime AS 实际签收,
  '' AS 是否超时,
  '' AS 是否损坏,
  '' AS 破损金额,
  '' AS 理赔回款,
  '' AS 是否有延迟,
  '' AS 是否有投诉,
  A.EDISENDFLAG AS 回传标记 ,
  GROUP_CONCAT(DISTINCT(DS.cartonId))  as  cartonId ,DS.DELIVERYNO  AS 子单号
FROM
  fule.ACT_ALLOCATION_DETAILS A
  LEFT JOIN fule.DOC_ORDER_HEADER B ON A.organizationId = B.organizationId 
  AND A.warehouseId = B.warehouseId 
  AND A.orderNo = B.orderNo
LEFT JOIN (select co.organizationid,co.codetype,co.codedescr,co.udf03
  from fule.bsm_code_ml co
  left join fule.bsm_code bc
    on co.organizationid = bc.organizationid
   and co.codetype = bc.codetype
     and bc.codeid=co.codeid      

   where co.codetype='PPYSSX' and bc.organizationid='POP' 
  --  and bc.warehouseid =  ':WHID'
  and 1=1
   ${if(len(warehouseId)=0,""," and bc.warehouseid in ('"+replace(warehouseId,"\n","','")+"')")}
   )  ML
 ON B.organizationId=ML.organizationId
AND CONCAT(B.ROUTE,B.ConsigneeCity)=ML.codeDescr
AND ML.CODETYPE='PPYSSX'
  LEFT JOIN fule.doc_order_packing_summary DS on A.organizationid=DS.organizationid 
  AND A.warehouseid=DS.warehouseid  -- and A.orderno=DS.docno 
  and A.picktotraceid=DS.traceid
  left  join fule.bas_carton BC on DS.organizationId=BC.organizationId  and DS.cartonId=BC.cartonId
  LEFT JOIN fule.BSM_WAREHOUSE BW ON B.organizationId = BW.organizationId 
  AND B.warehouseId = BW.warehouseId
  LEFT JOIN fule.BAS_SKU C ON A.organizationId = C.organizationId 
  AND A.SKU = C.SKU 
  AND A.CUSTOMERID = C.CUSTOMERID
  LEFT JOIN fule.Logistics_receipt D ON A.organizationId = D.organizationId 
  AND A.udf02 = D.dropId
  LEFT JOIN (
  SELECT
    DOH.udf05,
    t0.warehouseId AS warehouseId,
    t0.organizationId AS organizationId,
    COUNT( DISTINCT ( t0.pickToTraceId ) ) AS 订单箱数 
  FROM
    fule.ACT_ALLOCATION_DETAILS t0 
    LEFT JOIN fule.DOC_ORDER_HEADER DOH ON DOH.organizationId = t0.organizationId 
    AND DOH.warehouseId = t0.warehouseId 
    AND DOH.orderno = t0.ORDERNO 
  WHERE
    t0.organizationId = 'POP' 
    -- AND t0.warehouseId = ':WHID' 
    -- and t0.customerid=':CUSTOMERID'
    AND 1=1 
    ${if(len(warehouseId)=0,""," and t0.warehouseId in ('"+replace(warehouseId,"\n","','")+"')")}
    ${if(len(customerid)=0,""," and t0.customerid in ('"+replace(customerid,"\n","','")+"')")}  
    AND DOH.edittime > DATE_SUB(date_format(now(),'%Y-%m-%d'), INTERVAL 180 DAY) 
    -- AND DATE_FORMAT( DOH.editTime, '%Y-%m-%d' ) >= ':TIME1' 
    -- AND DATE_FORMAT( DOH.editTime, '%Y-%m-%d' ) <= ':TIME2' 
    AND DATE_FORMAT(DOH.editTime, '%Y-%m-%d') between '${start_time}' and '${end_time}'
  GROUP BY
    DOH.udf05,
    t0.warehouseId,
    t0.organizationId 
  ) E ON E.organizationId = B.organizationId 
  AND E.warehouseId = B.warehouseId 
  AND E.udf05 = B.udf05 
WHERE
  B.SOSTATUS = '99' 
  AND B.organizationId = 'POP' 
  AND A.organizationId = 'POP' 
  AND B.route IN ( 'WD', 'DB', 'QT', 'XYY' ) 
  AND A.edittime > DATE_SUB(date_format(now(),'%Y-%m-%d'), INTERVAL 180 DAY) 
  AND B.edittime > DATE_SUB(date_format(now(),'%Y-%m-%d'), INTERVAL 180 DAY) 
  AND DATE_FORMAT(B.editTime, '%Y-%m-%d') between '${start_time}' and '${end_time}' -- 发货时间
  -- AND B.editTime >= DATE_FORMAT( ':TIME1', '%Y-%m-%d' ) 
  -- AND B.editTime <= DATE_FORMAT( ':TIME2', '%Y-%m-%d' ) 
  -- AND B.warehouseId = ':WHID' 
  -- AND A.warehouseId = ':WHID' 
  -- and B.customerid=':CUSTOMERID'
  -- AND B.consigneeName = ':SHR' 
  -- AND B.ROUTE = ':WL' 
  -- AND A.udf02 = ':WLDH' 
  -- AND  B.udf05  = ':udf05' 
  -- AND B.ORDERNO IN( ':WMSNO')
  AND  1 = 1
  ${if(len(warehouseId)=0,""," and B.warehouseId in ('"+replace(warehouseId,"\n","','")+"')")}
  ${if(len(warehouseId)=0,""," and A.warehouseId in ('"+replace(warehouseId,"\n","','")+"')")}
  ${if(len(customerid)=0,""," and B.customerid in ('"+replace(customerid,"\n","','")+"')")}
  ${if(len(consigneeName)=0,""," and B.consigneeName in ('"+replace(consigneeName,"\n","','")+"')")} -- 发货人名称
  ${if(len(ROUTE)=0,""," and B.ROUTE in ('"+replace(ROUTE,"\n","','")+"')")} -- 物流商
  ${if(len(deliveryNo)=0,""," and A.udf02 in ('"+replace(deliveryNo,"\n","','")+"')")} -- 物流单号
  ${if(len(udf05)=0,""," and B.udf05 in ('"+replace(udf05,"\n","','")+"')")} -- 合并单号
  ${if(len(ORDERNO)=0,""," and B.ORDERNO in ('"+replace(ORDERNO,"\n","','")+"')")} -- WMS单号
  ${if(len(waveno)=0,""," and B.waveno in ('"+replace(waveno,"\n","','")+"')")} -- 波次单号
  ${if(len(customerId)=0,""," and B.customerId in ('"+replace(customerId,"\n","','")+"')")}
  ${if(len(DELIVERYNOsub)=0,""," and DS.DELIVERYNO in ('"+replace(DELIVERYNOsub,"\n","','")+"')")}
GROUP BY
B.ORDERTYPE,
  B.customerId,
  B.consigneeId,-- DS.cartonId,
  BC.length,
  BC.width,
  BC.height,
  BC.cartonWeight,
  B.udf05 ,
  B.consigneeName,
  -- B.editTime,
  -- B.orderNo,
B.waveNo,
  A.pickToTraceId,
A.DROPID,
  case when A.uom in ('IP','EA') then 'EA' else A.uom end,
  B.ROUTE,
  B.soReference1,
  B.consigneeProvince,
  B.consigneeCity,
  B.consigneeDistrict,
  B.consigneeAddress1,
  -- B.orderType,
  -- B.addTime,
  -- B.addWho,
  ifnull(A.udf02,''),
  -- D.Edisendtime,
  E.订单箱数,
  BW.warehouseId,
  BW.warehouseDescr,
  BW.province,
  BW.city,
  BW.district,
  BW.address1,
  A.EDISENDFLAG,
  A.udf07 ,
ML.UDF03,DS.DELIVERYNO
UNION
SELECT
  B.customerId  AS货主,
  GROUP_CONCAT(DISTINCT(B.orderNo))   AS 订单号,
  B.udf05 AS 合并单号,
  GROUP_CONCAT(DISTINCT(B.SOREFERENCE1))   AS 海鼎单号,
  BW.warehouseId AS 发货方代码,
  B.waveNo AS 波次号,
  BW.warehouseDescr AS 发货方名称,
  BW.province AS 发货省,
  BW.city AS 发货市,
  BW.district AS 发货区,
  BW.address1 AS 发货地址,
  B.consigneeId AS 收货人ID,
  B.consigneeName AS 收货人名称,
  B.consigneeProvince AS 收货省,
  B.consigneeCity AS 收货市,
  B.consigneeDistrict AS 收货区,
  B.consigneeAddress1 AS 收货地址,
  GROUP_CONCAT(DISTINCT(B.orderType ))  AS 单据类型,
  '' AS 大类,
  FORMAT( SUM( A.QTY_EACH ), 2 ) AS 数量,
  FORMAT( SUM( A.QTY_EACH * C.reservedField08 ), 2 ) AS 总金额,
  FORMAT( SUM( A.QTY_EACH * C.cube ) / 1000000, 8 ) AS 总体积,
  FORMAT( SUM( A.QTY_EACH * C.grossWeight ), 8 ) AS 总重量,
  -- ( CASE WHEN A.udf07 = 'Y' THEN FORMAT( SUM( A.cubic ) / 1000000, 8 ) ELSE FORMAT( SUM( A.QTY_EACH  * C.cube ) / 1000000, 8 )  END ) AS 箱体积,
 -- ( CASE WHEN A.udf07 = 'Y' THEN FORMAT( SUM( A.QTY_EACH * C.grossWeight ), 8 ) ELSE FORMAT( SUM( A.QTY_EACH * C.grossWeight), 8 )  END ) AS 箱重量,
  ( CASE WHEN A.udf07 = 'Y' THEN FORMAT( (ifnull((BC.length*BC.width*BC.height),SUM( A.cubic ))) / 1000000, 8 ) ELSE FORMAT(  ifnull((BC.length*BC.width*BC.height),SUM( A.QTY_EACH  * C.cube)) / 1000000, 8 )  END ) AS 箱体积A,
  ( CASE WHEN A.udf07 = 'Y' THEN FORMAT( SUM( A.QTY_EACH * C.grossWeight )+ifnull(BC.cartonWeight,0), 8 ) ELSE FORMAT( SUM( A.QTY_EACH * C.grossWeight)+ifnull(BC.cartonWeight,0), 8 )  END ) AS 箱重量A,
  GROUP_CONCAT(DISTINCT(B.addTime))   AS 创建时间,
  GROUP_CONCAT(DISTINCT(B.editTime))   AS 发货时间,
  '已发货' AS 状态,
  GROUP_CONCAT(DISTINCT(B.addWho))   AS 创建人,
  B.route AS 物流商,
   ML.UDF03 AS 运输时效,
  case when  B.orderType='ROB' THEN A.DROPID ELSE A.pickToTraceId END  AS 箱号,
  case when A.uom in ('IP','EA') then 'EA' else A.uom end AS 单位,
  (CASE WHEN B.route IN ('SF','SFBKLD') THEN DOD1.mainDeliveryNo ELSE B.deliveryNo END) AS 物流单号,
  E.订单箱数 AS 订单箱数,
  '' AS 运输费用,
  '' AS 计划发货,
  '' AS 计划到货,
  '' AS 实际提货时间,
  GROUP_CONCAT(DISTINCT(D.Edisendtime))   AS 实际签收,

  '' AS 是否超时,
  '' AS 是否损坏,
  '' AS 破损金额,
  '' AS 理赔回款,
  '' AS 是否有延迟,
  '' AS 是否有投,
  B.EDISENDFLAG2 AS 回传标记 ,
  GROUP_CONCAT(DISTINCT(DS.cartonId))  as  cartonId,CASE  WHEN DS.DELIVERYNO  = A.pickToTraceId   THEN '' ELSE DS.DELIVERYNO  END     AS 子单号
FROM
  fule.ACT_ALLOCATION_DETAILS A
  LEFT JOIN fule.DOC_ORDER_HEADER B ON A.organizationId = B.organizationId 
  AND A.warehouseId = B.warehouseId 
  AND A.orderNo = B.orderNo
LEFT JOIN  fule.doc_order_deliveryinfo  DOD1   
  ON
a.organizationId = DOD1.organizationId
AND a.warehouseId = DOD1.warehouseId
AND A.PICKTOTRACEID = DOD1.orderno

LEFT JOIN (select co.organizationid,co.codetype,co.codedescr,co.udf03
  from fule.bsm_code_ml co
  left join fule.bsm_code bc
    on co.organizationid = bc.organizationid
   and co.codetype = bc.codetype
     and bc.codeid=co.codeid      

   where co.codetype='PPYSSX' and bc.organizationid='POP' 
  --  and bc.warehouseid =  ':WHID'
   and 1=1
   ${if(len(warehouseId)=0,""," and bc.warehouseid in ('"+replace(warehouseId,"\n","','")+"')")}
   )  ML
ON B.organizationId=ML.organizationId
AND CONCAT(B.ROUTE,B.ConsigneeCity)=ML.codeDescr AND ML.CODETYPE='PPYSSX'
  LEFT JOIN fule.doc_order_packing_summary DS on A.organizationid=DS.organizationid 
  AND A.warehouseid=DS.warehouseid  -- and A.orderno=DS.docno 
  and A.picktotraceid=DS.traceid
  left  join fule.bas_carton BC on DS.organizationId=BC.organizationId  
  and DS.cartonId=BC.cartonId
  LEFT JOIN fule.BSM_WAREHOUSE BW ON B.organizationId = BW.organizationId 
  AND B.warehouseId = BW.warehouseId
  LEFT JOIN fule.BAS_SKU C ON A.organizationId = C.organizationId 
  AND A.SKU = C.SKU 
  AND A.CUSTOMERID = C.CUSTOMERID
  LEFT JOIN fule.Logistics_receipt D ON B.organizationId = D.organizationId 
  AND B.deliveryNo = D.dropId
  LEFT JOIN (
  SELECT
    DOH.udf05,
    DOH.deliveryNo AS deliveryNo,
    t0.warehouseId AS warehouseId,
    t0.organizationId AS organizationId,
    COUNT( DISTINCT ( t0.pickToTraceId ) ) AS 订单箱数 
  FROM
    fule.ACT_ALLOCATION_DETAILS t0
    LEFT JOIN fule.DOC_ORDER_HEADER DOH ON DOH.organizationId = t0.organizationId 
    AND DOH.warehouseId = t0.warehouseId 
    AND DOH.orderno = t0.orderno 
  WHERE
    t0.organizationId = 'POP' 
    -- AND t0.warehouseId = ':WHID' 
    -- and t0.customerid=':CUSTOMERID'
    AND DOH.edittime > DATE_SUB(date_format(now(),'%Y-%m-%d'), INTERVAL 180 DAY) 
    -- AND DOH.editTime >= DATE_FORMAT( ':TIME1', '%Y-%m-%d' ) 
    -- AND DOH.editTime <= DATE_FORMAT( ':TIME2', '%Y-%m-%d' ) 
    AND DATE_FORMAT(DOH.editTime, '%Y-%m-%d') between '${start_time}' and '${end_time}'
    AND 1=1 
    ${if(len(warehouseId)=0,""," and t0.warehouseId in ('"+replace(warehouseId,"\n","','")+"')")}
    ${if(len(customerid)=0,""," and t0.customerid in ('"+replace(customerid,"\n","','")+"')")}    
  GROUP BY
    DOH.udf05,
    DOH.deliveryNo,
    t0.warehouseId,
    t0.organizationId 
  ) E ON E.organizationId = B.organizationId 
  AND E.warehouseId = B.warehouseId 
  AND B.deliveryNo = E.deliveryNo 
  AND B.udf05 = E.udf05 
WHERE
  B.SOSTATUS = '99'  
  AND B.organizationId = 'POP' 
  AND A.organizationId = 'POP' 
  AND A.edittime > DATE_SUB(date_format(now(),'%Y-%m-%d'), INTERVAL 180 DAY) 
  AND B.edittime > DATE_SUB(date_format(now(),'%Y-%m-%d'), INTERVAL 180 DAY) 
  AND (B.route IN ( 'CF', 'KY', 'JD','SF','SFKH','SFBKLD','CFBJ','CFTJ','CFZJ','CFJS','CFSH','BS','BSWF','BSTJ','BSBJ','ZTO','CFHB','','HWKD','4PXI','SFI'
  ,'DHLI','TIKTOKI','SHOPEEI','LAZADAI','SMTI','YWI','VIRTUALI','OTHERI','UPSI','TikTokI','ShopeeI','LazadaI','virtualI','YUNI')  OR B.ROUTE IS NULL)
  AND DATE_FORMAT(B.editTime, '%Y-%m-%d') between '${start_time}' and '${end_time}'
  AND  1 = 1
${if(len(warehouseId)=0,""," and B.warehouseId in ('"+replace(warehouseId,"\n","','")+"')")}
${if(len(warehouseId)=0,""," and A.warehouseId in ('"+replace(warehouseId,"\n","','")+"')")}
${if(len(customerid)=0,""," and B.customerid in ('"+replace(customerid,"\n","','")+"')")}
${if(len(consigneeName)=0,""," and  B.consigneeName in ('"+replace(consigneeName,"\n","','")+"')")}
${if(len(ROUTE)=0,""," and B.ROUTE in ('"+replace(ROUTE,"\n","','")+"')")}
-- ${if(len(deliveryNo)=0,""," and B.deliveryNo in ('"+replace(deliveryNo,"\n","','")+"')")}
-- ${if(len(mainDeliveryNo)=0,""," and DOD1.mainDeliveryNo in ('"+replace(mainDeliveryNo,"\n","','")+"')")}
${if(len(udf05)=0,""," and B.udf05 in ('"+replace(udf05,"\n","','")+"')")}
${if(len(ORDERNO)=0,""," and B.ORDERNO in ('"+replace(ORDERNO,"\n","','")+"')")}
${if(len(waveno)=0,""," and B.waveno in ('"+replace(waveno,"\n","','")+"')")}
${if(len(customerId)=0,""," and B.customerId in ('"+replace(customerId,"\n","','")+"')")}
${if(len(DELIVERYNOsub)=0,""," and DS.DELIVERYNO in ('"+replace(DELIVERYNOsub,"\n","','")+"')")}
${if(len(deliveryNo)=0,"",
" and (
   ((B.route in ('SF','SFBKLD') and DOD1.maindeliveryno is not null) and DOD1.mainDeliveryNo in ('" + replace(deliveryNo,"\n","','") + "'))  
   or
   ((B.route not in ('SF','SFBKLD') or (B.route in ('SF','SFBKLD') and DOD1.maindeliveryno is null)) and B.deliveryNo in ('" + replace(deliveryNo,"\n","','") + "'))
)")}

-- ${if(len(deliveryNo)=0,"",
-- " and (
--    (B.route in ('SF','SFBKLD') and DOD1.mainDeliveryNo in ('" + replace(deliveryNo,"\n","','") + "'))
--    or
--    (B.route not in ('SF','SFBKLD') and B.deliveryNo in ('" + replace(deliveryNo,"\n","','") + "'))
-- )")}

--   AND B.editTime >= DATE_FORMAT( ':TIME1', '%Y-%m-%d' ) 
--   AND B.editTime <= DATE_FORMAT( ':TIME2', '%Y-%m-%d' ) 
--   AND B.warehouseId = ':WHID' 
--   and B.customerid=':CUSTOMERID'
--   AND A.warehouseId = ':WHID' 
--   AND B.consigneeId = ':SHR' 
--   AND B.ROUTE = ':WL' 
--   AND B.udf05  = ':udf05' 

-- --  AND B.deliveryNo = ':WLDH' 
-- AND    (CASE WHEN B.route IN ('SF','SFBKLD') THEN DOD1.mainDeliveryNo=':WLDH' ELSE B.deliveryNo=':WLDH' END) 
--   AND B.ORDERNO IN( ':WMSNO')
GROUP BY
 B.ORDERTYPE,
  B.customerId,
  B.consigneeId,-- DS.cartonId,
  BC.length,
  BC.width,
  BC.height,
  BC.cartonWeight,
  B.consigneeName,-- DOH.udf05,
  -- B.editTime,
  -- B.orderNo,
  B.waveNo,
  B.udf05,
  A.pickToTraceId,
A.DROPID,
  case when A.uom in ('IP','EA') then 'EA' else A.uom end,
  B.ROUTE,
  -- B.soReference1,
  B.consigneeProvince,
  B.consigneeCity,
  B.consigneeDistrict,
  B.consigneeAddress1,
  -- B.orderType,
  -- B.addTime,
  -- B.addWho,
   (CASE WHEN B.route IN ('SF','SFBKLD') THEN DOD1.mainDeliveryNo ELSE B.deliveryNo END) ,
  -- D.Edisendtime,
  E.订单箱数,
  BW.warehouseId,
  BW.warehouseDescr,
  BW.province,
  BW.city,
  BW.district,
  BW.address1,
  B.EDISENDFLAG2,
  A.udf07  ,
ML.UDF03,DS.DELIVERYNO