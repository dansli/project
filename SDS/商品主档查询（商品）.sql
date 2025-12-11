Select
       v_orggoods.code 商品代码,
       v_orggoods.code2 第二代码,
       v_orggoods.name 商品名称,
       v_orggoods.munit 规格单位,
       v_orggoods.spec 含量,
       goodsbusgate.code 商品状态代码,
       vendor.code 缺省供应商,
       goodsbusgate.name 商品状态名称,
       vendor.name 缺省供应商名称,
       brand.code 品牌代码,
       brand.name 品牌名称,
       v_orggoods.Segment 细分,
       v_orggoods.grounddate 上架日期,
       v_orggoods.year 年份,
       v_orggoods.mounth 月份,
       v_orggoods.Operationmode 经营方式,
       substr(v_orggoods.ip,1,(instr(v_orggoods.ip,'[',1)-1)) IP,
       gi.name 副IP,
       h4v_gdqpc.dqpcstr 配货规格,
       h4v_gdqpc.pqpcstr 采购规格,
       h4v_gdqpc.rqpcstr 零售规格,
       h4v_gdqpc.wqpcstr 批发规格,
       h4v_goodssort.asname 大类,
       h4v_goodssort.bsname 中类,
       h4v_goodssort.csname 小类,
       v_orggoods.property 商品属性,
       v_orggoods.xc 箱长,
       v_orggoods.xk 箱宽,
       v_orggoods.xg 箱高,
       v_orggoods.qpcstr 规格,
       -- ppmtdz 220711 by dqy start 新增箱规/单体体积
       v_orggoods.xianggui 箱规,
       v_orggoods.dwtj 单件体积件m3,
       v_orggoods.hegui 盒规,
       v_orggoods.weight 重量,
       decode(v_orggoods.rtlprc, 0, 0, (v_orggoods.rtlprc - v_orggoods.cntinprc) / v_orggoods.rtlprc * 100) 毛利率,
       v_orggoods.origin 产地,
       v_orggoods.slot 货架位,
       v_orggoods.validperiod 保质期,
       v_orggoods.alc 配货方式,
       v_orggoods.cntinprc 合同进价,
       v_orggoods.expcntinprc 去税合同进价,
       v_orggoods.rtlprc 核算售价,
       v_orggoods.whsprc 批发价,
       v_orggoods.lwtrtlprc 最低售价,
       v_orggoods.modifier 最后修改人, 
       v_orggoods.lstupdtime 最后修改时间,
(select '['||scode||']'||sname from sortname where acode='P0001' and scode=substr(REGEXP_SUBSTR(v_orggoods.def_datasort, '\d+', 1, 1, 'i'),0,2)) 商业一级,
       (select '['||scode||']'||sname from sortname where acode='P0001' and scode=substr(REGEXP_SUBSTR(v_orggoods.def_datasort, '\d+', 1, 1, 'i'),0,4)) 商业二级,
       v_orggoods.def_datasort 商业三级,
       g.taxcode 税收编码，
       v_orggoods.shortname 简称，
       v_orggoods.bzxs 包装形式,
       v_orggoods.dgc 单个长,
       v_orggoods.dgk 单个宽,
       v_orggoods.dgg 单个高,
       v_orggoods.vdrgdcode 供应商自编码
       ,v_orggoods.Srcblgorg 所属机构,
       v_orggoods.createdate 创建日期，
       v_orggoods.cpxz 产品性质,
       v_orggoods.wf 玩法,
       v_orggoods.cpz 产品组,
       v_orggoods.cpzdm 产品组代码,
       v_orggoods.series 系列代码，
       v_orggoods.LSTINPRC 最新进价,
        v_orggoods.style 明盒类型,
        decode(v_orggoods.hidemode,'1','实物','2','兑换卡') 隐藏形式,
        s.hidestylecnt 隐藏款数,
        (select o.FVALUE from ppro_options o where o.TYPE='hideRate' and v_orggoods.hideRate=o.fkey) 隐藏概率,
        v_orggoods.xz 箱重,
        v_orggoods.xtj 箱体积,
        pg.caseqpcbarcode 箱规条码,
        s.name 系列名称,
        se2.name 主系列名称,
        s.productModel 产品型号,
        v_orggoods.ename 商品英文名称,
        PG.SOURCE 商品来源,
        V_ORGGOODS.style 款式,
        V_ORGGOODS.TAXRATE 进项税率,
        v_orggoods.RtlPrc 建议零售价,
        v_orggoods.ISJQRSP 机器人商品,
        pg.boxqpcbarcode 盒规条码,
        v_orggoods.grounddate 辅助发售日期,
        v_orggoods.weight 单个重,
        v_orggoods.def_cpx 产品线,
        employee.name 采购员,
        dept.name 部门,
        decode(pg.state,'rejected','已驳回','modifiedAndWaitApprove','已修改待审核','approved','已通过','waitApply','待申请','submitted','已提交待审核') 商品状态，
        v_orggoods.srcblgorg 结算主体,
        (select o.FVALUE from ppro_options o,ppro_series ps where o.TYPE='area' and ps.code = s.code and ps.area=o.fkey) 地区,s.SERIESTHEME 系列主题,
		(select o.FVALUE from ppro_options o where o.TYPE='SERIESTHEME' and s.SERIESTHEME=o.fkey) 系列主题名称
  From  ppro_goods pg,vendor vendor, brand brand, employee employee, sortname sortname, h4v_gdqpc h4v_gdqpc, h4v_goodssort h4v_goodssort, warehouse warehouse, goods v_orggoods, goodsbusgate goodsbusgate，goods g,ppmt_goods_ip gi,series s,series se2,
  dept dept
 Where vendor.gid(+) = v_orggoods.vdrgid and s.mainseries = se2.code(+)
   and v_orggoods.gid = g.gid
   and gi.code(+) = v_orggoods.ip1
   And brand.code(+) = v_orggoods.brand
      and dept.code(+)=v_orggoods.dep
   And v_orggoods.psr(+) = employee.gid
   And sortname.scode(+) = v_orggoods.sort
   and s.code = v_orggoods.series and v_orggoods.code = pg.code
   --and pg.hidemode = pot1.fkey and pot1.type = 'hideMode'
  -- and v_orggoods.psr = e.gid
   And v_orggoods.gid <> 1
   And h4v_gdqpc.gid = v_orggoods.gid
   And h4v_goodssort.gid(+) = v_orggoods.gid
   And v_orggoods.wrh = warehouse.gid
   And goodsbusgate.gid = v_orggoods.busgate
   --And (v_orggoods.orggid = '{$currentOrg}')
   #and {vendor.gid:$vendor}#
   --#and {warehouse.gid:$warehouse}#
   #and {v_orggoods.code:pigdcode}#       /*商品代码*/
   #and {v_orggoods.sort:pisort}#         /*类别代码*/
   #and {v_orggoods.brand:pibrand}#       /*品牌代码*/
   #and {goodsbusgate.code:pigdbusgate}#      /*状态代码*/
   #and {h4v_goodssort.cscode:vcscode}#      /*小类代码*/
 Order By 配货方式 Asc