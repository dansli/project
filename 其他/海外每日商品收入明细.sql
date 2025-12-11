with dws_ns_income_daily_summary AS (
  SELECT
    transaction_date,
    transaction_month,
    transaction_year,
    subsidiary_id,
    entity_id,
    currency_id,
    sale_country_id,
    item_id,
    transaction_recordtype,
    SUM(product_qty) AS product_qty,
    SUM(transaction_amount) AS transaction_amount,
    SUM(transaction_amount_cny) AS transaction_amount_cny,
    SUM(transaction_amount_excl_tax) AS transaction_amount_excl_tax,
    SUM(transaction_amount_incl_tax) AS transaction_amount_incl_tax,
    SUM(transaction_amount_incl_tax_cny) AS transaction_amount_incl_tax_cny,
    SUM(transaction_amount_excl_tax_cny) AS transaction_amount_excl_tax_cny,
    SUM(tax_amount) AS tax_amount,
    SUM(tax_amount_cny) AS tax_amount_cny,
    SUM(tax_amount_cny_fin) AS tax_amount_cny_fin,
    SUM(tax_amount_subs_currency) AS tax_amount_subs_currency,
    max(direct_quotation_premon) AS direct_quotation_premon,
    SUM(transaction_amount_subs_currency) AS transaction_amount_subs_currency, -- 交易金额（记账货币）
    SUM(transaction_amount_excl_tax_subs_currency) AS transaction_amount_excl_tax_subs_currency,
    SUM(transaction_amount_incl_tax_subs_currency) AS transaction_amount_incl_tax_subs_currency, -- 含税交易金额（记账货币）
    SUM(transaction_amount_cny_fin) AS transaction_amount_cny_fin,
    SUM(transaction_amount_excl_tax_cny_fin) AS transaction_amount_excl_tax_cny_fin,
    SUM(transaction_amount_incl_tax_cny_fin) AS transaction_amount_incl_tax_cny_fin
  FROM dw.dwd_ns_transaction_sale_tax_detail
  where transaction_recordtype in ('invoice', 'creditmemo')
  and item_id not in (165097,178787,304454)
  GROUP BY
    transaction_date,
    transaction_month,
    transaction_year,
    subsidiary_id,
    entity_id,
    currency_id,
    sale_country_id,
    item_id,
    transaction_recordtype
)



SELECT
  sale.transaction_date,
  sale.transaction_month,
  sale.transaction_year,
  sale.subsidiary_id,
  sub.subsidiary_name,
  sub.subsidiary_currency_name, -- 主体记账货币
  sub.SUBSIDIARY_CURRENCY_ID, -- 主体记账货币ID
  ent.entity_continent AS subsidiary_continent,
  ent.entity_id,
  ent.entity_code,
  ent.entity_name,
  ent.entity_city,
  ent.entity_country,
  ent.entity_continent,
  ent.entity_1st_cat_name,
  ent.entity_2nd_cat_name,
  ent.entity_3rd_cat_name,
  ent.ENTITY_CODE as 客商代码,
  ent.entity_2nd_cat_name_cn,
  sale.currency_id,
  cur.name AS currency_name, -- 交易货币
  ctry.name AS sale_country,
  item.*,
  sale.product_qty,
  sale.transaction_amount,
  round(sale.transaction_amount_cny,2) as transaction_amount_cny,
  sale.transaction_amount_excl_tax,
  sale.transaction_amount_incl_tax,
  round(sale.transaction_amount_incl_tax_cny,2) as transaction_amount_incl_tax_cny,
  round(sale.transaction_amount_excl_tax_cny,2) as transaction_amount_excl_tax_cny,
  sale.tax_amount,
  round(sale.tax_amount_cny,2) as tax_amount_cny,
  round(sale.tax_amount_cny_fin,2) as tax_amount_cny_fin,
  round(sale.tax_amount_subs_currency,2) as tax_amount_subs_currency,
  sale.direct_quotation_premon,
  round(sale.transaction_amount_subs_currency,2) as transaction_amount_subs_currency,
  round(sale.transaction_amount_excl_tax_subs_currency,2) as transaction_amount_excl_tax_subs_currency,
  round(sale.transaction_amount_incl_tax_subs_currency,2) transaction_amount_incl_tax_subs_currency,
  round(sale.transaction_amount_cny_fin,2) as transaction_amount_cny_fin,
  round(sale.transaction_amount_excl_tax_cny_fin,2) as transaction_amount_excl_tax_cny_fin,
  round(sale.transaction_amount_incl_tax_cny_fin,2) as transaction_amount_incl_tax_cny_fin,
  sale.transaction_recordtype,
  g.property as 商品属性,
  g.ip as IP_HD,
  s.code as 系列代码_HD,
  s.name as 系列名称_HD,
  g.def_datasort as 商业三级分类_HD,
  g.expcntinprc as  商品采购单价_HD,
  g.RtlPrc as 泡泡中国吊牌单价_HD,
  curr.exchangerate as 结算货币汇率,
  m.region_1st as 售达区域,
  -- nvl(custrecord_link_item_price, custrecord_item_rrp_suggest_price) as 吊牌金额,
  ms.name as 主系列名称,
  st.fvalue as 系列主题名称,
  s.seriestheme as 系列主题编码,
  case when ent.ENTITY_CODE ='C23472' then '关联方'
  when ent.ENTITY_CODE ='C30299' or (ent.entity_2nd_cat_name ='Corp' and ent.ENTITY_CODE <>'C23472') then '合并范围内'
  else '第三方' end as 关联性质,
  case when item.hd_item_id in 
  ('AMZ GIFT', 'AMZ shipping', 'E00008', 'E00009', 'E00013', 'E00016', 'E00020', 'E00021OLD', 'E00032', 'MBSH01REV', 'S00001', 'SH0001', 'SHOP00028', 'SHOP00032', 'TW-Shipping') then '其他业务收入' 
  else '主营业务收入' end as 收入类型
FROM dws_ns_income_daily_summary AS sale
LEFT JOIN dw.dim_ns_subsidiary_info AS sub
  ON sale.subsidiary_id = sub.subsidiary_id
LEFT JOIN dw.dim_ns_entity_info AS ent
  ON sale.entity_id = ent.entity_id
LEFT JOIN ns.currency AS cur
  ON sale.currency_id = cur.id
LEFT JOIN ns.CUSTOMRECORD_HC_TRADING_COUNTRY AS ctry
  ON sale.sale_country_id = ctry.custrecord_hc_tc_name_en
INNER JOIN dw.dim_ns_item_info AS item
  ON sale.item_id = item.item_id 
LEFT JOIN dw.dwd_ns_budget_by_month AS bgt
  ON sale.entity_id = bgt.budget_entity_id
  AND sale.subsidiary_id = bgt.budget_subsidiary_id
  AND sale.transaction_month = bgt.budget_month
left join sds.goods as g on item.HD_ITEM_ID = g.code
left join sds.series as s 
on g.series = s.code
left join 
(select bcurry,id,exchangerate1,exchangerate,zdate from ns.zods_currency) curr 
on  sub.SUBSIDIARY_CURRENCY_ID=curr.bcurry and date_format(sale.transaction_date,'yyyyMMdd')=curr.zdate
left join dw.dim_manual_region_country_mapping as m
on m.abbreviation = ctry.custrecord_hc_tc_country_code
-- left join ns.CUSTOMRECORD_ITEM_RRP as rrp
-- on rrp.custrecord_link_item = item.item_id 
-- and rrp.custrecord_item_rrp_currency=sub.SUBSIDIARY_CURRENCY_ID
left join (
  select 
    mainseries,
    name 
  from sds.series 
  where mainseries = code
) as ms -- 主系列
on s.mainseries = ms.mainseries
left join sds.ppro_options as st -- 系列主题
on st.type = 'SERIESTHEME' 
and s.seriestheme = st.fkey