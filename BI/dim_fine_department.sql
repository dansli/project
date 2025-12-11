/*  
用了ADB标准列转行的方案，采用corss join unnest的方式来实现分割字符串，没有使用递归。
帆软继承了飞书的组织架构，但是却是自己的id编码，所以只能通过名称来关联北森，因为有很多重名，甚至上级部门也重名，所以只能通过路径来关联。
帆软的组织里有很多是假组织，在飞书手动创建的组织，这时候北森是没有的。
*/

create or replace view dw.dim_fine_department as 
with fr_dept_path as (
  select 
    d.dept_id, -- 帆软部门id
    d.dept_name, -- 帆软部门名称
    d.parent_dept_id, -- 上级部门id
    d.dept_id_path, -- 部门id路径
    t.path_id -- 部门路径id
  from (
    select 
      id as dept_id,
      name as dept_name,
      parentid as parent_dept_id,
      fullpath as dept_id_path,
      split(ifnull(concat(fullpath, '-_-', id), id), '-_-') as dept_path_array 
    from fr.fine_department
  ) as d 
  cross join unnest(dept_path_array) as t(path_id)
),
fr_dept as (
  select 
    dp.dept_id, -- 帆软部门id
    dp.dept_name, -- 帆软部门名称
    dp.parent_dept_id, -- 上级部门id
    pd.name as parent_dept_name, -- 上级部门名称
    ifnull(concat(dp.dept_id_path, '-_-', dp.dept_id), dp.dept_id) as dept_id_path, -- 部门id路径
    group_concat(d.name order by ifnull(concat(d.fullpath, '-_-', d.id), d.id) separator '/') as dept_name_path -- 部门名称路径
  from fr_dept_path as dp 
  inner join fr.fine_department as d 
  on dp.path_id = d.id 
  left join fr.fine_department as pd
  on dp.parent_dept_id = pd.id
  group by 
    dp.dept_id, 
    dp.dept_name,
    dp.parent_dept_id,
    pd.name,
    ifnull(concat(dp.dept_id_path, '-_-', dp.dept_id), dp.dept_id) 
)
select 
  d.dept_id, -- 帆软部门id
  d.dept_name, -- 帆软部门名称
  o.manager_userid, -- 部门负责人员工UserID
  o.org_type, -- 组织单元类型 门店、办公室、机器人
  o.store_code, -- 门店代码
  d.parent_dept_id, -- 上级部门id
  d.parent_dept_name, -- 上级部门名称
  d.dept_id_path, -- 部门id路径
  d.dept_name_path, -- 部门名称路径
  o.org_id, -- 组织单元id
  o.org_code, -- 组织单元代码
  o.parent_org_code, -- 上级组织单元代码
  o.org_level, -- 行政维度_层级
  o.level1_org_code, -- 一级组织单元代码
  o.level1_org_name, -- 一级组织单元名称
  o.level2_org_code, -- 二级组织单元代码
  o.level2_org_name, -- 二级组织单元名称
  o.level3_org_code, -- 三级组织单元代码
  o.level3_org_name, -- 三级组织单元名称
  o.level4_org_code, -- 四级组织单元代码
  o.level4_org_name, -- 四级组织单元名称
  o.level5_org_code, -- 五级组织单元代码
  o.level5_org_name, -- 五级组织单元名称
  o.level6_org_code, -- 六级组织单元代码
  o.level6_org_name, -- 六级组织单元名称
  o.level7_org_code, -- 七级组织单元代码
  o.level7_org_name, -- 七级组织单元名称
  o.level8_org_code, -- 八级组织单元代码
  o.level8_org_name, -- 八级组织单元名称
  o.level9_org_code, -- 九级组织单元代码
  o.level9_org_name, -- 九级组织单元名称
  o.is_leaf_org -- 是否为末级组织单元 1是 0否
from fr_dept as d 
left join dw.stg_beisen_org as o -- 北森组织过渡层
on d.dept_name_path = o.org_name_path


/* -- 递归 
-- 首先创建一个辅助数字表用于分割字符串
WITH RECURSIVE numbers(n) AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 9 -- 假设部门层级不超过100
),
path_components(department_id,original_path,component_id,position) AS (
    -- 提取每个部门的路径组件(ID)
    SELECT 
        d.id AS department_id,
        d.fullpath AS original_path,
        -- 使用MySQL字符串分割方法
        SUBSTRING_INDEX(SUBSTRING_INDEX(d.fullpath, '-_-', n), '-_-', -1) AS component_id,
        numbers.n AS position
    FROM fr.fine_department d
    JOIN numbers ON 
        numbers.n <= (LENGTH(d.fullpath) - LENGTH(REPLACE(d.fullpath, '-_-', ''))) / 3 + 1
    WHERE SUBSTRING_INDEX(SUBSTRING_INDEX(d.fullpath, '-_-', n), '-_-', -1) != ''
),
name_components(department_id,original_path,position,component_name) AS (
    -- 查找每个组件ID对应的名称
    SELECT 
        pc.department_id,
        pc.original_path,
        pc.position,
        d.name AS component_name
    FROM path_components pc
    JOIN fr.fine_department d ON pc.component_id = d.id
)
-- 生成最终结果
SELECT 
    d.id,
    d.parentid,
    d.fullpath AS original_fullpath,
    -- 使用MySQL的GROUP_CONCAT进行名称组合
    GROUP_CONCAT(nc.component_name ORDER BY nc.position SEPARATOR '/') AS name_fullpath,
    d.name
FROM fr.fine_department d
LEFT JOIN name_components nc ON d.id = nc.department_id
GROUP BY d.id, d.parentid, d.fullpath, d.name; */