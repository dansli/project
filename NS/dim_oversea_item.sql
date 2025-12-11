 CREATE VIEW `ns`.`dim_oversea_item` AS SELECT
  `item`.`id`
, `amortizationperiod`
, `amortizationtemplate`
, `assetaccount`
, `atpmethod`
, `averagecost`
, `billexchratevarianceacct`
, `billpricevarianceacct`
, `billqtyvarianceacct`
, `class` `item_class`
, `copydescription`
, `cost`
, `costestimate`
, `costestimatetype`
, `costingmethod`
, `costingmethoddisplay`
, `countryofmanufacture`
, `createddate`
, `createexpenseplanson`
, `cseg_pm_cf`
, `custitem_code_of_supply`
, `custitem_commodity_code`
, `custitem_itr_supplementary_unit`
, `custitem_itr_supplementary_unit_abbrev`
, `custitem_nature_of_transaction_codes`
, `custitem_pm_brand_name`
, `custitem_pm_brand_type_customs`
, `custitem_pm_cf_inflow`
, `custitem_pm_cf_outflow`
, `custitem_pm_china_price`
, `custitem_pm_customs_price`
, `item`.`displayname`
, `custitem_pm_sku_type`
, `totalquantityonhand`
, `custitem_pm_english_name`
, `custitem_pm_expose_date`
, `custitem_pm_up_date`
, `custitem_pm_item_1st_class`
, `custitem_pm_item_2nd_class`
, `custitem_pm_item_3rd_class`
, `custitem_pm_item_box`
, `custitem_pm_item_case`
, `custitem_pm_item_from_hd`
, `custitem_pm_item_hscode`
, `item`.`custitem_pm_item_ipicon`
, `custitem_pm_item_purchase_price`
, `custitem_pm_item_status`
, `custitem_pm_production_city`
, `custitem_pm_stop_date`
, `custitem_pm_volume`
, `custitem_type_of_goods`
, `custreturnvarianceaccount`
, `deferralaccount`
, `department`
, `description` `item_desc`
, `dropshipexpenseaccount`
, `effectivebomcontrol`
, `enforceminqtyinternally`
, `expenseaccount`
, `expenseamortizationrule`
, `item`.`externalid`
, `item`.`fullname`
, `fxcost`
, `gainlossaccount`
, `generateaccruals`
, `handlingcost`
, '' `item_ora_pk_id`
, `item`.`includechildren`
, `incomeaccount`
, `intercoexpenseaccount`
, `intercoincomeaccount`
, `isdropshipitem`
, `isfulfillable`
, `item`.`isinactive`
, `isonline`
, `isspecialorderitem`
, `item`.`itemid`
, `itemtype`
, `item`.`lastmodifieddate`
, `lastpurchaseprice`
, `location` `item_location`
, `manufacturer`
, `matchbilltoreceipt`
, `maximumquantity`
, `minimumquantity`
, `mpn`
, `item`.`parent`
, `preferredlocation`
, `printitems`
, `prodpricevarianceacct`
, `prodqtyvarianceacct`
, `purchasedescription`
, `purchaseorderamount`
, `purchaseorderquantity`
, `purchaseorderquantitydiff`
, `purchasepricevarianceacct`
, `purchaseunit`
, `receiptamount`
, `receiptquantity`
, `receiptquantitydiff`
, `residual`
, `saleunit`
, `scrapacct`
, `shipindividually`
, `shippackage`
, `shippingcost`
, `stockdescription`
, `stockunit`
, `item`.`subsidiary`
, `subtype`
, `supplyreplenishmentmethod`
, `totalvalue`
, `tracklandedcost`
, `transferprice`
, `unbuildvarianceaccount`
, `unitstype`
, `usecomponentyield`
, `vendorname`
, `vendreturnvarianceaccount`
, `weight` `item_weight`
, `weightunit`
, `weightunits`
, `wipacct`
, `wipvarianceacct`
, COALESCE(`iptype`.`name`, `iptype2`.`name`) `ip_type`
, `ZBIGTYPE`
, `ZBIGTYPE_TXT`
, `ZMIDDLETYPE`
, `ZMIDDLETYPE_TXT`
, `ZLITTLETYPE`
, `ZLITTLETYPE_TXT`
, `zbusiness1`
, `zbusiness1_txt`
, `zbusiness2`
, `zbusiness2_txt`
, `zbusiness3`
, `zbusiness3_txt`
, `vii`.`first_class_name_en`
, `vii`.`first_class_name_cn`
, `vii`.`second_class_name_en`
, `vii`.`second_class_name_cn`
, `ip`.`ip_name`
, `ip`.`custitem_pop_oversea_ip`
, `ip`.`oversea_ip_name`
, `item`.`custitem_pm_item_main_barcode`
FROM
  (((((`item`
LEFT JOIN `dw`.`zgoods` `gd` ON (`item`.`itemid` = `gd`.`zgoods`))
LEFT JOIN `zods_overseaitemclass` `vii` ON (`vii`.`itemid` = `item`.`itemid`))
LEFT JOIN (
   SELECT *
   FROM
     `zods_itemmainip`
)  `ip` ON (`item`.`itemid` = `ip`.`itemid`))
LEFT JOIN (
   SELECT
     `item`
   , `ns`.`arbitrary`(`name`) `name`
   FROM
     (
      SELECT
        `i`.`itemid` `item`
      , `iii`.`name`
      FROM
        ((`zods_itemmainip` `i`
      LEFT JOIN `customrecord_pm_ip_icon` `ii` ON (`ii`.`id` = `i`.`first_number`))
      LEFT JOIN `customlist_pm_ip_type` `iii` ON (`iii`.`id` = `ii`.`custrecord_pm_ip_type`))
      GROUP BY `i`.`itemid`, 2
   )  `ip`
   GROUP BY 1
)  `iptype` ON (`item`.`id` = `iptype`.`item`))
LEFT JOIN (
   SELECT
     `item`
   , `ns`.`arbitrary`(`name`) `name`
   FROM
     (
      SELECT
        `i`.`mapone` `item`
      , `iii`.`name`
      FROM
        ((`MAP_item_custitem_pm_item_ipicon` `i`
      LEFT JOIN `customrecord_pm_ip_icon` `ii` ON (`i`.`maptwo` = `ii`.`id`))
      LEFT JOIN `customlist_pm_ip_type` `iii` ON (`iii`.`id` = `ii`.`custrecord_pm_ip_type`))
      GROUP BY `i`.`mapone`, 2
   )  `ip`
   GROUP BY 1
)  `iptype2` ON (`item`.`id` = `iptype2`.`item`))
