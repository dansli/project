delete from dw.ads_sku_overseas_sales_daily
where
  trans_date >= date_sub(CURDATE(), interval 3 MONTH);

INSERT INTO
  dw.ads_sku_overseas_sales_daily
SELECT
  CAST(t.biz_date AS DATE) as trans_date,
  c.cus_code,
  t.entity_id as cus_id,
  c.ec_platform,
  t.sale_country_name,
  c.cus_2nd_cat_name,
  t.item_id as sku_code,
  g.sku_barcode,
  g.sku_name,
  t.currency_id as tran_cur_code,
  t.currency_name as tran_cur_name,  
  sum(t.sale_qty) as sale_qty,
  sum(t.incl_tax_rmb_amt) as incl_tax_rmb_amt,
  sum(tax_rmb_amt) as tax_rmb_amt,
  sum(excl_tax_rmb_amt) as excl_tax_rmb_amt,
  sum(t.incl_tax_foreign_amt) as incl_tax_foreign_amt,
  sum(tax_amt) as tax_amt,
  sum(excl_tax_foreign_amt) as excl_tax_foreign_amt
from
  dw.dwd_inv_trans_line as t
  left JOIN dw.dim_goods as g on t.item_id = g.sku_code
  left join dw.dim_customer_subsidiary as c on t.entity_id = c.cus_id
where c.cus_2nd_cat_name ='KA' 
  and t.biz_date >= date_sub(CURDATE(), interval 3 MONTH)
  AND t.trans_item_type NOT IN('EndGroup','TaxGroup','TaxItem','Service')
  AND t.is_imp_inv = 0
  AND t.is_cogs = 0
group by
  CAST(t.biz_date AS DATE),
  c.cus_code,
  t.entity_id,  
  c.ec_platform,
  t.sale_country_name,
  c.cus_2nd_cat_name,
  t.item_id,
  g.sku_barcode,
  g.sku_name,
  t.currency_id,
  t.currency_name 

union all

SELECT
  CAST(t.biz_date AS DATE) as trans_date,
  c.cus_code,
  t.entity_id as cus_id, 
  c.ec_platform, 
  t.sale_country_name,
  c.cus_2nd_cat_name,
  t.item_id as sku_code,
  g.sku_barcode,
  g.sku_name,
  t.currency_id as tran_cur_code,
  t.currency_name as tran_cur_name,  
  sum(t.sale_qty) as sale_qty,
  sum(t.incl_tax_rmb_amt) as incl_tax_rmb_amt,
  sum(tax_rmb_amt) as tax_rmb_amt,
  sum(excl_tax_rmb_amt) as excl_tax_rmb_amt,
  sum(t.incl_tax_foreign_amt) as incl_tax_foreign_amt,
  sum(tax_amt) as tax_amt,
  sum(excl_tax_foreign_amt) as excl_tax_foreign_amt
from
  dw.dwd_so_trans_line as t
  left JOIN dw.dim_goods as g on t.item_id = g.sku_code
  left join dw.dim_customer_subsidiary as c on t.entity_id = c.cus_id
where c.cus_2nd_cat_name in ('Store','EXPO','ROBOshop')
  and t.biz_date >= date_sub(CURDATE(), interval 3 MONTH)
  AND t.trans_item_type NOT IN('EndGroup','TaxGroup','TaxItem','Service')
  AND t.is_imp_inv = 0
  AND t.is_cogs = 0
group by
  CAST(t.biz_date AS DATE),
  c.cus_code,
  t.entity_id,  
  c.ec_platform,
  t.sale_country_name,
  c.cus_2nd_cat_name,
  t.item_id,
  g.sku_barcode,
  g.sku_name,
  t.currency_id,
  t.currency_name 
union all

SELECT
  CAST(t.biz_date AS DATE) as trans_date,
  case when c.cus_code='C0128' then
    case when t.sale_country_name='Thailand' then 'C31095'
         when t.sale_country_name='Malaysia' then 'C31096'
         when t.sale_country_name='Philippines' then 'C31097'
         when t.sale_country_name='Viet Nam' then 'C31098'
         when t.sale_country_name='Singapore' then 'C31099'
         when t.sale_country_name='Australia' then 'C31100'
         when t.sale_country_name='New Zealand' then 'C31101'
         when t.sale_country_name='Japan' then 'C31102'
         when t.sale_country_name='Korea (the Republic of)' then 'C31103'
         else 'C31104'
         end 
  else c.cus_code end as cus_code,
  case when t.entity_id='2323' then
    case when t.sale_country_name='Thailand' then '13670'
         when t.sale_country_name='Malaysia' then '13671'
         when t.sale_country_name='Philippines' then '13672'
         when t.sale_country_name='Viet Nam' then '13673'
         when t.sale_country_name='Singapore' then '13674'
         when t.sale_country_name='Australia' then '13675'
         when t.sale_country_name='New Zealand' then '13676'
         when t.sale_country_name='Japan' then '13677'
         when t.sale_country_name='Korea (the Republic of)' then '13678'
         else '13679'
         end 
  else t.entity_id end as cus_id,
  c.ec_platform,
  t.sale_country_name,  
  c.cus_2nd_cat_name,
  t.item_id as sku_code,
  g.sku_barcode,
  g.sku_name,
  t.currency_id as tran_cur_code,
  t.currency_name as tran_cur_name,  
  sum(t.sale_qty) as sale_qty,
  sum(t.incl_tax_rmb_amt) as incl_tax_rmb_amt,
  sum(tax_rmb_amt) as tax_rmb_amt,
  sum(excl_tax_rmb_amt) as excl_tax_rmb_amt,
  sum(t.incl_tax_foreign_amt) as incl_tax_foreign_amt,
  sum(tax_amt) as tax_amt,
  sum(excl_tax_foreign_amt) as excl_tax_foreign_amt
from
  dw.dwd_so_trans_line as t
  left JOIN dw.dim_goods as g on t.item_id = g.sku_code
  left join dw.dim_customer_subsidiary as c on t.entity_id = c.cus_id
where c.cus_2nd_cat_name = 'E-com' 
  and (c.sub_id not in ('28','17','18') 
  or (c.sub_id = '18' and t.biz_date >= '2025-08-01')
  or (c.sub_id = '17' and t.biz_date >= '2026-01-01'))
  and t.biz_date >= date_sub(CURDATE(), interval 3 MONTH)
  AND t.trans_item_type NOT IN('EndGroup','TaxGroup','TaxItem','Service')
  AND t.is_imp_inv = 0
  AND t.is_cogs = 0
group by
  CAST(t.biz_date AS DATE),
  case when c.cus_code='C0128' then
    case when t.sale_country_name='Thailand' then 'C31095'
         when t.sale_country_name='Malaysia' then 'C31096'
         when t.sale_country_name='Philippines' then 'C31097'
         when t.sale_country_name='Viet Nam' then 'C31098'
         when t.sale_country_name='Singapore' then 'C31099'
         when t.sale_country_name='Australia' then 'C31100'
         when t.sale_country_name='New Zealand' then 'C31101'
         when t.sale_country_name='Japan' then 'C31102'
         when t.sale_country_name='Korea (the Republic of)' then 'C31103'
         else 'C31104'
         end 
  else c.cus_code end,
  case when t.entity_id='2323' then
    case when t.sale_country_name='Thailand' then '13670'
         when t.sale_country_name='Malaysia' then '13671'
         when t.sale_country_name='Philippines' then '13672'
         when t.sale_country_name='Viet Nam' then '13673'
         when t.sale_country_name='Singapore' then '13674'
         when t.sale_country_name='Australia' then '13675'
         when t.sale_country_name='New Zealand' then '13676'
         when t.sale_country_name='Japan' then '13677'
         when t.sale_country_name='Korea (the Republic of)' then '13678'
         else '13679'
         end 
  else t.entity_id end,  
  c.ec_platform,
  t.sale_country_name,
  c.cus_2nd_cat_name,
  t.item_id,
  g.sku_barcode,
  g.sku_name,
  t.currency_id,
  t.currency_name

union all 
-- 韩台的电商走inv(没有so单) 日本的电商从2025.8.1开始走so，之前走inv
SELECT 
  CAST(t.biz_date AS DATE) as trans_date,
  c.cus_code,
  t.entity_id as cus_id,
  c.ec_platform,
  t.sale_country_name,
  c.cus_2nd_cat_name,
  t.item_id as sku_code,
  g.sku_barcode,
  g.sku_name,
  t.currency_id as tran_cur_code,
  t.currency_name as tran_cur_name,  
  sum(t.sale_qty) as sale_qty,
  sum(t.incl_tax_rmb_amt) as incl_tax_rmb_amt,
  sum(tax_rmb_amt) as tax_rmb_amt,
  sum(excl_tax_rmb_amt) as excl_tax_rmb_amt,
  sum(t.incl_tax_foreign_amt) as incl_tax_foreign_amt,
  sum(tax_amt) as tax_amt,
  sum(excl_tax_foreign_amt) as excl_tax_foreign_amt
from
  dw.dwd_inv_trans_line as t
  left JOIN dw.dim_goods as g on t.item_id = g.sku_code
  left join dw.dim_customer_subsidiary as c on t.entity_id = c.cus_id
where c.cus_2nd_cat_name = 'E-com' 
  and (c.sub_id in ('28') 
  or (c.sub_id = '18' and t.biz_date < '2025-08-01')
  or (c.sub_id = '17' and t.biz_date < '2026-01-01'))
  and t.biz_date >= date_sub(CURDATE(), interval 3 MONTH)
  AND t.trans_item_type NOT IN('EndGroup','TaxGroup','TaxItem','Service')
  AND t.is_imp_inv = 0
  AND t.is_cogs = 0
group by
  CAST(t.biz_date AS DATE),
  c.cus_code,
  t.entity_id,  
  c.ec_platform,
  t.sale_country_name,
  c.cus_2nd_cat_name,
  t.item_id,
  g.sku_barcode,
  g.sku_name,
  t.currency_id,
  t.currency_name 
union all 
-- others客户计入业绩，需要保留service
SELECT
  CAST(t.biz_date AS DATE) as trans_date,
  c.cus_code,
  t.entity_id as cus_id,
  c.ec_platform,
  t.sale_country_name,
  c.cus_2nd_cat_name,
  t.item_id as sku_code,
  g.sku_barcode,
  g.sku_name,
  t.currency_id as tran_cur_code,
  t.currency_name as tran_cur_name,  
  sum(t.sale_qty) as sale_qty,
  sum(t.excl_tax_rmb_amt) as incl_tax_rmb_amt,
  sum(tax_rmb_amt) as tax_rmb_amt,
  sum(t.excl_tax_rmb_amt) as excl_tax_rmb_amt,
  sum(t.excl_tax_foreign_amt) as incl_tax_foreign_amt,
  sum(tax_amt) as tax_amt,
  sum(excl_tax_foreign_amt) as excl_tax_foreign_amt
from
  dw.dwd_inv_trans_line as t
  left JOIN dw.dim_goods as g on t.item_id = g.sku_code
  left join dw.dim_customer_subsidiary as c on t.entity_id = c.cus_id
where c.cus_2nd_cat_name ='Others' 
  and t.biz_date >= date_sub(CURDATE(), interval 3 MONTH)
  AND t.trans_item_type NOT IN('EndGroup','TaxGroup','TaxItem')
  AND t.is_imp_inv = 0
  AND t.is_cogs = 0
group by
  CAST(t.biz_date AS DATE),
  c.cus_code,
  t.entity_id,  
  c.ec_platform,
  t.sale_country_name,
  c.cus_2nd_cat_name,
  t.item_id,
  g.sku_barcode,
  g.sku_name,
  t.currency_id,
  t.currency_name 