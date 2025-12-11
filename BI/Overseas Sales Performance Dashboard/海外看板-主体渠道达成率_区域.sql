--------------------------------------------------------
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
    c.cus_contient_country AS Subsidiary,
    s.incl_tax_rmb_amt,
    s.cus_2nd_cat_name
  FROM dw.ads_customer_overseas_sales_daily AS s 
  LEFT JOIN dw.dim_customer_subsidiary AS c
    ON c.cus_code = s.cus_code
  WHERE 
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
    Subsidiary,
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
  GROUP BY Region, Subsidiary
  ,cus_2nd_cat_name
),
bug_amt as(
  select
  bgt_date,
  sum(bug.month_bgt_amt) as month_bgt_amt,
  c.cus_contient_name AS Region,
  c.cus_contient_country AS Subsidiary,
  c.cus_2nd_cat_name
  from dw.ads_customer_month_budget as bug
  LEFT JOIN dw.dim_customer_subsidiary as c
  on bug.cus_code = c.cus_code
  where exists (
    select 1
    from dw.bi_overseas_region_rowauth r
    where r.user_id = '${fine_username}'
      and (
             (r.sub_region_flag = 'region' and c.cus_contient_name = r.region_name or region_name='ALL')
          or (r.sub_region_flag = 'sub'    and c.cus_contient_country = r.sub_name)
      )
)
  group by 
  bgt_date,
  c.cus_contient_name,
  c.cus_contient_country,
c.cus_2nd_cat_name)

SELECT
  DAY('${trans_date}') / DAY(LAST_DAY('${trans_date}')) AS Month_Progress,
  sale.Region,
  sale.Subsidiary,
  sale.Month_CNY_MTD,
  sale.cus_2nd_cat_name,
  bug.month_bgt_amt as Month_Target,
  ifnull(sale.Month_CNY_MTD/bug.month_bgt_amt,0) as Month_Target_Reach,
  sale.amt_last_month,
  sale.amt_last_year,
  -- 环比 MoM
  CASE WHEN amt_last_month != 0 THEN ROUND((Month_CNY_MTD - amt_last_month) / amt_last_month, 4) ELSE NULL END AS MOM,
  -- 同比 YoY
  CASE WHEN amt_last_year != 0 THEN ROUND((Month_CNY_MTD - amt_last_year) / amt_last_year, 4) ELSE NULL END AS YOY
FROM agg_sales as sale
left join bug_amt as bug
on sale.Subsidiary = bug.Subsidiary 
and sale.Region = bug.Region
and sale.cus_2nd_cat_name=bug.cus_2nd_cat_name
and DATE_FORMAT(bug.bgt_date, '%Y-%m')=DATE_FORMAT('${trans_date}', '%Y-%m') 
where 1=1 ${if(Subsidiary == '',"","and   Subsidiary in ('" + Subsidiary + "')")} 
and 1=1 ${if(Region == '',"","and   Region in ('" + Region + "')")} 
and 1=1 ${if(cus_name == '',"","and   cus_name in ('" + cus_name + "')")} 
and 1=1 ${if(cus_2nd_cat_name == '',"","and   sale.cus_2nd_cat_name in ('" + cus_2nd_cat_name + "')")} 



----------------------------------------
-- 10.10 修改不实际产生业绩的客户显示问题
WITH date_ref AS (
  SELECT
    DATE('${trans_date}') AS cur_day,
    DATE_FORMAT('${trans_date}', '%Y-%m-01') AS cur_month_start,
    DATE_FORMAT(DATE_ADD('${trans_date}', INTERVAL -1 MONTH), '%Y-%m-01') AS last_month_start,
    DATE_ADD('${trans_date}', INTERVAL -1 MONTH) AS last_month_end,
    DATE_FORMAT(DATE_ADD('${trans_date}', INTERVAL -12 MONTH), '%Y-%m-01') AS last_year_month_start,
    DATE_ADD('${trans_date}', INTERVAL -12 MONTH) AS last_year_month_end
),
base_sales as (
select 
  Region,
  Subsidiary,
  cus_2nd_cat_name,
  sum(Month_CNY_MTD) as Month_CNY_MTD,
  sum(amt_last_month) as amt_last_month,
  sum(amt_last_year) as amt_last_year,
  sum(month_bgt_amt) as month_bgt_amt
from 
(SELECT
  -- s.trans_date,
  c.cus_contient_name AS Region,
  c.cus_contient_country AS Subsidiary,
  s.cus_2nd_cat_name,
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
      END) AS amt_last_year,
  0 as month_bgt_amt
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
  (
    (c.sub_id = '1' AND c.cus_2nd_cat_name = 'E-com') OR
    (c.sub_id NOT IN ('28','21','15','22','24', '1','42') AND c.cus_contient_country NOT LIKE '%No performance%')
  )
  AND c.cus_contient_name IS NOT NULL
  AND s.trans_date BETWEEN DATE_FORMAT(DATE_ADD('${trans_date}', INTERVAL -12 MONTH), '%Y-%m-01') AND '${trans_date}' -- 足够包含3个区间
 and !(s.cus_id='13679' and s.sale_country_name in ('Taiwan (Province of China)','Hong Kong','China','Macao'))
 group by 
    c.cus_contient_name,
    c.cus_contient_country,
    s.cus_2nd_cat_name

union all

select
  -- bgt_date,
  c.cus_contient_name AS Region,
  c.cus_contient_country AS Subsidiary,
  c.cus_2nd_cat_name,
  0 as Month_CNY_MTD,
  0 as amt_last_month,
  0 as amt_last_year,
  sum(bug.month_bgt_amt) as month_bgt_amt
  from dw.ads_customer_month_budget as bug
  LEFT JOIN dw.dim_customer_subsidiary as c
  on bug.cus_code = c.cus_code
  where 
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
  (
    (c.sub_id = '1' AND c.cus_2nd_cat_name = 'E-com') OR
    (c.sub_id NOT IN ('28','21','15','22','24', '1','42') AND c.cus_contient_country NOT LIKE '%No performance%')
  )
AND c.cus_contient_name IS NOT NULL
and DATE_FORMAT(bug.bgt_date, '%Y-%m')=DATE_FORMAT('${trans_date}', '%Y-%m') 
group by 
  -- bgt_date,
  c.cus_contient_name,
  c.cus_contient_country,
  c.cus_2nd_cat_name)
group by 
  Region,
  Subsidiary,
  cus_2nd_cat_name
)



SELECT
  DAY('${trans_date}') / DAY(LAST_DAY('${trans_date}')) AS Month_Progress,
  Region,
  Subsidiary,
  cus_2nd_cat_name,
  Month_CNY_MTD,
  month_bgt_amt as Month_Target,
  ifnull(Month_CNY_MTD/month_bgt_amt,0) as Month_Target_Reach,
  amt_last_month,
  amt_last_year,
  -- 环比 MoM
  CASE WHEN amt_last_month != 0 THEN ROUND((Month_CNY_MTD - amt_last_month) / amt_last_month, 4) ELSE NULL END AS MOM,
  -- 同比 YoY
  CASE WHEN amt_last_year != 0 THEN ROUND((Month_CNY_MTD - amt_last_year) / amt_last_year, 4) ELSE NULL END AS YOY
FROM base_sales
where 1=1 ${if(Subsidiary == '',"","and   Subsidiary in ('" + Subsidiary + "')")} 
and 1=1 ${if(Region == '',"","and   Region in ('" + Region + "')")} 
and 1=1 ${if(cus_2nd_cat_name == '',"","and   cus_2nd_cat_name in ('" + cus_2nd_cat_name + "')")} 



select * from po.purchase_order_info