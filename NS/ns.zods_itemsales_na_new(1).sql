delete from ns.zods_itemsales_na_new 
where 日期 >= DATE_FORMAT(DATE_SUB(NOW(),INTERVAL 3 month),'yyyyMMdd');

insert into ns.zods_itemsales_na_new 
with item_na as (
  select 
    i.itemid as SKU_20码,
    ii.主系列 
  from ns.dim_oversea_item as i
  inner join DW.ZMD_DMV002_01 as ii 
  on i.itemid = ii.商品代码
)
select 
  od.tran_day as 日期,
  od.channel as 渠道,
  od.cum_country as 客户国家,
  od.terminal as 终端,
  nvl(i2.主系列, i1.主系列) as 主系列,
  sum(od.PRODUCT_COUNT) as 数量, 
  sum(od.FOREIGN_AMOUNT) as 原币金额, 
  sum(od.INCL_TAX_FOREIGN_AMOUNT) as 原币含税金额 
from ns.dws_oversea_order_v2_detail_na as od 
left join ns.zods_itempacking_na as i 
on od.item_code = i.itemid 
left join item_na as i1 
on od.item_code = i1.SKU_20码
left join item_na as i2 
on i.itemid  = i2.SKU_20码
where ((od.channel in ('Store', 'Comic-Con') and od.RECORDTYPE in ('invoice', 'creditmemo')) 
  or (od.channel not in ('Store', 'Comic-Con') and od.RECORDTYPE in ('salesorder','returnauthorization'))) 
  and od.SUBSIDIARY in (15, 22) 
  and od.tran_day >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 3 month), 'yyyyMMdd')
  and od.tran_day <= DATE_FORMAT(curdate() ,'yyyyMMdd')
  and not(od.status = 'H' and od.recordtype in ('salesorder' ,'returnauthorization') and od.channel = 'Reseller')
group by 
  od.tran_day, 
  od.channel, 
  od.cum_country, 
  od.terminal, 
  nvl(i2.主系列, i1.主系列);


-- 【NS】全渠道365天销售
with item_na as (
  select * 
  from (
    select 
      i.itemid as SKU_20码,
      i.custitem_pm_item_main_barcode as SKU_69码,
      i.displayname as SKU名称,
      i.CUSTITEM_PM_ENGLISH_NAME as SKU英文名,
      i.CUSTITEM_PM_UP_DATE as 上市日期,
      ii.系列编码,
      ii.系列名称,
      ii.主系列,
      iii.主系列名称,
      ii.IP,
      ii.商业一级代码,
      ii.商业一级名称,
      ii.商业二级代码,
      ii.商业二级名称,
      ii.商业三级代码,
      ii.商业三级名称,
      -- 优先级排序：先按是否为盲盒排序，再按上市日期升序排序
      row_number() over(partition by ii.主系列 
        order by  
          if(ii.包装方式 = '盲盒', 0, 1), -- 盲盒优先
          i.CUSTITEM_PM_UP_DATE -- 按上市日期升序
      ) as rn
    from ns.dim_oversea_item as i 
    inner join DW.ZMD_DMV002_01 as ii 
    on i.itemid = ii.商品代码
    inner join (
      select distinct 
        主系列,
        系列名称 as 主系列名称 
      from dw.ZMD_DMV002_01 
      where 主系列 = 系列编码
    ) as iii
    on ii.主系列 = iii.主系列
  ) as t 
  where rn = 1
) 
select 
  a.日期,
  a.渠道,
  a.客户国家,
  a.终端,
  i.SKU_20码,
  i.SKU_69码,
  i.SKU名称,
  i.SKU英文名,
  i.上市日期,
  (DATEDIFF(date_format(a.日期,'yyyyMMdd'),date_format(i.上市日期,'yyyyMMdd'))) 售卖天数,
  a.数量,
  a.原币金额,
  a.原币含税金额,
  i.IP,
  i.商业一级代码,
  i.商业一级名称,
  i.商业二级代码,
  i.商业二级名称,
  i.商业三级代码,
  i.商业三级名称,
  i.系列编码,
  i.系列名称,
  i.主系列,
  i.主系列名称
from ns.zods_itemsales_na_new as a  
inner join item_na as i 
on a.主系列 = i.主系列 
where a.日期 >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 2 year), 'yyyyMMdd')

