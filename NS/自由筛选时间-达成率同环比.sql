WITH date_ref AS (
  SELECT
    DATE('${start}') AS start_day,
    DATE('${end}') AS end_day
    DATE_ADD('${start}', INTERVAL -1 MONTH) AS last_month_start,
    DATE_ADD('${end}', INTERVAL -1 MONTH) AS last_month_end,
    DATE_ADD('${start}', INTERVAL -12 MONTH) AS last_year_start,
    DATE_ADD('${end}', INTERVAL -12 MONTH) AS last_year_end
),
base_sales AS (
  SELECT
    s.trans_date,
    c.cus_name,
    s.cus_id,
    s.cus_code,
    c.cus_2nd_cat_name,
    c.cus_contient_name AS Region,
    c.cus_contient_country AS Subsidiary,
    s.incl_tax_rmb_amt
  FROM dw.ads_customer_overseas_sales_daily AS s 
  LEFT JOIN dw.dim_customer_subsidiary AS c
    ON c.cus_code = s.cus_code
  WHERE (
    (c.sub_id = '1' AND c.cus_2nd_cat_name = 'E-com') OR
    (c.sub_id NOT IN ('28','21','15','22','24', '1') AND c.cus_contient_country NOT LIKE '%No performance%')
  )
  AND c.cus_contient_name IS NOT NULL
  AND s.trans_date BETWEEN DATE_ADD('${start}', INTERVAL -12 MONTH) AND '${end}'
),
agg_sales AS (
  SELECT
    Region,
    Subsidiary,
    cus_code,
    cus_id,
    cus_name,
    cus_2nd_cat_name,
    -- 当前月累计
    SUM(CASE 
          WHEN s.trans_date BETWEEN dr.start_day AND dr.end_day 
          THEN s.incl_tax_rmb_amt ELSE 0 
        END) AS Month_CNY_MTD,

    -- 上月同期累计
    SUM(CASE 
          WHEN s.trans_date BETWEEN dr.last_month_start AND dr.last_month_end
          THEN s.incl_tax_rmb_amt ELSE 0 
        END) AS amt_last_month,

    -- 去年同月累计
    SUM(CASE 
          WHEN s.trans_date BETWEEN dr.last_year_start AND dr.last_year_end
          THEN s.incl_tax_rmb_amt ELSE 0 
        END) AS amt_last_year
  FROM base_sales s
  JOIN date_ref dr ON 1=1
  GROUP BY Region, Subsidiary, cus_id, cus_name,cus_code,cus_2nd_cat_name
)

SELECT
-- DAY('${trans_date}') / DAY(LAST_DAY('${trans_date}')) AS Month_Progress,
  sale.cus_id,
  sale.cus_code,
  sale.cus_name,
  sale.cus_2nd_cat_name,
  sale.Region,
  sale.Subsidiary,
  sale.Month_CNY_MTD,
  avg(bug.month_bgt_amt) as Month_Target,
  ifnull(sale.Month_CNY_MTD/bug.month_bgt_amt,0) as Month_Target_Reach,
  sale.amt_last_month,
  sale.amt_last_year,
  -- 环比 MoM
  CASE WHEN amt_last_month != 0 THEN ROUND((Month_CNY_MTD - amt_last_month) / amt_last_month, 4) ELSE NULL END AS MOM,
  -- 同比 YoY
  CASE WHEN amt_last_year != 0 THEN ROUND((Month_CNY_MTD - amt_last_year) / amt_last_year, 4) ELSE NULL END AS YOY
FROM agg_sales as sale
left join dw.ads_customer_month_budget as bug
on sale.cus_code = bug.cus_code and DATE_FORMAT(bug.bgt_date, '%Y-%m')=DATE_FORMAT('${trans_date}', '%Y-%m')
where 1=1 ${if(Subsidiary == '',"","and   Subsidiary in ('" + Subsidiary + "')")} 
and 1=1 ${if(Region == '',"","and   Region in ('" + Region + "')")} 
and 1=1 ${if(cus_name == '',"","and   cus_name in ('" + cus_name + "')")} 
and 1=1 ${if(cus_2nd_cat_name == '',"","and   cus_2nd_cat_name in ('" + cus_2nd_cat_name + "')")} 