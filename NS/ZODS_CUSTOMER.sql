create view dw.dim_currency as 
select distinct name, id from ns.currency
 
 
 
 CREATE VIEW ns.ZODS_CUSTOMER AS WITH
  t1 AS (
   SELECT
     cum.id as internal_id
   , cum.altname as customer_altname
   , cum.custentity_pm_store_seat as customer_city
   , cum.custentity_inter_regional_segmentation as regional_segmentation
   , cum.entityid as customer_code
   , cum.category as category_code
   , cum.currency as currency_code --交易货币?
  -- , cum.custentity_pm_customer_business_class 
   , cum.currency as SUBSIDIARY_COUNTRY
   , cum.custentity_pm_customer_2nd_cat as customer_2nd_cat_code --category2
   , cum.custentity_3nd_cat_classs as customer_3rd_cat_code --custentity_3nd_cat_classs
   , cum.custentity_inter_regional_segmentation as customer_continent
   , cty.name as customer_1st_cat_name --2b/2c
   , cty2.name as customer_2nd_cat_name --KA/STORE
   , cty3.name as customer_3rd_cat_name --电商分类
   , country.custrecord_hc_tc_country_code as country_code
   , country.names as country_name
   , sub.id as SUBSIDIARY_code
   , sub.name as SUBSIDIARY_NAME
   , cur.name as currency
   , custentity_pm_cus_norlocation as warehouse_code --映射门店下的发货仓
   , loc.fullname as warehouse_location -- 发货仓库名称
  -- ,'csr'.currency_name as primarycurrency
   FROM
     ((((((ns.customer cum
   LEFT JOIN ns.customerCategory cty --客户商业模式2b-1/2c-2 
   ON (cum.category = cty.ID))
   LEFT JOIN ns.CUSTOMLIST_PM_CUSTOMER_2ND_CAT cty2 ON (cum.custentity_pm_customer_2nd_cat = cty2.ID))
   LEFT JOIN ns.CUSTOMLIST_PM_CUSTOMER_3ND_CAT cty3 ON (cum.custentity_3nd_cat_classs = cty3.id))
   -- LEFT JOIN (
   --   SELECT i.*,ii.name as currency_name
   --   FROM
   --     ns.CustomerSubsidiaryRelationship as i
   --   LEFT JOIN (select distinct name, id from ns.currency) as ii on i.primarycurrency = ii.id
   --   WHERE (i.isprimarysub = 'T') 
   --)  csr ON (cum.id = csr.entity))
   LEFT JOIN ns.Subsidiary sub ON (csr.subsidiary = sub.id))
   LEFT JOIN ns.CUSTOMRECORD_HC_TRADING_COUNTRY country ON (country.custrecord_hc_tc_country_code = sub.country))
   LEFT JOIN (select distinct name, id from ns.currency) cur ON (cum.currency = cur.id))
   left join ns.location as loc on cum.custentity_pm_cus_norlocation=loc.id
) 
SELECT
  t1.internal_id
   ,t1.customer_altname
   ,t1.customer_city
   , t1.regional_segmentation
   , t1.customer_code
   , t1.category_code
   , t1.currency_code --交易货币?
   , t1.SUBSIDIARY_COUNTRY
   , t1.customer_2nd_cat_code --category2
   , t1.customer_3rd_cat_code --custentity_3nd_cat_classs
   , t1.customer_continent
   ,  t1.customer_1st_cat_name --2b/2c
   , t1.customer_2nd_cat_name --KA/STORE
   ,  t1.customer_3rd_cat_name --电商分类
   , t1.country_code
   , t1.country_name
   , t1.SUBSIDIARY_code
   , t1.SUBSIDIARY_NAME
   , t1.currency
   ,  t1.warehouse_code --映射门店下的发货仓
   , t1.warehouse_location
, (CASE WHEN (CUSTOMER_3ND_CAT_NAME = '总部跨境电商') THEN '总部跨境电商' 
        WHEN ((((customer_2nd_cat_name IN ('KA', 'Retail')) AND (SUBSIDIARY_code IN (1, 10))) AND (COUNTRY_CODE <> 'HK')) AND (CUSTOMER_CONTINENT = '东亚区域')) THEN '东亚KA' 
        WHEN ((((customer_2nd_cat_name IN ('KA', 'Retail')) AND (SUBSIDIARY_code IN (1, 10))) AND (NOT (COUNTRY_CODE IN ('HK', 'FR')))) AND (CUSTOMER_CONTINENT = '欧洲区域')) THEN '欧洲KA' 
        WHEN ((((customer_2nd_cat_name IN ('KA', 'Retail')) AND (SUBSIDIARY_code = 29)) AND (COUNTRY_CODE <> 'FR')) AND (CUSTOMER_CONTINENT = '欧洲区域')) THEN '欧洲KA' 
        WHEN ((((customer_2nd_cat_name IN ('KA', 'Retail')) AND (SUBSIDIARY_code IN (1, 10))) AND (COUNTRY_CODE <> 'HK')) AND (CUSTOMER_CONTINENT = '澳新区域')) THEN '澳新KA' 
        WHEN ((((customer_2nd_cat_name IN ('KA', 'Retail')) AND (SUBSIDIARY_code IN (1, 10))) AND (COUNTRY_CODE <> 'HK')) AND (CUSTOMER_CONTINENT = '北美区域')) THEN '北美KA' 
        WHEN ((((customer_2nd_cat_name IN ('KA', 'Retail')) AND (SUBSIDIARY_code IN (1, 10))) AND (COUNTRY_CODE <> 'HK')) AND (CUSTOMER_CONTINENT = '东南亚区域')) THEN '东南亚KA' 
        WHEN (country_name = '香港,中国') THEN '中国香港' WHEN (country_name = '台湾,中国') THEN '中国台湾' 
        WHEN (country_name = '澳门') THEN '中国澳门' ELSE country_name END) SUBSIDIARY_REGIONAL_SEGMENTATION
FROM
  t1


create view
  dw.dim_currency as
select distinct
  name,
  id
from
  ns.currency

CREATE VIEW
  ns.ZODS_CUSTOMER AS
WITH
  t1 AS (
    SELECT
      cum.id as internal_id,
      cum.altname as customer_altname,
      cum.custentity_pm_store_seat as customer_city,
      cum.custentity_inter_regional_segmentation as regional_segmentation,
      cum.entityid as customer_code,
      cum.category as category_code,
      cum.currency as currency_code, --交易货币?
      -- cum.custentity_pm_customer_business_class, 
      cum.currency as SUBSIDIARY_COUNTRY,
      cum.custentity_pm_customer_2nd_cat as customer_2nd_cat_code, -- category2
      cum.custentity_3nd_cat_classs as customer_3rd_cat_code, -- custentity_3nd_cat_classs
      cum.custentity_inter_regional_segmentation as customer_continent,
      cty.name as customer_1st_cat_name, -- 2b/2c
      cty2.name as customer_2nd_cat_name, -- KA/STORE
      cty3.name as customer_3rd_cat_name, -- 电商分类
      country.custrecord_hc_tc_country_code as country_code,
      country.names as country_name,
      sub.id as SUBSIDIARY_code,
      sub.name as SUBSIDIARY_NAME,
      cur.name as currency,
      custentity_pm_cus_norlocation as warehouse_code, -- 映射门店下的发货仓
      loc.fullname as warehouse_location -- 发货仓库名称
      -- ,'csr'.currency_name as primarycurrency
    FROM
      (
        (
          (
            (
              (
                (
                  ns.customer cum
                  LEFT JOIN ns.customerCategory cty --客户商业模式2b-1/2c-2 
                  ON (cum.category = cty.ID)
                )
                LEFT JOIN ns.CUSTOMLIST_PM_CUSTOMER_2ND_CAT cty2 ON (cum.custentity_pm_customer_2nd_cat = cty2.ID)
              )
              LEFT JOIN ns.CUSTOMLIST_PM_CUSTOMER_3ND_CAT cty3 ON (cum.custentity_3nd_cat_classs = cty3.id)
            )
            -- LEFT JOIN (
            --   SELECT i.*,ii.name as currency_name
            --   FROM
            --     ns.CustomerSubsidiaryRelationship as i
            --   LEFT JOIN (select distinct name, id from ns.currency) as ii on i.primarycurrency = ii.id
            --   WHERE (i.isprimarysub = 'T') 
            --)  csr ON (cum.id = csr.entity))
            LEFT JOIN ns.Subsidiary sub ON (csr.subsidiary = sub.id)
          )
          LEFT JOIN ns.CUSTOMRECORD_HC_TRADING_COUNTRY country ON (
            country.custrecord_hc_tc_country_code = sub.country
          )
        )
        LEFT JOIN (
          select distinct
            name,
            id
          from
            ns.currency
        ) cur ON (cum.currency = cur.id)
      )
      left join ns.location as loc on cum.custentity_pm_cus_norlocation = loc.id
  )
SELECT
  t1.internal_id,
  t1.customer_altname,
  t1.customer_city,
  t1.regional_segmentation,
  t1.customer_code,
  t1.category_code,
  t1.currency_code,
  t1.SUBSIDIARY_COUNTRY,
  t1.customer_2nd_cat_code,
  t1.customer_3rd_cat_code,
  t1.customer_continent,
  t1.customer_1st_cat_name,
  t1.customer_2nd_cat_name,
  t1.customer_3rd_cat_name,
  t1.country_code,
  t1.country_name,
  t1.SUBSIDIARY_code,
  t1.SUBSIDIARY_NAME,
  t1.currency,
  t1.warehouse_code,
  t1.warehouse_location,
  (
    CASE
      WHEN (CUSTOMER_3ND_CAT_NAME = '总部跨境电商') THEN '总部跨境电商'
      WHEN (
        (
          (
            (customer_2nd_cat_name IN ('KA', 'Retail'))
            AND (SUBSIDIARY_code IN (1, 10))
          )
          AND (COUNTRY_CODE <> 'HK')
        )
        AND (CUSTOMER_CONTINENT = '东亚区域')
      ) THEN '东亚KA'
      WHEN (
        (
          (
            (customer_2nd_cat_name IN ('KA', 'Retail'))
            AND (SUBSIDIARY_code IN (1, 10))
          )
          AND (NOT(COUNTRY_CODE IN ('HK', 'FR')))
        )
        AND (CUSTOMER_CONTINENT = '欧洲区域')
      ) THEN '欧洲KA'
      WHEN (
        (
          (
            (customer_2nd_cat_name IN ('KA', 'Retail'))
            AND (SUBSIDIARY_code = 29)
          )
          AND (COUNTRY_CODE <> 'FR')
        )
        AND (CUSTOMER_CONTINENT = '欧洲区域')
      ) THEN '欧洲KA'
      WHEN (
        (
          (
            (customer_2nd_cat_name IN ('KA', 'Retail'))
            AND (SUBSIDIARY_code IN (1, 10))
          )
          AND (COUNTRY_CODE <> 'HK')
        )
        AND (CUSTOMER_CONTINENT = '澳新区域')
      ) THEN '澳新KA'
      WHEN (
        (
          (
            (customer_2nd_cat_name IN ('KA', 'Retail'))
            AND (SUBSIDIARY_code IN (1, 10))
          )
          AND (COUNTRY_CODE <> 'HK')
        )
        AND (CUSTOMER_CONTINENT = '北美区域')
      ) THEN '北美KA'
      WHEN (
        (
          (
            (customer_2nd_cat_name IN ('KA', 'Retail'))
            AND (SUBSIDIARY_code IN (1, 10))
          )
          AND (COUNTRY_CODE <> 'HK')
        )
        AND (CUSTOMER_CONTINENT = '东南亚区域')
      ) THEN '东南亚KA'
      WHEN (country_name = '香港,中国') THEN '中国香港'
      WHEN (country_name = '台湾,中国') THEN '中国台湾'
      WHEN (country_name = '澳门') THEN '中国澳门'
      ELSE country_name
    END
  ) SUBSIDIARY_REGIONAL_SEGMENTATION
FROM
  t1