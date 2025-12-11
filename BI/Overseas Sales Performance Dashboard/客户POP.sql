WITH date_ref AS (
  SELECT
    DATE('${start}') AS start,
    DATE('${end}') AS end,
    DATE_ADD('${start}', INTERVAL -DATEDIFF('${end}', '${start}') - 1 DAY) AS last_period_start,
    DATE_ADD('${start}', INTERVAL -1 DAY) AS last_period_end
),

base_sales AS (
  SELECT
  	c.cus_name,
    s.cus_2nd_cat_name,
    c.ec_platform,
    c.cus_contient_name as region,
    c.cus_contient_country as subsidiary,
    s.sale_country_name as sale_country,
    -- 当前月累计业绩
    SUM(CASE 
          WHEN s.trans_date BETWEEN dr.start AND dr.end
          THEN s.incl_tax_rmb_amt ELSE 0 
        END) AS CNY,
    -- 当前月累计销量
    SUM(CASE 
          WHEN s.trans_date BETWEEN dr.start AND dr.end
          THEN s.sale_qty ELSE 0 
        END) AS QTY,
    -- 当前月累计订单
    SUM(CASE 
          WHEN s.trans_date BETWEEN dr.start AND dr.end
          THEN s.ord_cnt ELSE 0 
        END) AS Order,
    -- 上月同期累计业绩
    SUM(CASE 
          WHEN s.trans_date BETWEEN dr.last_period_start AND dr.last_period_end
          THEN s.incl_tax_rmb_amt ELSE 0 
        END) AS  last_period_amt,
    -- 上月累计销量
    SUM(CASE 
          WHEN s.trans_date BETWEEN dr.last_period_start AND dr.last_period_end
          THEN s.sale_qty ELSE 0 
        END) AS  last_period_QTY,
    -- 上月累计订单
    SUM(CASE 
          WHEN s.trans_date BETWEEN dr.last_period_start AND dr.last_period_end
          THEN s.ord_cnt ELSE 0 
        END) AS  last_period_Order
  FROM dw.ads_customer_overseas_sales_daily AS s 
  LEFT JOIN dw.dim_customer_subsidiary AS c
  ON c.cus_code = s.cus_code
  JOIN date_ref dr ON 1=1
  WHERE 
  (
   ${dashboard_id} = '1'
   OR EXISTS (
        SELECT 1
        FROM dw.bi_overseas_region_rowauth r
        WHERE r.user_id = '${fine_username}'
          AND (
                 (r.sub_region_flag = 'region' AND (c.cus_contient_name = r.region_name OR r.region_name = 'ALL'))
              OR (r.sub_region_flag = 'sub'    AND c.cus_contient_country = r.sub_name)
          )
   )
)
and
  ((c.sub_id = '1' AND c.cus_2nd_cat_name = 'E-com')
OR (c.sub_id NOT IN ('28','21','15','22','24', '1','42')
and c.cus_contient_country NOT LIKE '%No performance%'))
and c.cus_contient_name is not null -- cus_contient_name为空不计入业绩
and s.trans_date BETWEEN DATE_ADD('${start}', INTERVAL -12 MONTH) AND '${end}' -- 足够包含3个区间
  and !(s.cus_id='13679' and s.sale_country_name in ('Taiwan (Province of China)','Hong Kong','China','Macao'))
group by
  c.cus_name,
  s.cus_2nd_cat_name,
  c.ec_platform,
  c.cus_contient_name,
  c.cus_contient_country,
  s.sale_country_name
)



SELECT
  cus_name,
  cus_2nd_cat_name,
  region,
  subsidiary,
  sale_country,
  ec_platform,
  CNY,
  QTY,
  Order,
  last_period_amt,
  last_period_QTY,
  last_period_Order
FROM base_sales
where 1=1 ${if(cus_name == '',"","and cus_name in ('" + cus_name + "')")} 
and 1=1 ${if(sale_country_name == '',"","and  sale_country_name in ('" + sale_country_name+ "')")} 
and 1=1 ${if(region == '',"","and  region in ('" + region+ "')")} 
and 1=1 ${if(subsidiary == '',"","and  subsidiary in ('" + subsidiary+ "')")} 
and 1=1 ${if(sub_name == '',"","and  sub_name in ('" + sub_name+ "')")} 
and 1=1 ${if(cus_2nd_cat_name == '',"","and  cus_2nd_cat_name in ('" + cus_2nd_cat_name+ "')")} 
and 1=1 ${if(ec_platform == '',"","and  ec_platform in ('" + ec_platform+ "')")}