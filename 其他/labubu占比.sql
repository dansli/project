with
  overall_sales as (
    select
      substr(i.TRAN_DATE,1,7) as month,
      sum(i.PRODUCT_COUNT) as qty,
      sum(i.INCL_TAX_RMB_AMOUNT) as RMB_AMOUNT,
      ii.SUBSIDIARY_REGIONAL_SEGMENTATION
    from
      (
        SELECT
          TRAN_DATE,
          CUSTOMER_CODE,
          PRODUCT_COUNT,
          RMB_AMOUNT,
          INCL_TAX_RMB_AMOUNT,
          ITEM_CODE
        from
          ns.dws_oversea_order_v2_detail
        where
          is_target = 1
      ) as i
      left join (
        select
          ENTITYID,
          SUBSIDIARY_REGIONAL_SEGMENTATION
        from
          ns.ZODS_customer
      ) as ii on i.CUSTOMER_CODE = ii.ENTITYID
      left join (
        select
          ITEMID,
          oversea_ip_name as IP_NAME
        from
          ns.dim_oversea_item
      ) as iii on i.ITEM_CODE = iii.ITEMID
    where
      i.TRAN_DATE between "${start}" and "${end}"
    group by
      substr(i.TRAN_DATE,1,7),
      ii.SUBSIDIARY_REGIONAL_SEGMENTATION
  ),
  labubu_sales as (
 select
      substr(i.TRAN_DATE,1,7) as month,
      sum(i.PRODUCT_COUNT) as qty,
      sum(i.INCL_TAX_RMB_AMOUNT) as RMB_AMOUNT,
      ii.SUBSIDIARY_REGIONAL_SEGMENTATION
    from
      (
        SELECT
          TRAN_DATE,
          CUSTOMER_CODE,
          PRODUCT_COUNT,
          RMB_AMOUNT,
          INCL_TAX_RMB_AMOUNT,
          ITEM_CODE
        from
          ns.dws_oversea_order_v2_detail
        where
          is_target = 1
      ) as i
      left join (
        select
          ENTITYID,
          SUBSIDIARY_REGIONAL_SEGMENTATION
        from
          ns.ZODS_customer
      ) as ii on i.CUSTOMER_CODE = ii.ENTITYID
      left join (
        select
          ITEMID,
          oversea_ip_name as IP_NAME
        from
          ns.dim_oversea_item
      ) as iii on i.ITEM_CODE = iii.ITEMID
    where
      i.TRAN_DATE between "${start}" and "${end}" and  iii.IP_NAME = 'LABUBU'
    group by
      substr(i.TRAN_DATE,1,7),
      ii.SUBSIDIARY_REGIONAL_SEGMENTATION)

  select 
  i.RMB_AMOUNT/ii.RMB_AMOUNT as labubu_ratio,
i.SUBSIDIARY_REGIONAL_SEGMENTATION,
   i.month
  from labubu_sales as i
  left join overall_sales as ii on i.month = ii.month and i.SUBSIDIARY_REGIONAL_SEGMENTATION = ii.SUBSIDIARY_REGIONAL_SEGMENTATION
  where 1=1
  <parameter>and i.SUBSIDIARY_REGIONAL_SEGMENTATION in ("${SUBSIDIARY_REGIONAL_SEGMENTATION}") </parameter>
    group by i.SUBSIDIARY_REGIONAL_SEGMENTATION,
i.month