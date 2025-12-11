/*
参考的是海鼎报表：渠道销售明细及汇总，以及强哥的原模型：zsd_dwb002。
强哥的模型同样参考的是海鼎报表，但是列出了更多的字段。

遵循原逻辑用的是goodsh，但个人更喜欢用goods。
goodsh和goods的区别，
goodsh比goods多几百条，但是肉眼看没有用；
goodsh的code，有几条是不唯一的。

client的在原报表里用做渠道，而不是客户。
单据类型的展示，在原报表里是写死了批发单而不是用的cls（批发）。

按强哥的原模型，可能还有用但暂没有加到模型里去的字段：
批发单
  so.NOTE AS ZNOTE, -- 备注
  sod.SRCNUM AS ZSRCNUM, -- 来源单号
  sod.TAX AS ZSALETAX, -- 税额
  sod.CAMT AS ZCAMT, -- 进价金额
  sod.CTAX AS ZCTAX, -- 进价税额
批发退货单
  sob.NOTE AS ZNOTE, -- 备注
  sobd.SRCNUM AS ZSRCNUM, -- 来源单号
  sobd.TAX*-1 AS ZSALETAX, -- 税额
  sobd.CAMT*-1 AS ZCAMT, -- 进价金额
  sobd.CTAX*-1 AS ZCTAX, -- 进价税额

状态枚举： 
320:完成后冲单(负单)
340:完成后修正单(负单)
700:已发货
720:发货后作废(负单)
740:发货后修正单(负单)
1000:已收货
1020:收货后冲单(负单)
1040:收货后修正单(负单)

stkout和stkoutbck的日期（stkoutbck没有senddate，有sendtime），有多个，
可能有意义的：
  OCRDATE,  -- 发生日期
  PAYDATE, -- 付款日期
  LSTUPDTIME, -- 最后更改时间
  FILDATE, -- 填单日期
  SENDDATE, -- 发送日期
  BUSDATE  -- 记账日期
其中只有最后更改时间和填单日期，是非空的，其它都可以是空值。
记账日期是后加的字段，adb的表里没有，历史数据里也都是空值，所以没法用。
所以还是采用原逻辑，用log表上的time。

stkout的抽取，用了lstuptime，但依然抽了90天的数据，这个要整改。
stkoutbck，则是用的FILDATE>=sysdate-310 and FILDATE<sysdate
这些抽取都应该整改。

分区表的问题，
如果创建分区表，则必须主键加入创建时间或记账日期，则难以保证主键覆盖。
而不创建分区表，则会影响build的性能。
按官方文档，建议单个分区在[6400万, 32000万]，目前总行数15000万，综合考虑，暂不创建分区表。

开始表名叫做dwd_hd_sales_order_detail_online，
这里其实有个问题，就是其实用线上这个词不够精准，因为包含了机器人、展会的销售，以及其它各个渠道的销售。
只要是非海鼎POS（即传统门店）产生的销售，都在该表里。
所以重构该表，表名改为：dwd_hd_wholesale_order_detail。

另外，为了更通用性，不在这里增加原逻辑：ifnull(sob.srccls,0) != 'customer_service' -- 排除掉由客服系统下发的单据
在后续模型里再增加该逻辑。

后续整改的两个点：
1. 最终要废掉强哥的zsd_dwb002；
2. 修正stkout和stkoutbck还有其他相关表的抽取逻辑。


2025-02-05
1. 增加吊牌价；
2. 增加批发类型，目前枚举：null、普通、换货、维修，其中null值用空字符串代替，以避免不小心造成的bug，后续可能会需要屏蔽掉换货；
3. 增加冲销原单号，在订单完成后(300或700，300已完成，700已发货)，可能会作废（310），作废后，会自动生成冲销的负单（320），会在冲销单上记录原单号；
4. 修正状态编码取值错误；
5. 将来源类型，null值用空字符串代替，之前是用0；

2025-02-06
1. 增加销售税额，用来计算不含税销售金额；
2. 增加进价金额，用来出含税成本；
3. 增加金价税额，用来计算不含税成本。
ALTER TABLE dw.dwd_hd_wholesale_order_detail 
  ADD sales_tax_amt decimal(24, 2) DEFAULT 0 COMMENT '销售税额',
  ADD cost_amt decimal(24, 2) DEFAULT 0 COMMENT '进价金额',
  ADD cost_tax_amt decimal(24, 2) DEFAULT 0 COMMENT '进价税额';


2025-03-10
没有改这块的逻辑，但是改了抽数的逻辑。
因为在未审核状态下，用户可能会修改明细行数据，这时候会造成数据物理删除，从而导致ADB多，海鼎少的情况。
所以在抽数的时候，增加了删除未审核的单子的逻辑。
stat = 0 是未审核状态。 

Exists(Select 1 From Stkout t 
Where t.lstupdtime >= TRUNC(sysdate - 5) 
  and t.Num = stkoutdtl.Num 
  and t.Cls = stkoutdtl.Cls 
  and t.stat != 0)

Exists(Select 1 From STKOUTBCK t 
Where lstupdtime >= TRUNC(sysdate - 5) 
  and t.Num = STKOUTBCKDTL.Num 
  and t.Cls =STKOUTBCKDTL.Cls 
  and t.stat != 0)
*/

CREATE TABLE if not exists dw.dwd_hd_wholesale_order_detail (
  sales_order_num varchar(14) COMMENT '销售单号',
  order_type varchar(16) COMMENT '单据类型',
  sales_order_line int COMMENT '销售单行号',
  trans_date date COMMENT '记账日期',
  trans_datetime datetime COMMENT '记账时间',
  store_id int COMMENT '门店id',
  store_code varchar(10) COMMENT '门店编码',
  store_name varchar(50) COMMENT '门店名称',
  sku_id int COMMENT '商品id',
  sku_code varchar(32) COMMENT '商品编码',
  sku_name varchar(80) COMMENT '商品名称',
  client_id int COMMENT '客户id',
  client_code varchar(20) COMMENT '客户编码',
  client_name varchar(80) COMMENT '客户名称',
  warehouse_id int COMMENT '仓位id',
  warehouse_code varchar(10) COMMENT '仓位代码',
  warehouse_name varchar(50) COMMENT '仓位名称',
  sales_qty decimal(24, 4) DEFAULT 0 COMMENT '销售数量',
  sales_amt decimal(24, 2) DEFAULT 0 COMMENT '销售金额',
  order_status int COMMENT '订单状态',
  order_status_name varchar(255) COMMENT '订单状态描述',
  source_type varchar(32) COMMENT '来源类型',
  created_datetime datetime COMMENT '创建时间',
  last_modified_datetime datetime COMMENT '最后修改时间',
  tag_amt decimal(24, 2) DEFAULT 0 COMMENT '吊牌价',
  wholesale_type varchar(16) COMMENT '批发类型',
  original_order_num varchar(14) COMMENT '冲销原单号',
  sales_tax_amt decimal(24, 2) DEFAULT 0 COMMENT '销售税额',
  cost_amt decimal(24, 2) DEFAULT 0 COMMENT '进价金额',
  cost_tax_amt decimal(24, 2) DEFAULT 0 COMMENT '进价税额',
  -- PRIMARY KEY (sales_order_num,order_type,created_datetime,sales_order_line)
  PRIMARY KEY (sales_order_num,order_type,sales_order_line)
) 
DISTRIBUTE BY HASH(sales_order_num,order_type) 
-- PARTITION BY VALUE(date_format(created_datetime,'%Y%m')) 
COMMENT='海鼎批发销售订单明细';


replace into dw.dwd_hd_wholesale_order_detail 
select 
  so.num as sales_order_num, -- 出货单单号
  so.cls as order_type, -- 单据类型
  sod.line as sales_order_line, -- 出货单行号
  date(sol.time) as trans_date, -- 记账日期
  sol.time as trans_datetime, -- 记账时间
  so.sender as store_id, -- 门店id
  s.code as store_code, -- 门店编码
  s.name as store_name, -- 门店名称
  sod.gdgid as sku_id, -- 商品id
  g.code as sku_code, -- 商品编码
  g.name as sku_name, -- 商品名称
  so.client as client_id, -- 客户id
  c.code as client_code, -- 客户编码
  c.name as client_name, -- 客户名称
  so.wrh as warehouse_id, -- 仓位id
  w.code as warehouse_code, -- 仓位代码
  w.name as warehouse_name, -- 仓位名称
  sod.qty as sales_qty, -- 销售数量
  sod.total as sales_amt, -- 销售金额
  so.stat as order_status, -- 订单状态
  ms.statname as order_status_name, -- 订单状态描述
  ifnull(so.srccls, '') as source_type, -- 来源类型
  so.fildate as created_datetime, -- 创建时间
  so.lstupdtime as last_modified_datetime, -- 最后修改时间
  sod.rtotal as tag_amt, -- 吊牌价
  ifnull(so.def_wholesaletype, '') as wholesale_type, -- 批发类型
  so.modnum as original_order_num, -- 冲销原单号
  sod.tax as sales_tax_amt, -- 销售税额
  sod.camt + sod.ctax as cost_amt, -- 进价金额
  sod.ctax as cost_tax_amt -- 进价税额
from sds.stkoutdtl as sod -- 出货单明细
inner join sds.stkout as so -- 出货单
on sod.num = so.num 
and sod.cls = so.cls
inner join sds.stkoutlog as sol -- 出货单日志
on so.num = sol.num
and so.cls = sol.cls
and sol.stat in (320, 340, 700, 720, 740, 1020, 1040) -- 状态 
inner join sds.store as s -- 门店
on so.sender = s.gid
inner join sds.goodsh as g -- 商品
on sod.gdgid = g.gid
inner join sds.client as c -- 客户
on so.client = c.gid
left join sds.warehouse as w -- 仓位
on so.sender = w.storegid 
and so.wrh = w.gid
inner join sds.modulestat as ms -- 状态 
on so.stat = ms.no 
where so.cls = '批发' 
  and so.lstupdtime >= date_sub(curdate(),interval 2 day)
  -- and so.lstupdtime >= curdate()
union all 
select 
  sob.num as sales_order_num, -- 出货退货单号
  sob.cls as order_type, -- 单据类型
  sobd.line as sales_order_line, -- 出货退货单行号
  date(sobl.time) as trans_date, -- 记账日期
  sobl.time as trans_datetime, -- 记账时间
  sob.receiver as store_id, -- 门店id
  s.code as store_code, -- 门店编码
  s.name as store_name, -- 门店名称
  sobd.gdgid as sku_id, -- 商品id
  g.code as sku_code, -- 商品编码
  g.name as sku_name, -- 商品名称
  sob.client as client_id, -- 客户id
  c.code as client_code, -- 客户编码
  c.name as client_name, -- 客户名称
  sob.wrh as warehouse_id, -- 仓位id
  w.code as warehouse_code, -- 仓位代码
  w.name as warehouse_name, -- 仓位名称
  -sobd.qty as sales_qty, -- 销售数量
  -sobd.total as sales_amt, -- 销售金额
  sob.stat as order_status, -- 订单状态
  ms.statname as order_status_name, -- 订单状态描述
  ifnull(sob.srccls,'') as source_type, -- 来源类型
  sob.fildate as created_datetime, -- 创建时间
  sob.lstupdtime as last_modified_datetime, -- 最后修改时间
  -sobd.rtotal as tag_amt, -- 吊牌价
  '' as wholesale_type, -- 批发类型
  sob.modnum as original_order_num, -- 冲销原单号
  -sobd.tax as sales_tax_amt, -- 销售税额
  -sobd.camt - sobd.ctax as cost_amt, -- 进价金额
  -sobd.ctax as cost_tax_amt -- 进价税额
from sds.stkoutbckdtl as sobd -- 出货退货单明细
inner join sds.stkoutbck as sob -- 出货退货单
on sobd.num = sob.num
and sobd.cls = sob.cls
inner join sds.stkoutbcklog as sobl -- 出货退货单日志
on sob.num = sobl.num
and sob.cls = sobl.cls
and sobl.stat in (320, 340, 1000, 1020, 1040) -- 状态
inner join sds.store as s -- 门店
on sob.receiver = s.gid
inner join sds.goodsh as g -- 商品
on sobd.gdgid = g.gid
inner join sds.client as c -- 客户
on sob.client = c.gid
left join sds.warehouse as w -- 仓位
on sob.receiver = w.storegid
and sob.wrh = w.gid
inner join sds.modulestat as ms -- 状态
on sob.stat = ms.no
where sob.cls = '批发退' 
  and sob.lstupdtime >= date_sub(curdate(),interval 2 day)
  -- and sob.lstupdtime >= curdate()

