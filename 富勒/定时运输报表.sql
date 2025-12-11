select
  i.wmshd_orderno as 合单单号,
  i.orderno as 订单号,
  i.hd_orderno as 海鼎单号,
  i.warehouseId as 发货方代码,
  ii.warehouseDescr as 发货方名称,
  i.fh_province as 发货省,
  i.fh_city as 发货市,
  i.fh_district as 发货区,
  i.fh_address1 as 发货地址,
  i.consigneeId as 收货人ID,
  i.consigneeName as 收货人名称,
  i.sh_consigneeProvince as 收货省,
  i.sh_consigneeCity as 收货市,
  i.sh_consigneeDistrict as 收货区,
  i.sh_consigneeAddress1 as 收货地址,
  i.orderType as 单据类型,
  i.dl as 大类,
  i.QTY_EACH as 数量,
  i.sum_price as 总金额,
  FORMAT(i.sum_cube, 8) as 产品体积,
  FORMAT(i.sum_grossWeight, 8) as 产品重量,
  FORMAT(i.x_cube, 8) as 箱体积,
  FORMAT(i.x_grossWeight, 8) as 箱重量,
  -- FORMAT(i.x_cube_a, 8) AS x_cube_a,
  -- FORMAT(i.x_cartnWeight, 8) AS x_cartonWeight,
  i.xzsj as 创建时间,
  i.fhsj as 发货时间,
  i.ZT as 状态,
  i.addWho as 创建人,
  iii.codeDescr as 物流商,
  i.yssx as 运输时效,
  i.uom as 单位,
  i.pickToTraceId as 箱号,
  i.wldh as 物流单号,
  i.ZIDANHAO as 物流子单号,
  i.ddxs as 箱数,
  i.ysfy as 运输费用,
  i.jhfhtime as 计划发货,
  i.jhdhtime as 计划到货,
  i.sjthsjtime as 实际提货时间,
  i.sjqssjtime as 实际签收,
  i.sfcs as 是否超时,
  i.sfsh as 是否损坏,
  i.psje as 破损金额,
  i.lphk as 理赔回款,
  i.sfyyc as 是否有延迟,
  i.sfyts as 是否有投诉,
  i.EDISENDFLAG as 回传标记,
  i.cartonId as 标签号,
  i.cxtime as 记录时间,
  i.waveno as 波次单号
from
  tmp_ysbbds i
left join BSM_WAREHOUSE as ii 
on i.warehouseId=ii.warehouseId
left join BSM_CODE_ML as iii
on iii.codeId = i.route
where iii.codeType = 'ROU_COD' AND iii.languageId = 'zh_CN'
and i.cxtime between '${start_time}' and '${end_time}' -- 发货时间
${if(len(warehouseId)=0,""," and ii.warehouseId = '"+warehouseId+"'")} -- 仓库
${if(len(consigneeName)=0,""," and i.consigneeName = '"+consigneeName+"'")} -- 收货人名称
${if(len(wldh)=0,""," and i.wldh = '"+wldh+"'")} -- 物流单号
${if(len(codeId)=0,""," and iii.codeId in ('"+replace(codeId,"\n","','")+"')")} -- 物流商
${if(len(orderno)=0,""," and i.orderno = '"+orderno+"'")} -- WMS单号
${if(len(wmshd_orderno)=0,""," and i.wmshd_orderno = '"+wmshd_orderno+"'")} -- 合单单号
${if(len(waveno)=0,""," and i.waveno = '"+waveno+"'")} -- 波次单号
