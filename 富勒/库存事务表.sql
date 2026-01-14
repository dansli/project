SELECT
   h1.warehouseId AS 仓库编号,
   h1.editWho AS 操作人,
   h2.lotAtt08 AS 库存状态,
   h1.transactionId AS 事务编号,
   l1.codedescr AS 事务类型,
   l3.codedescr AS 单证类型,
   h1.docLineNo AS 行号,
   l2.codedescr AS 事务状态,
   DATE_FORMAT(h1.transactionTime, '%Y-%m-%d %T') AS 事务时间,
   h1.docNo AS 单证编号,
   DOH.soReference1 AS 出库海鼎单号,
   ASN_HEADER.asnReference1 AS 入库海鼎单号,
   h1.fmCustomerId AS FM货主,
   h1.fmSku AS FM产品,
   h3.skuDescr1 AS 产品描述,
   h3.freightClass AS 货物类型,
   J1.freightDescr1 AS 货物描述,
   h1.fmLotNum AS FM批次,
   h1.fmLocation AS FM库位,
   h1.fmMuid AS FM_MUID,
   h1.fmId AS FM跟踪号,
   h1.fmPackId AS FM包装代码,
   h1.fmUom AS FM单位,
   h1.fmQty AS FM单位数量,
   h1.fmQty_Each AS FM主单位数量,
   h1.toCustomerId AS TO_货主,
   h1.toSku AS TO_产品,
   h1.toLotNum AS TO_批次,
   h1.toLocation AS TO_库位,
   h1.toMuid AS TO_MUID,
   h1.toId AS TO_跟踪号,
   h1.toPackId AS TO_包装代码,
   h1.toUom AS TO_单位,
   h1.toQty AS TO_单位数量,
   h1.toQty_Each AS TO_主单位数量,
   CASE WHEN h1.totalNetWeight < 0 THEN 0 ELSE h1.totalNetWeight END AS 净重,
   CASE WHEN h1.totalGrossWeight < 0 THEN 0 ELSE h1.totalGrossWeight END AS 毛重,
   CASE WHEN h1.totalCubic < 0 THEN 0 ELSE h1.totalCubic END AS 体积,
   DATE_FORMAT(h1.editTime, '%Y-%m-%d %T') AS 系统时间,
   h1.operator AS 操作人
FROM
fule.ACT_TRANSACTION_LOG h1
LEFT JOIN fule.BSM_CODE_ML l1
ON
h1.organizationId = l1.organizationId
AND l1.languageId = 'zh_CN'
AND l1.codeType = 'TRN_TYP'
AND h1.transactionType = l1.codeId
LEFT JOIN fule.BSM_CODE_ML l2
ON
h1.organizationId = l2.organizationId
AND l2.languageId = 'zh_CN'
AND l2.codeType = 'TRN_STS'
AND h1.status = l2.codeId
LEFT JOIN BSM_CODE_ML l3
ON
h1.organizationId = l3.organizationId
AND l3.languageId = 'zh_CN'
AND l3.codeType = 'DOC_TYP'
AND h1.docType = l3.codeId
LEFT JOIN fule.INV_LOT_ATT h2
ON
h1.organizationId = h2.organizationId
AND h1.fmCustomerId = h2.customerId
AND h1.fmLotnum = h2.lotNum
LEFT JOIN fule.INV_LOT_ATT h4
ON
h1.organizationId = h4.organizationId
AND h1.toCustomerId = h4.customerId
AND h1.toLotnum = h4.lotNum
LEFT JOIN fule.BAS_SKU h3
ON
h1.organizationId = h3.organizationId
AND h1.fmSku = h3.sku
AND h1.fmCustomerId = h3.customerId
LEFT JOIN fule.BSM_USER b1
ON
1 = 1
AND h1.organizationId = b1.organizationId
AND h1.addWho = b1.USERID
LEFT JOIN fule.BAS_CUSTOMERFREIGHT J1
ON
1 = 1
AND h1.organizationId = J1.organizationId
AND J1.freightCode = h3.freightClass
AND J1.CustomerId = h3.CustomerId
LEFT JOIN fule.DOC_ORDER_HEADER DOH
ON
1 = 1
AND h1.organizationId = DOH.organizationId
AND h1.warehouseId = DOH.warehouseId
AND DOH.ORDERNO = h1.DOCNO
LEFT JOIN fule.DOC_ASN_HEADER ASN_HEADER
ON
1 = 1
AND h1.organizationId = ASN_HEADER.organizationId
AND h1.warehouseId = ASN_HEADER.warehouseId
AND ASN_HEADER.asnNo = h1.DOCNO
WHERE
1 = 1
AND h1.organizationId = 'POP'
AND
(
h1.warehouseId IN('DGBP', 'DONGG', 'NANJ', 'TIANJ')
OR h1.warehouseId = '*'
)
AND DATE_FORMAT(h1.transactionTime, '%Y-%m-%d %T')>='2026-01-01 00:00:00'
AND DATE_FORMAT(h1.transactionTime, '%Y-%m-%d %T')<='2026-01-09 00:00:00'
AND 1 = 1