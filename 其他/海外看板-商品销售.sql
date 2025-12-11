SELECT 
s.trans_date,
c.sub_name,
s.cus_id,
c.cus_code,
c.cus_name,
s.ec_platform,
s.sale_country_name as sale_country,
s.cus_2nd_cat_name,
c.cus_contient_name as region,
c.cus_contient_country as subsidiary,
s.tran_cur_name,
s.sku_code,
s.sku_barcode,
s.sku_name,
g.sku_name_en,
g.bus_cat_name1,
g.bus_cat_name2,
g.bus_cat_name3,
g.pro_cat_name1,
g.pro_cat_name2,
g.pro_cat_name3,
g.first_class_name_cn,
g.first_class_name_en,
g.second_class_name_cn,
g.second_class_name_en,
g.oversea_ip_name,
g.launch_date,
sum(s.sale_qty) as QTY,
sum(s.incl_tax_rmb_amt) as CNY,
sum(s.incl_tax_foreign_amt) as incl_tax_foreign_amt
from dw.ads_sku_overseas_sales_daily as s
left join dw.dim_goods as g   
on s.sku_code=g.sku_code
left join dw.dim_customer_subsidiary as c
on c.cus_code=s.cus_code
where 
exists (
    select 1
    from dw.bi_overseas_region_rowauth r
    where r.user_id = '${fine_username}'
      and (
             (r.sub_region_flag = 'region' and c.cus_contient_name = r.region_name or region_name='ALL')
          or (r.sub_region_flag = 'sub'    and c.cus_contient_country = r.sub_name)
      )
)
and
((c.sub_id = '1' AND c.cus_2nd_cat_name = 'E-com')
OR (c.sub_id NOT IN ('28','21','15','22','24', '1','42') AND c.cus_contient_country NOT LIKE '%No performance%'))
and c.cus_contient_name is not null
and s.trans_date between '${start}' and '${end}'
and 1=1 ${if(cus_contient_country == '',"","and c.cus_contient_country in ('" + cus_contient_country + "')")} 
and 1=1 ${if(cus_contient_name == '',"","and  c.cus_contient_name in ('" + cus_contient_name + "')")} 
and 1=1 ${if(cus_name == '',"","and  c.cus_name in ('" + cus_name + "')")} 
and 1=1 ${if(cus_2nd_cat_name == '',"","and  s.cus_2nd_cat_name in ('" + cus_2nd_cat_name + "')")} 
group by 
s.trans_date,
c.sub_name,
s.cus_id,
c.cus_code,
c.cus_name,
s.ec_platform,
s.sale_country_name,
s.cus_2nd_cat_name,
c.cus_contient_name,
c.cus_contient_country,
s.tran_cur_name,
s.sku_code,
s.sku_barcode,
s.sku_name,
g.sku_name_en,
g.bus_cat_name1,
g.bus_cat_name2,
g.bus_cat_name3,
g.pro_cat_name1,
g.pro_cat_name2,
g.pro_cat_name3,
g.first_class_name_cn,
g.first_class_name_en,
g.second_class_name_cn,
g.second_class_name_en,
g.oversea_ip_name,
g.launch_date