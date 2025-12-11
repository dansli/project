WITH base_sales AS (
  SELECT
    c.cus_name,
    s.cus_id,
    s.cus_code,
    s.trans_date,
  	c.sub_name,
  	c.cus_2nd_cat_name,
  	c.cus_contient_name as Region,
	c.cus_contient_country as Subsidiary,
    DATE_FORMAT(s.trans_date, '%Y-%m') AS trans_month,
    DATE_FORMAT(s.trans_date, '%Y') AS trans_year,
    s.incl_tax_rmb_amt,
    s.incl_tax_foreign_amt
  FROM dw.ads_customer_overseas_sales_daily AS s 
  LEFT JOIN dw.dim_customer_subsidiary AS c
    ON c.cus_code = s.cus_code
where   ((c.sub_id = '1' AND c.cus_2nd_cat_name = 'E-com')
OR (c.sub_id NOT IN ('28','21','15','22','24', '1')
and c.cus_contient_country NOT LIKE '%No performance%'))
and c.cus_contient_name is not null -- cus_contient_name为空不计入业绩
),
sales_agg as(
SELECT
  trans_date,
  cus_name,
  cus_id,
  cus_code,
  sub_name,
  cus_2nd_cat_name,
  Region,
  Subsidiary,
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
    ROUND((curr.cum_rmb_amt_month - mom_prev.cum_rmb_amt_month) / ifnull(mom_prev.cum_rmb_amt_month, 0), 3) AS MOM,
    ROUND((curr.cum_rmb_amt_year - yoy_prev.cum_rmb_amt_year) / ifnull(yoy_prev.cum_rmb_amt_year, 0), 3) AS YOY
  FROM sales_agg AS curr
  LEFT JOIN sales_agg AS mom_prev
    ON curr.cus_code = mom_prev.cus_code
   AND curr.trans_date = DATE_ADD(mom_prev.trans_date, INTERVAL 1 MONTH)
  LEFT JOIN sales_agg AS yoy_prev
    ON curr.cus_code = yoy_prev.cus_code
   AND curr.trans_date = DATE_ADD(yoy_prev.trans_date, INTERVAL 1 YEAR)
)



select 
sale.trans_date,
DAY(sale.trans_date) / DAY(LAST_DAY(sale.trans_date)) AS Month_Progress,
sale.cus_name,
sale.sub_name,
sale.cus_2nd_cat_name,
sale.Region,
sale.Subsidiary,
sale.cum_rmb_amt_month as Month_CNY_MTD,
bug.month_bgt_amt as Month_Target,
ifnull(sale.cum_rmb_amt_month/bug.month_bgt_amt,0) as Month_Target_Reach,
sale.last_year_cum_amt as Last_Year_Sales,
sale.cum_rmb_amt_year as Current_Year_Sales,
sale.MOM,
sale.YOY
from sales_mom_yoy as sale
left join dw.ads_customer_month_budget as bug
on bug.cus_code=sale.cus_code and DATE_FORMAT(bug.bgt_date, '%Y-%m')=sale.trans_month
where sale.trans_date = '${trans_date}'
and 1=1 ${if(Subsidiary == '',"","and   Subsidiary in ('" + Subsidiary + "')")} 
and 1=1 ${if(Region == '',"","and   Region in ('" + Region + "')")} 
and 1=1 ${if(cus_name == '',"","and   cus_name in ('" + cus_name + "')")} 
and 1=1 ${if(cus_2nd_cat_name == '',"","and   cus_2nd_cat_name in ('" + cus_2nd_cat_name + "')")} 