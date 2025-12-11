CREATE VIEW ns.zods_taxline AS 
SELECT DISTINCT
  tr.id transactionid
, tr.trandate
, tr.tranid
, itemtype
, tr.recordtype
, trl.isinventoryaffecting
, trl.IsCogs
, trl.item
, trl.foreignamount
FROM ns.transactionline trl
LEFT JOIN ns.transaction tr ON tr.id = trl.TRANSACTION 
WHERE ((((itemtype IN ('TaxItem', 'TaxGroup')) 
  AND (tr.recordtype IN ('invoice', 'creditmemo', 'salesorder', 'returnauthorization'))) 
  AND (trl.isinventoryaffecting = 'F')) 
  AND (trl.IsCogs = 'F')) 
  AND (trl.netamount <> 0)
