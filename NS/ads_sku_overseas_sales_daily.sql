SELECT 
t.item_id as sku_code,
t.currency_id as tran_cur_code,
t.currency_name as tran_cur_name,
t.trans_date,
sum(t.sale_qty),
sum(t.incl_tax_rmb_amt),
sum(t.incl_tax_foreign_amt),
t.entity_id as cus_id,
c.cus_code,
g.sku_barcode,
g.sku_name 
from
dw.dwd_trans_line as t
left JOIN 
dw.dim_goods as g
on t.item_id = g.sku_code
left join dw.dim_customer_subsidiary as c
on t.entity_id = c.cus_id
group by
t.item_id,
t.currency_id,
t.currency_name,
t.entity_id,
c.cus_code,
g.sku_barcode,
g.sku_name 




 
SELECT 
t.item_id,
t.currency_id,
t.currency_name,
t.trans_date,
t.sale_qty,
t.incl_tax_rmb_amt,
t.incl_tax_foreign_amt,
t.entity_id,
t.entity_name,
g.sku_barcode,
g.sku_display_name,
g.sku_name_en,
g.bus_cat_code1,
g.bus_cat_name1,
g.bus_cat_code2,
g.bus_cat_name2,
g.bus_cat_code3,
g.bus_cat_name3,
g.pro_cat_code,
g.pro_cat_name1,
g.pro_cat_code2,
g.pro_cat_name2,
g.pro_cat_code3,
g.pro_cat_name3,
g.first_class_name_cn,
g.first_class_name_en,
g.first_class_code,
g.second_class_name_cn,
g.second_class_name_en,
g.second_class_code,
g.ip_name,
g.launch_date
from
dw.dwd_trans_line as t
left JOIN 
dw.dim_goods as g
on t.item_id = g.sku_code


CREATE TABLE dw.ads_sku_overseas_sales_daily (
    sku_code VARCHAR COMMENT '商品编码',
    sku_barcode VARCHAR COMMENT '商品条码',
    sku_display_name VARCHAR COMMENT 'ns商品名称',
    sku_name_en VARCHAR COMMENT 'ns商品英文名称',
    bus_cat_code1 VARCHAR COMMENT '商业一级编码',
    bus_cat_name1 VARCHAR COMMENT '商业一级名称',
    bus_cat_code2 VARCHAR COMMENT '商业二级编码',
    bus_cat_name2 VARCHAR COMMENT '商业二级名称',
    bus_cat_code3 VARCHAR COMMENT '商业三级编码',
    bus_cat_name3 VARCHAR COMMENT '商业三级名称',
    pro_cat_code VARCHAR COMMENT '产品大类编码',
    pro_cat_name1 VARCHAR COMMENT '产品大类名称',
    pro_cat_code2 VARCHAR COMMENT '产品中类编码',
    pro_cat_name2 VARCHAR COMMENT '产品中类名称',
    pro_cat_code3 VARCHAR COMMENT '产品小类编码',
    pro_cat_name3 VARCHAR COMMENT '产品小类名称',
    first_class_name_cn VARCHAR COMMENT '海外一级分类中文',
    first_class_name_en VARCHAR COMMENT '海外一级分类英文',
    first_class_code VARCHAR COMMENT '海外一级分类编码',
    second_class_name_cn VARCHAR COMMENT '海外二级分类中文',
    second_class_name_en VARCHAR COMMENT '海外二级分类英文',
    second_class_code VARCHAR COMMENT '海外二级分类编码',
    ip_name VARCHAR COMMENT 'IP',
    tran_cur_code BIGINT COMMENT '交易货币代码',
    tran_cur_name VARCHAR COMMENT '交易货币名称',
    trans_date VARCHAR COMMENT '交易日期（yyyy-mm-dd）',
    launch_date DATETIME COMMENT '上市日期',
    entity_id BIGINT COMMENT '实体id',
    entity_name VARCHAR COMMENT '实体名称',
    sale_qty DOUBLE COMMENT '销量',
    incl_tax_rmb_amt DOUBLE COMMENT '人民币含税业绩',
    incl_tax_foreign_amt DOUBLE COMMENT '外币金额（含税）',
    PRIMARY KEY (sku_barcode)
) COMMENT = '海外销售数据表';




TRUNCATE TABLE dw.ads_sku_overseas_sales_daily;
INSERT INTO dw.ads_sku_overseas_sales_daily
SELECT 
t.item_id,
t.currency_id,
t.currency_name,
t.trans_date,
t.sale_qty,
t.incl_tax_rmb_amt,
t.incl_tax_foreign_amt,
t.entity_id,
t.entity_name,
g.sku_barcode,
g.sku_display_name,
g.sku_name_en,
g.bus_cat_code1,
g.bus_cat_name1,
g.bus_cat_code2,
g.bus_cat_name2,
g.bus_cat_code3,
g.bus_cat_name3,
g.pro_cat_code,
g.pro_cat_name1,
g.pro_cat_code2,
g.pro_cat_name2,
g.pro_cat_code3,
g.pro_cat_name3,
g.first_class_name_cn,
g.first_class_name_en,
g.first_class_code,
g.second_class_name_cn,
g.second_class_name_en,
g.second_class_code,
g.ip_name,
g.launch_date
from
dw.dwd_trans_line as t
left JOIN 
dw.dim_goods as g
on t.item_id = g.sku_code