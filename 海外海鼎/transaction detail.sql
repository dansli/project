WITH TMP_DAYS AS
 (SELECT NVL(TO_DATE(SUBSTR('#<PIDATE>#', 0, INSTR('#<PIDATE>#', ',') - 1), 'YYYY/MM/DD'), TO_DATE('2000-01-01','YYYY/MM/DD')) BDATE,
         NVL(TO_DATE(SUBSTR('#<PIDATE>#', INSTR('#<PIDATE>#', ',') + 1, LENGTH('#<PIDATE>#') - INSTR('#<PIDATE>#', ',')), 'YYYY/MM/DD'), SYSDATE) EDATE
    FROM DUAL
   WHERE 1 = 1
  --#AND {PIDATE:PIDATE}#
  ),

TMP_MAIN AS
 ( --零售单
   SELECT 
         B1.POSNO   POSNO,   
         B1.FLOWNO  FLOWNO,'' platform,
         B1.FILDATE FILDATE,B1.FILDATE  DTIME, B1.RCVTIME OCRDATE,
         DECODE(SIGN(B2.QTY), -1, '零售退', '零售')         SALECLS,
         '[' || E.CODE || ']' || E.NAME EMPNAME, B1.CARDNO  MEMBERNO,
         S.CODE     STCODE,  S.NAME     STNAME,
         '-'        CLTCODE, '零售客户' CLTNAME,
         G.CODE     GDCODE,  G.CODE2    GDCODE2, G.ENAME     GDNAME, G.NAME GNAME,
         SN.ASCODE  ASCODE,  SN.ASNAME  ASNAME,
         SN.BSCODE  BSCODE,  SN.BSNAME  BSNAME,
         SN.CSCODE  CSCODE,  SN.CSNAME  CSNAME,
         SN.DSCODE  DSCODE,  SN.DSNAME  DSNAME,
         BR.CODE    BRCODE,  BR.NAME    BRNAME,
         B2.QTY                                             QTY,
   		B2.PFURTLPRC RTLPRC,
         DECODE(B2.QTY, 0, 0, B2.REALAMT / B2.QTY)          PRICE,
         B2.REALAMT                                         TOTAL,
         B3.TAXAMOUNT                                       TAX,
         DECODE(B2.QTY, 0, 0, (B2.IAMT + B2.ITAX) / B2.QTY) IPRICE,
         (B2.IAMT + B2.ITAX)                                ITOTAL,
         B2.IAMT                                            IAMT,
         B2.ITAX                                            ITAX,
         (B2.REALAMT - B2.IAMT - B2.ITAX)                   GP,
         B2.STDTOTAL                                        STDTOTAL,
         B2.FAVAMT                                          FAVAMT
    FROM BUY1S B1
   INNER JOIN BUY2S             B2 ON B1.POSNO = B2.POSNO AND B1.FLOWNO = B2.FLOWNO
   INNER JOIN BUY23S            B3 ON B2.POSNO = B3.POSNO AND B2.FLOWNO = B3.FLOWNO AND B2.ITEMNO=B3.ITEMNO
   INNER JOIN WORKSTATION       WS ON B1.POSNO = WS.NO
   INNER JOIN STORE             S  ON WS.STOREGID = S.GID
   INNER JOIN ORGGOODS          G  ON B2.GID = G.GID
   INNER JOIN EMPLOYEE          E  ON E.GID = B1.CASHIER
   INNER JOIN BRAND             BR ON G.BRAND = BR.CODE
   INNER JOIN STDRPT_V_SORTNAME SN ON G.SORT = SN.DSCODE
   INNER JOIN TMP_DAYS          TD ON B1.FILDATE >= TD.BDATE AND B1.FILDATE < TD.EDATE
   WHERE 1 = 1
    /*限制组织*/
     and G.orggid = {$currentorg}
     And S.code not like '%X%'
     and (s.orggid = {$currentorg} OR {$currentorg}=1000000)
    /*数据授权*/
    #and {S.GID:$store}#
    #and {G.sort:$sort}#
    /*查询条件*/
    #and {G.code:pigdcode}#      /*商品代码*/
    #and {G.NAME:pigdname}#      /*商品名称*/
     AND EXISTS (SELECT 1 FROM GDINPUT GI2 WHERE G.GID = GI2.GID #AND {GI2.CODE:PIGDCODE2}#) /*商品条码*/
    #and {G.sort:pisort}#        /*类别代码*/
    #and {G.sort:pisortcode}#    /*类别代码*/
    #and {SN.CSNAME:pisortname}# /*类别名称*/
    #and {G.brand:pibrand}#      /*品牌代码*/
    #and {GB.code:pigdbusgate}#  /*状态代码*/
    
    #and {S.code:PISTOREGID}#    /*门店代码*/
    #and {S.AREA:PISTAREA}#      /*区域代码*/ 
    
    #and {'零售客户':PICLIENT}#   /*客户代码*/
    #and {B1.POSNO:PIPOSNO}#     /*收银机号*/
    #and {B1.FLOWNO:PIFLOWNO}#   /*流水号*/
    #and {DECODE(SIGN(B2.QTY), -1, '零售退', '零售'):PISALECLS}# /*销售类型*/
 
   UNION ALL
   
    --零售单未加工表
   SELECT 
         B1.POSNO   POSNO,   
         B1.FLOWNO  FLOWNO,'' platform,
         B1.FILDATE FILDATE,B1.FILDATE  DTIME, B1.FILDATE OCRDATE,
         DECODE(SIGN(B2.QTY), -1, '零售退', '零售')         SALECLS,
         '[' || E.CODE || ']' || E.NAME EMPNAME, B1.CARDNO  MEMBERNO,
         S.CODE     STCODE,  S.NAME     STNAME,
         '-'        CLTCODE, '零售客户' CLTNAME,
         G.CODE     GDCODE,  G.CODE2    GDCODE2, G.ENAME     GDNAME, G.NAME GNAME,
         SN.ASCODE  ASCODE,  SN.ASNAME  ASNAME,
         SN.BSCODE  BSCODE,  SN.BSNAME  BSNAME,
         SN.CSCODE  CSCODE,  SN.CSNAME  CSNAME,
         SN.DSCODE  DSCODE,  SN.DSNAME  DSNAME,
         BR.CODE    BRCODE,  BR.NAME    BRNAME,
         B2.QTY                                             QTY,
         B2.PFURTLPRC RTLPRC,
         DECODE(B2.QTY, 0, 0, B2.REALAMT / B2.QTY)          PRICE,
         B2.REALAMT                                         TOTAL,
         B3.TAXAMOUNT                                       TAX,
         DECODE(B2.QTY, 0, 0, (0 / B2.QTY) )IPRICE,
         0                                ITOTAL,
         0                                         IAMT,
         0                                            ITAX,
         (B2.REALAMT )                   GP,
         B2.STDTOTAL                                        STDTOTAL,
         B2.FAVAMT                                          FAVAMT
    FROM BUY1POOLS B1
   INNER JOIN BUY2POOLS             B2 ON B1.POSNO = B2.POSNO AND B1.FLOWNO = B2.FLOWNO
   INNER JOIN BUY23POOLS            B3 ON B2.POSNO = B3.POSNO AND B2.FLOWNO = B3.FLOWNO AND B2.ITEMNO=B3.ITEMNO
   INNER JOIN WORKSTATION       WS ON B1.POSNO = WS.NO
   INNER JOIN STORE             S  ON WS.STOREGID = S.GID
   INNER JOIN ORGGOODS          G  ON B2.GID = G.GID
   INNER JOIN EMPLOYEE          E  ON E.GID = B1.CASHIER
   INNER JOIN BRAND             BR ON G.BRAND = BR.CODE
   INNER JOIN STDRPT_V_SORTNAME SN ON G.SORT = SN.DSCODE
   INNER JOIN TMP_DAYS          TD ON B1.FILDATE >= TD.BDATE AND B1.FILDATE < TD.EDATE
   WHERE 1 = 1
    /*限制组织*/
     and G.orggid = {$currentorg}
     and (s.orggid = {$currentorg} OR {$currentorg}=1000000)
    /*数据授权*/
    #and {S.GID:$store}#
    #and {G.sort:$sort}#
    /*查询条件*/
    #and {G.code:pigdcode}#      /*商品代码*/
    #and {G.NAME:pigdname}#      /*商品名称*/
     AND EXISTS (SELECT 1 FROM GDINPUT GI2 WHERE G.GID = GI2.GID #AND {GI2.CODE:PIGDCODE2}#) /*商品条码*/
    #and {G.sort:pisort}#        /*类别代码*/
    #and {G.sort:pisortcode}#    /*类别代码*/
    #and {SN.CSNAME:pisortname}# /*类别名称*/
    #and {G.brand:pibrand}#      /*品牌代码*/
    #and {GB.code:pigdbusgate}#  /*状态代码*/
    
    #and {S.code:PISTOREGID}#    /*门店代码*/
    #and {S.AREA:PISTAREA}#      /*区域代码*/ 
    
    #and {'零售客户':PICLIENT}#   /*客户代码*/
    #and {B1.POSNO:PIPOSNO}#     /*收银机号*/
    #and {B1.FLOWNO:PIFLOWNO}#   /*流水号*/
    #and {DECODE(SIGN(B2.QTY), -1, '零售退', '零售'):PISALECLS}# /*销售类型*/
  
  UNION ALL
 --批发单
  SELECT NULL       POSNO,    A.NUM      FLOWNO,A.srcnum platform,
         A.PM_ORDER_TIME     FILDATE, A.PM_DELIVERY_TIME  DTIME, L.TIME     OCRDATE,
         A.CLS      SALECLS,
         A.FILLER   EMPNAME,  NULL       MEMBERNO, 
         S.CODE     STCODE,   S.NAME     STNAME,
         C.CODE     CLTCODE,  C.NAME     CLTNAME,
         G.CODE     GDCODE,   G.CODE2    GDCODE2, G.ENAME GDNAME,G.NAME GNAME,
         SN.ASCODE  ASCODE,   SN.ASNAME  ASNAME,
         SN.BSCODE  BSCODE,   SN.BSNAME  BSNAME,
         SN.CSCODE  CSCODE,   SN.CSNAME  CSNAME,
         SN.DSCODE  DSCODE,   SN.DSNAME  DSNAME,
         BR.CODE    BRCODE,   BR.NAME    BRNAME,
         D.QTY                                           QTY,
   		D.RTLPRC RTLPRC,
         DECODE(D.QTY, 0, 0, D.TOTAL / D.QTY)            PRICE,
         D.TOTAL                                         TOTAL, (case when  D.TOTAL >0 then 1 else -1 end) *D.tax TAX,
         DECODE(D.QTY, 0, 0, (D.CAMT + D.CTAX) / D.QTY)  IPRICE,
         (D.CAMT + D.CTAX)                               ITOTAL,
         D.CAMT                                          IAMT,
         D.CTAX                                          ITAX,
         (D.TOTAL - D.CAMT - D.CTAX)                     GP,
         D.TOTAL                                         STDTOTAL,
         0                                               FAVAMT
    FROM STKOUT A
   INNER JOIN STKOUTDTL         D  ON A.NUM = D.NUM AND A.CLS = D.CLS
   INNER JOIN STKOUTLOG         L  ON A.NUM = L.NUM AND A.CLS = L.CLS AND L.STAT IN (700, 720, 740, 1020, 1040, 320, 340)
   INNER JOIN STORE             S  ON A.SENDER = S.GID
   INNER JOIN ORGGOODS          G  ON D.GDGID = G.GID
   INNER JOIN CLIENT            C  ON A.CLIENT = C.GID
   INNER JOIN STDRPT_V_SORTNAME SN ON G.SORT = SN.DSCODE
   INNER JOIN BRAND             BR ON G.BRAND = BR.CODE
   INNER JOIN TMP_DAYS          TD ON A.PM_DELIVERY_TIME >= TD.BDATE AND A.PM_DELIVERY_TIME < TD.EDATE
   WHERE 1 = 1
     AND A.CLS = '批发'
    /*限制组织*/
     and G.orggid = {$currentorg}
    and (s.orggid = {$currentorg} OR {$currentorg}=1000000)
    /*数据授权*/
    #and {S.GID:$store}#
    #and {G.sort:$sort}#
    /*查询条件*/
    #and {G.code:pigdcode}#      /*商品代码*/
    #and {G.NAME:pigdname}#      /*商品名称*/
     AND EXISTS (SELECT 1 FROM GDINPUT GI2 WHERE G.GID = GI2.GID #AND {GI2.CODE:PIGDCODE2}#) /*商品条码*/
    #and {G.sort:pisort}#        /*类别代码*/
    #and {G.sort:pisortcode}#    /*类别代码*/
    #and {SN.CSNAME:pisortname}# /*类别名称*/
    #and {G.brand:pibrand}#      /*品牌代码*/
    #and {GB.code:pigdbusgate}#  /*状态代码*/
    
    #and {S.code:PISTOREGID}#    /*门店代码*/
    #and {S.AREA:PISTAREA}#      /*区域代码*/
    
    #and {C.CODE:PICLIENT}#      /*客户代码*/
    #and {NULL:PIPOSNO}#         /*收银机号*/
    #and {A.NUM:PIFLOWNO}#       /*流水号*/
    #and {A.CLS:PISALECLS}#      /*销售类型*/
  UNION ALL
   --批发退单
  SELECT NULL       POSNO,    A.NUM      FLOWNO,a.platformrtnnum platform,
         a.pm_return_time    FILDATE, a.pm_return_time   DTIME,L.TIME     OCRDATE,
         A.CLS      SALECLS,
         A.FILLER   EMPNAME,  NULL       MEMBERNO, 
         S.CODE     STCODE,   S.NAME     STNAME,
         C.CODE     CLTCODE,  C.NAME     CLTNAME,
         G.CODE     GDCODE,   G.CODE2    GDCODE2, G.ENAME GDNAME,G.NAME GNAME,
         SN.ASCODE  ASCODE,   SN.ASNAME  ASNAME,
         SN.BSCODE  BSCODE,   SN.BSNAME  BSNAME,
         SN.CSCODE  CSCODE,   SN.CSNAME  CSNAME,
         SN.DSCODE  DSCODE,   SN.DSNAME  DSNAME,
         BR.CODE    BRCODE,   BR.NAME    BRNAME,
         - D.QTY                                         QTY,
         DECODE(D.QTY, 0, 0, D.TOTAL / D.QTY)            PRICE,
   			D.RTLPRC RTLPRC,
         - D.TOTAL                                       TOTAL, -d.tax TAX,
         DECODE(D.QTY, 0, 0, (D.CAMT + D.CTAX) / D.QTY)  IPRICE,
         - (D.CAMT + D.CTAX)                             ITOTAL,
         - D.CAMT                                        IAMT,
         - D.CTAX                                        ITAX,
         - (D.TOTAL - D.CAMT - D.CTAX)                   GP,
         - D.TOTAL                                       STDTOTAL,
         0                                               FAVAMT
    FROM STKOUTBCK A
   INNER JOIN STKOUTBCKDTL      D  ON A.NUM = D.NUM AND A.CLS = D.CLS
   INNER JOIN STKOUTBCKLOG      L  ON A.NUM = L.NUM AND A.CLS = L.CLS AND L.STAT IN (1000, 1020, 1040, 320, 340)
   INNER JOIN STORE             S  ON A.RECEIVER = S.GID
   INNER JOIN ORGGOODS          G  ON D.GDGID = G.GID
   INNER JOIN CLIENT            C  ON A.CLIENT = C.GID
   INNER JOIN STDRPT_V_SORTNAME SN ON G.SORT = SN.DSCODE
   INNER JOIN BRAND             BR ON G.BRAND = BR.CODE
   INNER JOIN TMP_DAYS          TD ON a.pm_return_time >= TD.BDATE AND a.pm_return_time < TD.EDATE
   WHERE 1 = 1
     AND A.CLS = '批发退'
    /*限制组织*/
     and G.orggid = {$currentorg}
     and (s.orggid = {$currentorg} OR {$currentorg}=1000000)
    /*数据授权*/
    #and {S.GID:$store}#
    #and {G.sort:$sort}#
    /*查询条件*/
    #and {G.code:pigdcode}#      /*商品代码*/
    #and {G.NAME:pigdname}#      /*商品名称*/
     AND EXISTS (SELECT 1 FROM GDINPUT GI2 WHERE G.GID = GI2.GID #AND {GI2.CODE:PIGDCODE2}#) /*商品条码*/
    #and {G.sort:pisort}#        /*类别代码*/
    #and {G.sort:pisortcode}#    /*类别代码*/
    #and {SN.CSNAME:pisortname}# /*类别名称*/
    #and {G.brand:pibrand}#      /*品牌代码*/
    #and {GB.code:pigdbusgate}#  /*状态代码*/
    
    #and {S.code:PISTOREGID}#    /*门店代码*/
    #and {S.AREA:PISTAREA}#      /*区域代码*/
    
    #and {C.CODE:PICLIENT}#      /*门店代码*/
    #and {NULL:PIPOSNO}#         /*收银机号*/
    #and {A.NUM:PIFLOWNO}#       /*流水号*/
    #and {A.CLS:PISALECLS}#      /*销售类型*/)


SELECT *
  FROM (SELECT T.POSNO    Register_No,  T.FLOWNO   Doc_No,T.platform,
               T.MEMBERNO Customer_ID,  T.EMPNAME  Cashier,
               T.FILDATE  Created_Date, T.DTIME  Pickup_time,  T.OCRDATE  Server_time,
               DECODE(SIGN(T.QTY), -1, 'Return', 'Sale')  Type,
               '[' || T.STCODE  || ']' || T.STNAME  Store,
               T.GDCODE  Item_code,        
               T.GDCODE2 Barcode,
               T.GDNAME  Description,
               T.GNAME   Description_CN,
        		T.RTLPRC RETAIL_PRICE,
               T.QTY      Sold_qty,        T.PRICE   Price_with_tax,
               T.TOTAL    AMT_WITH_TAX,
               T.TAX      TAX,
               round(T.TAX,0)      Rounded_TAX,
               T.STDTOTAL Net_amt,    
               T.FAVAMT   disc_amt
          FROM TMP_MAIN T
         WHERE 1 = 1
          #and {queryCondition}#
         ORDER BY T.FILDATE)
#{order by} #