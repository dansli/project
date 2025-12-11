SELECT
a.warehouseId as 仓库代码,
a.addWho as 操作人,
a.fmCustomerId as 货主,
a.toSku as 产品代码,
b.udf03 as 是否隐藏,
a.docNo as ASN编号,
f.ASNtype as ASN类型,
t3.codeDescr as 导出库存状态,
a.docLineNo as ASN行号,
DATE_FORMAT(f.asnCreationTime, '%Y-%m-%d %T') as 创建时间,
f.issuePartyName as 订单渠道,
DATE_FORMAT(a.transactionTime, '%Y-%m-%d %T') as 入库时间,
DATE_FORMAT(t2.putawayDate, '%Y-%m-%d %T') as 上架时间,
b.skuDescr1 as 产品描述L,
b.skuDescr2 as 产品描述S,
b.freightClass as 货类,
b.packId as 包装,
t.packUom as 单位,
b.sku_group1 as 系列代码,
sum(a.toQty_Each) / t.qty as 数量,
b.sku_group4 as 盒规,
sum(a.totalCubic) as 体积,
b.sku_group3 as 箱规,
sum(a.totalGrossWeight) as 重量,
f.udf01 as 售后原因1,
f.udf02 as 自定义02,
f.udf04 as 三方渠道,
f.udf05 as 自定义05,
f.noteText as 备注,
dod.dedi07 as 售后原因2,
f.carrierId as 承运人,
f.carrierName as 承运人名称,
f.supplierId as 供应商代码,
f.supplierName as 供应商姓名,
f.asnReference1 as 参考编号1,
f.asnReference3 as 参考编号3,
f.asnReference2 as 参考编号2,
f.asnReference4 as 参考编号4,
f.asnReference5 as 参考编号5,
d.lotAtt05 as 盲盒拆零件，
d.lotAtt06 as 唯一码，
d.lotAtt08 as 库存状态，
d.lotAtt09 as 快递单号
FROM
fule.ACT_TRANSACTION_LOG a
LEFT OUTER JOIN fule.BAS_CUSTOMER tt
ON
tt.organizationId = a.organizationId
AND tt.CustomerID = a.ToCustomerID
AND tt.customerType = 'OW'
LEFT OUTER JOIN fule.BAS_SKU b
ON
b.organizationId = a.organizationId
AND b.customerId = a.toCustomerId
AND b.sku = a.toSku
LEFT OUTER JOIN fule.BAS_CUSTOMERFREIGHT e
ON
e.organizationId = b.organizationId
AND e.customerId = b.customerId
AND e.freightCode = b.freightClass
LEFT JOIN fule.BAS_PACKAGE_DETAILS t
ON
tt.organizationId = t.organizationId
AND tt.customerId = t.customerId
AND tt.defaultReportUom = t.packUom
AND b.packId = t.packId
LEFT OUTER JOIN fule.BAS_PACKAGE c
ON
c.organizationId = b.organizationId
AND c.customerId = b.customerId
AND c.PackID = b.PackID
LEFT OUTER JOIN fule.INV_LOT_ATT d
ON
d.organizationId = a.organizationId
AND d.lotNum = a.toLotNum
LEFT OUTER JOIN fule.DOC_ASN_HEADER f
ON
f.organizationId = a.organizationId
AND f.warehouseId = a.warehouseId
AND f.asnNo = a.docNo
LEFT JOIN fule.BSM_CODE_ML t1
ON
f.organizationId = t1.organizationId
AND t1.codeType = 'ASN_TYP'
AND f.asnType = t1.codeId
AND t1.languageId = 'zh_CN'
LEFT JOIN
(
SELECT
aa.organizationId,
aa.warehouseId,
aa.docNo,
MAX(transactionTime) putawayDate
FROM
fule.ACT_TRANSACTION_LOG aa
WHERE
aa.transactionType = 'PA'
AND aa.STATUS = '99'
AND aa.organizationId = 'POP'
AND aa.warehouseId IN ('DGBP', 'DONGG', 'NANJ', 'TIANJ')
AND aa.organizationId = 'POP'
GROUP BY
aa.organizationId,
aa.warehouseId,
aa.docNo
)
t2
ON
a.organizationId = t2.organizationId
AND a.warehouseId = t2.warehouseId
AND a.docNo = t2.docNo
LEFT JOIN fule.BSM_CODE_ML t3
ON
1 = 1
AND a.organizationId = t3.organizationId
AND d.organizationId = t3.organizationId
AND d.lotatt08 = t3.codeid
AND t3.codetype = 'DMG_FLG03'
LEFT JOIN fule.DOC_ASN_DETAILS dod
ON
1 = 1
AND a.organizationId = dod.organizationId
AND a.warehouseId = dod.warehouseId
AND a.docno = dod.asnno
AND a.tosku = dod.sku
AND A.DOCLINENO = DOD.ASNLINENO
WHERE
a.transactionType = 'IN'
AND a.status = '99'
AND a.organizationId = 'POP'
AND a.warehouseId IN('DGBP', 'DONGG', 'NANJ', 'TIANJ')
and a.transactionTime between '${start_time}' and '${end_time}' -- 收货时间
${if(len(fmCustomerId)=0,""," and a.fmCustomerId = '"+fmCustomerId+"'")} -- 货主
${if(len(warehouseId)=0,""," and a.warehouseId = '"+warehouseId+"'")} -- 仓库代码
${if(len(ASNtype)=0,""," and f.ASNtype = '"+ASNtype+"'")} -- ASN类型
${if(len(freightClass)=0,""," and b.freightClass in ('"+replace(freightClass,"\n","','")+"')")} -- 货类
${if(len(asnNo)=0,""," and f.asnNo = '"+asnNo+"'")} -- 预期到货通知编码
${if(len(sku)=0,""," and b.sku in ('"+replace(sku,"\n","','")+"')")} -- 产品
AND 1 = 1
GROUP BY
a.warehouseId,
a.addWho,
a.fmCustomerId,
a.toSku,
b.udf03,
a.docNo,
t1.codeDescr,
t3.codeDescr,
a.docLineNo,
f.asnCreationTime,
f.issuePartyName,
a.transactionTime,
t2.putawayDate,
b.skuDescr1,
b.skuDescr2,
b.freightClass,
b.packId,
t.packUom,
b.sku_group1,
b.sku_group4,
b.sku_group3,
f.udf01,
f.udf02,
f.udf04,
f.udf05,
f.noteText,
dod.dedi07,
f.carrierId,
f.carrierName,
f.supplierId,
f.supplierName,
f.asnReference1,
f.asnReference3,
f.asnReference2,
f.asnReference4,
f.asnReference5,
d.lotAtt05,
d.lotAtt06,
d.lotAtt08,
d.lotAtt09,
t.qty
