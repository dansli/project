WITH base_sales AS (
  SELECT
    c.cus_name,
    s.cus_id,
    s.cus_code,
    s.trans_date,
  	c.sub_name,
  	c.cus_2nd_cat_name,
    DATE_FORMAT(s.trans_date, '%Y-%m') AS trans_month,
    DATE_FORMAT(s.trans_date, '%Y') AS trans_year,
    s.incl_tax_rmb_amt,
    s.incl_tax_foreign_amt
  FROM dw.ads_customer_overseas_sales_daily AS s 
  LEFT JOIN dw.dim_customer_subsidiary AS c
    ON c.cus_id = s.cus_id
where   (c.sub_id = '1' AND c.cus_2nd_cat_name = 'E-com' )
  OR (c.sub_id NOT IN ('28','21','15','22','24', '1'))
),
sales_agg as(
SELECT
  trans_date,
  cus_name,
  cus_id,
  cus_code,
  sub_name,
  cus_2nd_cat_name,
  trans_month,
  trans_year,
  incl_tax_rmb_amt,
  SUM(incl_tax_rmb_amt) OVER (PARTITION BY cus_name,trans_month ORDER BY trans_date) AS cum_rmb_amt_month,
  SUM(incl_tax_rmb_amt) OVER (PARTITION BY cus_name,trans_year ORDER BY trans_date) AS cum_rmb_amt_year, 
  SUM(incl_tax_foreign_amt) OVER (PARTITION BY cus_name,trans_month ORDER BY trans_date) AS cum_foreign_amt_month,
  SUM(incl_tax_foreign_amt) OVER (PARTITION BY cus_name,trans_year ORDER BY trans_date) AS cum_foreign_amt_year
FROM base_sales),
sales_mom_yoy AS (
  SELECT
    curr.*,
    mom_prev.cum_rmb_amt_month AS last_month_cum_amt,
    yoy_prev.cum_rmb_amt_year AS last_year_cum_amt,
    ROUND((curr.cum_rmb_amt_month - mom_prev.cum_rmb_amt_month) / NULLIF(mom_prev.cum_rmb_amt_year, 0), 3) AS MOM,
    ROUND((curr.cum_rmb_amt_year - yoy_prev.cum_rmb_amt_year) / NULLIF(yoy_prev.cum_rmb_amt_year, 0), 3) AS YOY
  FROM sales_agg AS curr
  LEFT JOIN sales_agg AS mom_prev
    ON curr.cus_name = mom_prev.cus_name
   AND curr.trans_date = DATE_ADD(mom_prev.trans_date, INTERVAL 1 MONTH)
  LEFT JOIN sales_agg AS yoy_prev
    ON curr.cus_name = yoy_prev.cus_name
   AND curr.trans_date = DATE_ADD(yoy_prev.trans_date, INTERVAL 1 YEAR)
)



select 
sale.trans_date,
sale.cus_name,
sale.sub_name,
sale.cus_2nd_cat_name,
sale.cum_rmb_amt_month as Month_CNY_MTD,
bug.month_bgt_amt as Month_Target,
sale.cum_rmb_amt_month/bug.month_bgt_amt as Month_Target_Reach,
sale.MOM,
sale.YOY
from sales_mom_yoy as sale
left join dw.ads_customer_month_budget as bug
on bug.cus_id=sale.cus_id and DATE_FORMAT(bug.bgt_date, '%Y-%m')=sale.trans_month
where sale.trans_date = '${trans_date}'





