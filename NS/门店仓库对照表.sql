select
  *
from
  (
    select
      cus.id as cus_id,
      cus.entityid as cus_code,
      cus.altname AS cus_name,
      loc.name as warehouse_name, -- 仓库名称
      list.name as warehouse_cat_name, -- 仓库分类
      loc.id as warhouse_id, -- 仓库id
      loc.custrecord_hp_father_location as father_warehouse_id, -- 父级仓库id
      loc.custrecord_pm_pos_location as warehouse_code -- 仓库代码
    from
      ns.Customer as cus
      left join ns.location as loc on cus.custentity_pm_cus_norlocation = loc.id
      left join ns.CUSTOMLIST_PM_LOCATION_TYPE_LIST as list on loc.custrecord_pm_location_type = list.id
    where
      loc.parent is null
      and list.name = 'store'
  ) as t
  left join (
    select
      loc.name as warehouse_def_name, -- 陈列仓名称
      loc.id as warehouse_def_id, -- 陈列仓id
      loc.parent as warehouse_def_parent_id,
      loc.custrecord_pm_pos_location as warehouse_def_code -- 陈列仓代码
    from
      ns.location as loc
      left join ns.CUSTOMLIST_PM_LOCATION_TYPE_LIST as list on loc.custrecord_pm_location_type = list.id
    where
      loc.parent is not null
      and list.name = 'store'
      AND loc.custrecord_pm_pos_location LIKE '%D'
  ) as t_def
  on t.father_warehouse_id = t_def.warehouse_def_parent_id
  left join (
    select
      loc.name as warehouse_exh_name, -- 残损仓名称
      loc.id as warehouse_exh_id, -- 残损仓id  
      loc.parent as warehouse_exh_parent_id, 
      loc.custrecord_pm_pos_location as warehouse_exh_code -- 残损仓代码
    from
      ns.location as loc
      left join ns.CUSTOMLIST_PM_LOCATION_TYPE_LIST as list on loc.custrecord_pm_location_type = list.id
    where
      loc.parent is not null
      and list.name = 'store'
      AND loc.custrecord_pm_pos_location LIKE '%E'
  ) as t_exh
  on t.father_warehouse_id = t_exh.warehouse_exh_parent_id