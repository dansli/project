WITH date_ref AS (
  SELECT
    DATE('${trans_date}') AS cur_day,
    DATE_FORMAT('${trans_date}', '%Y-%m-01') AS cur_month_start,
    DATE_FORMAT(DATE_ADD('${trans_date}', INTERVAL -1 MONTH), '%Y-%m-01') AS last_month_start,
    DATE_ADD('${trans_date}', INTERVAL -1 MONTH) AS last_month_end,
    DATE_FORMAT(DATE_ADD('${trans_date}', INTERVAL -12 MONTH), '%Y-%m-01') AS last_year_month_start,
    DATE_ADD('${trans_date}', INTERVAL -12 MONTH) AS last_year_month_end
),

base_sales AS (
  SELECT
    s.trans_date,
    c.cus_contient_name AS Region,
    s.sale_country_name,
    s.incl_tax_rmb_amt,
    case when s.cus_2nd_cat_name = 'E-com' then 'Online' else 'Offline' end as cus_2nd_cat_name
  FROM dw.ads_customer_overseas_sales_daily AS s 
  LEFT JOIN dw.dim_customer_subsidiary AS c
    ON c.cus_code = s.cus_code
  WHERE 
-- 行权限位置
  (
    (c.sub_id = '1' AND c.cus_2nd_cat_name = 'E-com') OR
    (c.sub_id NOT IN ('28','21','15','22','24', '1','42') AND c.cus_contient_country NOT LIKE '%No performance%')
  )
  AND c.cus_contient_name IS NOT NULL
  AND s.trans_date BETWEEN DATE_FORMAT(DATE_ADD('${trans_date}', INTERVAL -12 MONTH), '%Y-%m-01') AND '${trans_date}' -- 足够包含3个区间
 and !(s.cus_id='13679' and s.sale_country_name in ('Taiwan (Province of China)','Hong Kong','China','Macao'))
),

agg_sales AS (
  SELECT
    Region,
    sale_country_name,
   cus_2nd_cat_name,
    -- 当前月累计
    SUM(CASE 
          WHEN s.trans_date BETWEEN dr.cur_month_start AND dr.cur_day 
          THEN s.incl_tax_rmb_amt ELSE 0 
        END) AS Month_CNY_MTD,

    -- 上月同期累计
    SUM(CASE 
          WHEN s.trans_date BETWEEN dr.last_month_start AND dr.last_month_end
          THEN s.incl_tax_rmb_amt ELSE 0 
        END) AS amt_last_month,

    -- 去年同月累计
    SUM(CASE 
          WHEN s.trans_date BETWEEN dr.last_year_month_start AND dr.last_year_month_end
          THEN s.incl_tax_rmb_amt ELSE 0 
        END) AS amt_last_year

  FROM base_sales s
  JOIN date_ref dr ON 1=1
  GROUP BY Region, sale_country_name
  ,cus_2nd_cat_name
)

SELECT
  DAY('${trans_date}') / DAY(LAST_DAY('${trans_date}')) AS Month_Progress,
  sale.Region,
  sale.sale_country_name,
  sale.Month_CNY_MTD,
  sale.cus_2nd_cat_name,
  sale.amt_last_month,
  sale.amt_last_year,
  -- 环比 MoM
  CASE WHEN amt_last_month != 0 THEN ROUND((Month_CNY_MTD - amt_last_month) / amt_last_month, 4) ELSE NULL END AS MOM,
  -- 同比 YoY
  CASE WHEN amt_last_year != 0 THEN ROUND((Month_CNY_MTD - amt_last_year) / amt_last_year, 4) ELSE NULL END AS YOY,
  sale.Month_CNY_MTD / SUM(sale.Month_CNY_MTD) OVER (PARTITION BY sale.Subsidiary) as ratio
FROM agg_sales as sale
where 1=1 ${if(Subsidiary == '',"","and   Subsidiary in ('" + Subsidiary + "')")} 
and 1=1 ${if(Region == '',"","and   Region in ('" + Region + "')")} 
and 1=1 ${if(cus_name == '',"","and   cus_name in ('" + cus_name + "')")} 
and 1=1 ${if(cus_2nd_cat_name == '',"","and   sale.cus_2nd_cat_name in ('" + cus_2nd_cat_name + "')")} 