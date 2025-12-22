create table dw.dws_trans_detail_mb_daily (
  order_create_time        datetime comment '订单创建时间',
  order_express_time       datetime comment '订单发货时间',
  platform_order_id        varchar   comment '平台订单ID',
  shop_id                  varchar   comment '店铺ID',
  shop_code                varchar   comment '店铺代码',
  shop_name                varchar   comment '店铺名称',
  platform_id              varchar   comment '平台ID',
  platform_name            varchar   comment '平台名称',
  country_code             varchar   comment '国家code',
  country_name_en          varchar   comment '国家名称英文',
  country_name_cn          varchar   comment '国家名称中文',
  continent_name_biz       varchar   comment '业务定义大区名称中文',
  continent_name_biz_en    varchar   comment '业务定义大区名称英文',
  item_name                varchar   comment '商品名称',
  stock_sku                varchar   comment '商品编码',
  box_qty                  double   comment '整盒数量',
  single_qty               double   comment '单个数量',
  primary key(order_create_time,platform_order_id,shop_id,)
)
comment '马帮交易明细-订单SKU粒度-盒/个拆分'
;



insert into dw.dws_trans_detail_mb_daily
select
  mb.order_create_time, -- 订单创建时间
  mb.order_express_time, -- 订单发货时间
  mb.platform_order_id, -- 平台订单id
  mb.shop_id, -- 店铺ID
  mb.shop_code, -- 店铺代码
  mb.shop_name, -- 店铺名称
  mb.platform_id, -- 平台ID
  mb.platform_name, -- 平台名称
  mb.country_code, -- 国家代码
  mb.country_name_en, -- 国家名称英文
  mb.country_name_cn, -- 国家名称中文
  mb.continent_name_biz, -- 业务定义大区名称中文
  decode(mb.continent_name_biz, 
  '美洲区','NA','欧洲区','EU','亚太区','APAC','港澳台地区','GC','非洲区','AF',
  mb.continent_name_biz) as continent_name_biz_en, -- 业务定义大区名称英文
--   mb.warehouse_code,
--   mb.warehouse_name,
--   mb.warehouse_type,
  mb.item_name, -- 商品名称
  mb.stock_sku, -- 商品编码
  floor(sum(mb.item_sales_count) / g.box_spec_ns) as box_qty, -- 整盒数量
  mod(sum(mb.item_sales_count), g.box_spec_ns) as single_qty -- 单个数量
from
  dw.dws_itemsales_detail_mb as mb
  left join dw.dim_goods as g on mb.stock_sku = g.sku_code
group by
  mb.order_create_time,
  mb.order_express_time,
  mb.platform_order_id,
  mb.shop_id,
  mb.shop_code,
  mb.shop_name,
  mb.platform_id,
  mb.platform_name,
  mb.country_code,
  mb.country_name_en,
  mb.country_name_cn,
  mb.continent_name_biz,
  decode(mb.continent_name_biz, 
  '美洲区','NA','欧洲区','EU','亚太区','APAC','港澳台地区','GC','非洲区','AF',
  mb.continent_name_biz),
--   mb.warehouse_code,
--   mb.warehouse_name,
--   mb.warehouse_type,
  mb.item_name,
  mb.stock_sku