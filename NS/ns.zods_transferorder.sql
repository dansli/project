 CREATE VIEW `ns`.`zods_transferorder` AS WITH
  trfo AS (
   SELECT
     `tr`.`ID`
   , `tr`.`createddate`
   , `tr`.`custbody_pm_so_src_no`
   , `tr`.`lastmodifieddate`
   , `tr`.`trandate`
   , `tr`.`tranid`
   , `tr`.`transferlocation`
   , `tr`.`recordtype`
   , `tr`.`type`
   , `tr`.`status`
   , `trl`.`id` `trl_id`
   , `trl`.`item`
   , `trl`.`itemtype`
   , `trl`.`location`
   , `trl`.`memo`
   , `trl`.`quantity`
   , `trl`.`transactionlinetype`
   , `trl`.`accountinglinetype`
   , `trl`.`createdfrom`
   , `st`.`name` `location_txt`
   , `trl`.`subsidiary`,
   ,trl.entity
   FROM
     ((`transactionline` `trl`
   LEFT JOIN `transaction` `tr` ON (`tr`.`id` = `trl`.`transaction`))
   LEFT JOIN `location` `st` ON (`trl`.`location` = `st`.`id`))
   WHERE (((`tr`.`recordtype` IN ('transferorder')) AND (`trl`.`accountinglinetype` = 'ASSET')) AND ((`trl`.`transactionlinetype` IN ('ITEM')) OR (`trl`.`transactionlinetype` IS NULL)))
) 
, itemful AS (
   SELECT
     `trl`.`createdfrom`
   , `trl`.`item`
   , `ns`.`min`(`tr`.`tranid`) `tranid`
   , `ns`.`min`(`tr`.`createddate`) `createddate`
   , `ns`.`sum`(`trl`.`quantity`) `quantity`
   FROM
     ((`transactionline` `trl`
   LEFT JOIN `transaction` `tr` ON (`tr`.`id` = `trl`.`transaction`))
   LEFT JOIN `location` `st` ON (`trl`.`location` = `st`.`id`))
   WHERE (((`tr`.`recordtype` IN ('itemfulfillment')) AND (`trl`.`accountinglinetype` = 'ASSET')) AND ((`trl`.`transactionlinetype` IN ('ITEM')) OR (`trl`.`transactionlinetype` IS NULL)))
   GROUP BY 1, 2
) 
, itemrec AS (
   SELECT
     `trl`.`createdfrom`
   , `trl`.`item`
   , `ns`.`min`(`tr`.`tranid`) `tranid`
   , `ns`.`min`(`tr`.`createddate`) `createddate`
   , `ns`.`sum`(`trl`.`quantity`) `quantity`
   FROM
     ((`transactionline` `trl`
   LEFT JOIN `transaction` `tr` ON (`tr`.`id` = `trl`.`transaction`))
   LEFT JOIN `location` `st` ON (`trl`.`location` = `st`.`id`))
   WHERE (((`tr`.`recordtype` IN ('itemreceipt')) AND (`trl`.`accountinglinetype` = 'ASSET')) AND ((`trl`.`transactionlinetype` IN ('ITEM')) OR (`trl`.`transactionlinetype` IS NULL)))
   GROUP BY 1, 2
) 
, trfo_to AS (
   SELECT
     `tr`.`ID`
   , `tr`.`createddate`
   , `tr`.`custbody_pm_so_src_no`
   , `tr`.`lastmodifieddate`
   , `tr`.`trandate`
   , `tr`.`tranid`
   , `tr`.`transferlocation`
   , `tr`.`recordtype`
   , `tr`.`type`
   , `tr`.`status`
   , `trl`.`id` `trl_id`
   , `trl`.`item`
   , `trl`.`itemtype`
   , `trl`.`location`
   , `trl`.`memo`
   , `trl`.`quantity`
   , `trl`.`transactionlinetype`
   , `trl`.`accountinglinetype`
   , `trl`.`createdfrom`
   , `st`.`name` `location_txt`
   , `trl`.`subsidiary`
   ,trl.entity
   FROM
     ((`transactionline` `trl`
   LEFT JOIN `transaction` `tr` ON (`tr`.`id` = `trl`.`transaction`))
   LEFT JOIN `location` `st` ON (`trl`.`location` = `st`.`id`))
   WHERE (((`tr`.`recordtype` IN ('transferorder')) AND (`trl`.`accountinglinetype` = 'ASSET')) AND (`trl`.`transactionlinetype` IN ('RECEIVING')))
) 
SELECT
  `trfo`.`location` `发出地点ID`
, `trfo`.`location_txt` `发出地点名称` -- 大仓
, `trfo_to`.`location` `接收地点ID`
, `trfo_to`.`location_txt` `接收地点名称` -- 门店
, `trfo`.`tranid` `TO单`
, `st`.`status_txt` `TO单状态`
, `itemful`.`tranid` `发货单`
, `itemrec`.`tranid` `收货单`
, `trfo`.`item` `商品ID`
, `itm`.`itemID` `商品代码`
, `itm`.`custitem_pm_item_main_barcode` `国际条码`
, `itm`.`displayname` `商品名称`
, `trfo`.`createddate` `TO日期`
, `itemful`.`createddate` `发货日期`
, `itemrec`.`createddate` `收货日期`
, COALESCE(`ns`.`abs`(`trfo`.`quantity`), 0) `TO数量`
, COALESCE(`ns`.`abs`(`itemful`.`quantity`), 0) `发货数量`
, COALESCE(`ns`.`abs`(`itemrec`.`quantity`), 0) `收货数量`
, `trfo`.`subsidiary` `分公司`
, `ftype`.`locationtype` `发出地点类型`
, `ttype`.`locationtype` `接收地点类型`,
,trfo.`entity`
FROM
  (((((((`trfo`
LEFT JOIN `itemful` ON ((`trfo`.`id` = `itemful`.`createdfrom`) AND (`trfo`.`item` = `itemful`.`item`)))
LEFT JOIN `itemrec` ON ((`trfo`.`id` = `itemrec`.`createdfrom`) AND (`trfo`.`item` = `itemrec`.`item`)))
LEFT JOIN `zods_trstatus` `st` ON ((`trfo`.`recordtype` = `st`.`abbrevtype`) AND (`trfo`.`status` = `st`.`status`)))
LEFT JOIN `item` `itm` ON (`trfo`.`item` = `itm`.`id`))
LEFT JOIN `trfo_to` ON ((`trfo`.`id` = `trfo_to`.`ID`) AND (`trfo`.`item` = `trfo_to`.`item`)))
LEFT JOIN (
   SELECT
     `a`.`id`
   , `a`.`name`
   , `b`.`name` `locationtype`
   , `custrecord_pm_location_type`
   FROM
     (`location` `a`
   LEFT JOIN `CUSTOMLIST_PM_LOCATION_TYPE_LIST` `b` ON (`a`.`custrecord_pm_location_type` = `b`.`id`))
)  `ftype` ON (`trfo`.`location` = `ftype`.`id`))
LEFT JOIN (
   SELECT
     `a`.`id`
   , `a`.`name`
   , `b`.`name` `locationtype`
   , `custrecord_pm_location_type`
   FROM
     (`location` `a`
   LEFT JOIN `CUSTOMLIST_PM_LOCATION_TYPE_LIST` `b` ON (`a`.`custrecord_pm_location_type` = `b`.`id`))
)  `ttype` ON (`trfo_to`.`location` = `ttype`.`id`))
