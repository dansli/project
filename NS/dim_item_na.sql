

 CREATE VIEW `dw`.`ZMD_DMV002_01` AS SELECT
  `g`.`code` `商品代码`
, `g`.`name` `商品名称`
, `g`.`ename` `商品英文名称`
, `g`.`barcode` `商品条码`
, `o4`.`FVALUE` `包装方式`
, (CASE `s`.`sort` WHEN null THEN '' ELSE `dw`.`concat`(`dw`.`concat`(`dw`.`concat`('[', `so`.`scode`), '] '), `so`.`sname`) END) `商品类别`
, `so2`.`sname` `大类名称`
, `so3`.`sname` `中类名称`
, `o5`.`fvalue` `产品性质`
, `o6`.`fvalue` `商品属性`
, `o1`.`FVALUE` `款式`
, `o9`.`fvalue` `产品线`
, `g`.`CASEQPC` `商品箱规`
, `g`.`BOXQPC` `商品盒规`
, `s`.`CASEQPC` `系列箱规`
, `s`.`BOXQPC` `系列盒规`
, `g`.`caseQpcBarcode` `箱规条码`
, `g`.`boxQpcBarcode` `盒规条码`
, `s`.`HIDESTYLECNT` `隐藏款数`
, `o2`.`FVALUE` `隐藏概率`
, `o3`.`FVALUE` `隐藏形式`
, (CASE `g`.`vendor` WHEN null THEN '' ELSE `dw`.`concat`(`dw`.`concat`(`dw`.`concat`('[', `g`.`vendor`), '] '), `v`.`name`) END) `供应商`
, (CASE `g`.`psrCode` WHEN null THEN '' ELSE `dw`.`concat`(`dw`.`concat`(`dw`.`concat`('[', `g`.`psrCode`), '] '), `f`.`name`) END) `采购员`
, `g`.`vdrGdCode` `自编码`
, `g`.`actInPrc` `核算进价`
, `g`.`taxRate` `进项税率`
, `o8`.`fvalue` `产品组`
, `g`.`series` `系列编码`
, `s`.`name` `系列名称`
, `s`.`productModel` `产品型号`
, `dw`.`replace`(`dw`.`replace`(`dw`.`replace`(`dw`.`replace`(`dw`.`replace`(`s`.`ipdevhead`, '[', ''), ']', ''), '{"code":"', '['), '","name":"', ']'), '"}', '') `IP开发负责人`
, `s`.`projectheadname` `项目负责人`
, `dw`.`replace`(`dw`.`replace`(`dw`.`replace`(`dw`.`replace`(`dw`.`replace`(`s`.`antifakemarkgoods`, '[', ''), ']', ''), '{"code":"', '['), '","name":"', ']'), '"}', '') `防伪贴商品`
, `s`.`hideratedesc` `隐藏概率描述`
, `s`.`srcblgorg` `所属业务板块代码`
, (CASE `s`.`srcblgorg` WHEN 'POP MART-01' THEN '自主常规' WHEN 'POP MART-02' THEN '共鸣工作室' WHEN 'POP MART-03' THEN '乐园' WHEN 'POP MART-04' THEN '商品外采' WHEN 'POP MART-05' THEN '衍生品' WHEN 'POP MART-06' THEN '葩趣' WHEN 'POP MART-07' THEN '艺术家外采' WHEN 'POP MART-08' THEN 'inner flow' WHEN 'POP MART-09' THEN '零作工作室' WHEN 'POP MART-10' THEN '偲徕' WHEN 'POP MART-11' THEN '非卖品' WHEN 'POP MART-12' THEN '辅助售卖' END) `所属业务板块`
, `s`.`source` `系列来源`
, `s`.`biztype` `系列标识`
, `s`.`mainseries` `主系列`
, `g`.`assistselldate` `辅助发售日期`
, (CASE `g`.`robotgoods` WHEN 1 THEN '是' WHEN 0 THEN '否' END) `机器人商品`
, (CASE `s`.`brand` WHEN null THEN '' ELSE `dw`.`concat`(`dw`.`concat`(`dw`.`concat`('[', `s`.`BRAND`), '] '), `b`.`name`) END) `品牌`
, (CASE `s`.`ip` WHEN null THEN '' ELSE `dw`.`concat`(`dw`.`concat`(`dw`.`concat`('[', `s`.`ip`), '] '), `i`.`name`) END) `IP`
, `s`.`COLLABORATIONIP` `联名ip`
, `dw`.`date_format`(`s`.`LAUNCHDATE`, '%Y-%m-%d') `上市日期`
, `o7`.`fvalue` `玩法`
, `g`.`suggestrtlprc` `建议零售价`
, `g`.`rtlprc` `零售价`
, (CASE `g`.`dept` WHEN null THEN '' ELSE `dw`.`concat`(`dw`.`concat`(`dw`.`concat`('[', `g`.`dept`), '] '), `d1`.`name`) END) `部门`
, `g`.`caseLength` `箱长`
, `g`.`casewidth` `箱宽`
, `g`.`caseHeight` `箱高`
, `g`.`singleLength` `单个长`
, `g`.`singleHeight` `单个高`
, `g`.`singleWidth` `单个宽`
, `g`.`singleVolume` `单个体积`
, `g`.`caseVolume` `箱体积`
, `g`.`singleWeight` `单个重`
, `g`.`caseWeight` `箱重`
, `s`.`ENAME` `系列英文名称`
, `tm`.`name` `商品模板`
, `g`.`source` `商品来源`
, `g`.`disassemblyCnt` `商品拆件数量`
, (CASE `g`.`state` WHEN 'rejected' THEN '已驳回' WHEN 'waitApply' THEN '待申请' WHEN 'submitted' THEN '已提交待审核' WHEN 'approved' THEN '已通过' WHEN 'modifiedAndWaitApprove' THEN '已修改待审核' ELSE null END) `商品状态`
, `g`.`reason` `原因`
, `o10`.`fvalue` `模具类型`
, `o11`.`fvalue` `模具材质`
, `s`.`disassemblyCnt` `拆件数量`
, `s`.`pvcCnt` `搪胶件数`
, `g`.`partName` `零件名称`
, (CASE `g`.`moldingMaterials` WHEN '[]' THEN null ELSE `goods`.`moldingMaterials` END) `成型材料`
, `g`.`cavityCnt` `型腔数量`
, `o12`.`fvalue` `加工工艺`
, `g`.`pvcMouldHolesCnt` `搪胶模具孔数`
, `o13`.`fvalue` `AB模`
, `zgd`.`zbusiness1` `商业一级代码`
, `zgd`.`zbusiness1_txt` `商业一级名称`
, `zgd`.`zbusiness2` `商业二级代码`
, `zgd`.`zbusiness2_txt` `商业二级名称`
, `zgd`.`zbusiness3` `商业三级代码`
, `zgd`.`zbusiness3_txt` `商业三级名称`
FROM
  (((((((((((((((((((((((((((`sds`.`ppro_goods` `g`
LEFT JOIN `DW`.`zgoods` `zgd` ON (`g`.`gid` = `zgd`.`zgid`))
LEFT JOIN `sds`.`ppro_options` `o1` ON ((`o1`.`TYPE` = 'hideStyle') AND (`g`.`style` = `o1`.`fkey`)))
LEFT JOIN `sds`.`goods` `goods` ON (`goods`.`gid` = `g`.`gid`))
LEFT JOIN `sds`.`ppro_options` `o2` ON ((`o2`.`TYPE` = 'hideRate') AND (`g`.`hideRate` = `o2`.`fkey`)))
LEFT JOIN `sds`.`ppro_options` `o3` ON ((`o3`.`TYPE` = 'hideMode') AND (`g`.`hideMode` = `o3`.`fkey`)))
LEFT JOIN `sds`.`ppro_options` `o4` ON ((`o4`.`TYPE` = 'packing') AND (`g`.`packing` = `o4`.`fkey`)))
LEFT JOIN `sds`.`vendor` `v` ON (`v`.`code` = `g`.`vendor`))
LEFT JOIN `sds`.`faemph` `f` ON (`g`.`psrCode` = `f`.`Code`))
LEFT JOIN `sds`.`ppro_series` `s` ON (`s`.`code` = `g`.`series`))
LEFT JOIN `sds`.`BRAND` `b` ON (`s`.`BRAND` = `b`.`code`))
LEFT JOIN `sds`.`V_MDM_IP` `i` ON (`s`.`ip` = `i`.`code`))
LEFT JOIN `sds`.`ppro_options` `o5` ON ((`o5`.`TYPE` = 'productProperty') AND (`s`.`PRODUCTPROPERTY` = `o5`.`fkey`)))
LEFT JOIN `sds`.`ppro_options` `o6` ON ((`o6`.`TYPE` = 'devProperty') AND (`s`.`DEVPROPERTY` = `o6`.`fkey`)))
LEFT JOIN `sds`.`sortname` `so` ON ((`so`.`acode` = '0000') AND (`so`.`scode` = `s`.`sort`)))
LEFT JOIN `sds`.`ppro_options` `o7` ON ((`o7`.`TYPE` = 'playMode') AND (`s`.`playMode` = `o7`.`fkey`)))
LEFT JOIN (
   SELECT *
   FROM
     `sds`.`ppro_options`
   WHERE (`ENABLED` = 1)
)  `o8` ON ((`o8`.`TYPE` = 'productGroup') AND (`s`.`PRODUCTGROUP` = `o8`.`fkey`)))
LEFT JOIN `sds`.`ppro_options` `o9` ON ((`o9`.`TYPE` = 'productType') AND (`s`.`PRODUCTTYPE` = `o9`.`fkey`)))
LEFT JOIN `sds`.`ppro_product_tmpl` `tm` ON (`g`.`productTmpl` = `tm`.`id`))
LEFT JOIN `sds`.`dept` `d1` ON (`d1`.`code` = `g`.`dept`))
LEFT JOIN `sds`.`dept` `d2` ON (`d2`.`code` = `s`.`dept`))
LEFT JOIN `sds`.`sortname` `so2` ON ((`so2`.`acode` = '0000') AND (`dw`.`substr`(`s`.`sort`, 1, 2) = `so2`.`scode`)))
LEFT JOIN `sds`.`sortname` `so3` ON ((`so3`.`acode` = '0000') AND (`dw`.`substr`(`s`.`sort`, 1, 4) = `so3`.`scode`)))
LEFT JOIN `sds`.`ppro_options` `o10` ON ((`o10`.`TYPE` = 'mouldType') AND (`g`.`mouldType` = `o10`.`fkey`)))
LEFT JOIN `sds`.`ppro_options` `o11` ON ((`o11`.`TYPE` = 'mouldMaterial') AND (`g`.`mouldMaterial` = `o11`.`fkey`)))
LEFT JOIN `sds`.`ppro_options` `o12` ON ((`o12`.`TYPE` = 'processTech') AND (`dw`.`replace`(`dw`.`replace`(`g`.`processTechs`, '["', ''), '"]') = `o12`.`fkey`)))
LEFT JOIN `sds`.`ppro_options` `o13` ON ((`o13`.`TYPE` = 'abMould') AND (`g`.`abMould` = `o13`.`fkey`)))
LEFT JOIN `sds`.`ppro_options` `o14` ON ((`o14`.`TYPE` = 'moldingMaterials') AND (`dw`.`substr`(`g`.`moldingMaterials`, 3, (`dw`.`length`(`g`.`moldingMaterials`) - 4)) = `o14`.`fkey`)))



