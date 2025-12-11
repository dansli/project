/*
只包含启用的用户。
只mapping了部门职位的用户，不包含自定义角色的用户。
*/

create or replace view dw.dim_fine_user_department_mapping as 
select 
  u.id as fine_user_id, -- 帆软用户id
  u.username as user_id, -- 用户id
  u.realname as user_name, -- 用户姓名
  u.mobile, -- 手机号
  u.email, -- 邮箱
  u.creationtype as creation_type, -- 创建类型 1：手动创建 2：同步创建
--   u.enable as is_active, -- 是否启用 1：启用 0：不启用
  dr.departmentid as dept_id -- 部门id
from fr.fine_user as u 
inner join fr.fine_user_role_middle as urm 
on u.id = urm.userid 
and urm.roletype = 1 -- 角色类型 1:部门职位 2：自定义角色
inner join fr.fine_dep_role as dr
on urm.roleid = dr.id 
where u.enable = 1  -- 是否启用 1：启用 0：不启用

