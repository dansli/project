select *
from dw.dim_fine_user_department_mapping as u 
left join dw.dim_fine_department as d on u.DEPT_ID=d.DEPT_ID
where 
  -- u.USER_NAME='郭晓鹏'
d.LEVEL2_ORG_CODE='100636' and LEVEL3_ORG_CODE='100056' and LEVEL4_ORG_CODE='100057'
and MANAGER_USERID=USER_ID
and LEVEL6_ORG_CODE is null -- 大区
and LEVEL6_ORG_CODE is not null -- 督导


insert into dw.dim_cn_robo_rowauth
select 
  USER_ID,
  USER_NAME,
  u.EMAIL,
  LEVEL1_ORG_NAME,
  LEVEL2_ORG_NAME,
  LEVEL3_ORG_NAME,
  LEVEL4_ORG_NAME,
  LEVEL5_ORG_NAME,
  LEVEL6_ORG_NAME,
  '大区' as role,
  w.wrh_code,
  w.wrh_name,
  r.robot_code
from dw.dim_fine_user_department_mapping as u 
left join dw.dim_fine_department as d on u.DEPT_ID=d.DEPT_ID
left join dw.dim_mannual_robo_warehouse_info as w on w.ctrer=d.LEVEL5_ORG_NAME
left join 
(select distinct city_wrh_code,robot_code
from dw.api_hby_robot_operator_snap 
where store_status='正常' and snap_datetime = date_sub(CURDATE(), interval 1 day)
  ) as r  
on r.city_wrh_code = w.wrh_code
where 
d.LEVEL2_ORG_CODE='100636' and LEVEL3_ORG_CODE='100056' and LEVEL4_ORG_CODE='100057'
and MANAGER_USERID=USER_ID
  and ORG_LEVEL='5'
union 
select 
  USER_ID,
  USER_NAME,
  u.EMAIL,
  LEVEL1_ORG_NAME,
  LEVEL2_ORG_NAME,
  LEVEL3_ORG_NAME,
  LEVEL4_ORG_NAME,
  LEVEL5_ORG_NAME,
  LEVEL6_ORG_NAME,
  '督导' as role,
  w.wrh_code,
  w.wrh_name,
  r.robot_code
from dw.dim_fine_user_department_mapping as u 
left join dw.dim_fine_department as d on u.DEPT_ID=d.DEPT_ID
left join dw.dim_mannual_robo_warehouse_info as w on w.sup_email = u.email
left join 
(select distinct city_wrh_code,robot_code
from dw.api_hby_robot_operator_snap 
where store_status='正常' and snap_datetime = date_sub(CURDATE(), interval 1 day)
  ) as r  
on r.city_wrh_code = w.wrh_code
where 
d.LEVEL2_ORG_CODE='100636' and LEVEL3_ORG_CODE='100056' and LEVEL4_ORG_CODE='100057'
and MANAGER_USERID=USER_ID
  and ORG_LEVEL='6'
union 
select 
  USER_ID,
  USER_NAME,
  u.EMAIL,
  LEVEL1_ORG_NAME,
  LEVEL2_ORG_NAME,
  LEVEL3_ORG_NAME,
  LEVEL4_ORG_NAME,
  LEVEL5_ORG_NAME,
  LEVEL6_ORG_NAME,
  '总部' as role,
  'ALL' as wrh_code,
  'ALL' as wrh_name,
  'ALL' as robot_code
from dw.dim_fine_user_department_mapping as u 
left join dw.dim_fine_department as d on u.DEPT_ID=d.DEPT_ID
where 
d.LEVEL2_ORG_CODE='100636' and LEVEL3_ORG_CODE='100056' and ORG_LEVEL in ('3','4')
union 
select 
distinct 
  USER_ID,
  USER_NAME,
  u.EMAIL,
  LEVEL1_ORG_NAME,
  LEVEL2_ORG_NAME,
  LEVEL3_ORG_NAME,
  LEVEL4_ORG_NAME,
  LEVEL5_ORG_NAME,
  LEVEL6_ORG_NAME,
  '库管' as role,
  w.wrh_code,
  w.wrh_name,
  r.robot_code
from dw.dim_mannual_robo_warehouse_info as w
left join dw.dim_fine_user_department_mapping as u 
on u.email = w.email
left join dw.dim_fine_department as d on u.DEPT_ID=d.DEPT_ID
left join 
(select distinct city_wrh_code,robot_code
from dw.api_hby_robot_operator_snap 
where store_status='正常' and snap_datetime = date_sub(CURDATE(), interval 1 day)
  ) as r  
on r.city_wrh_code = w.wrh_code
where USER_ID is not null



insert into dw.dim_cn_robo_rowauth
select 
  USER_ID,
  USER_NAME,
  u.EMAIL,
  LEVEL1_ORG_NAME,
  LEVEL2_ORG_NAME,
  LEVEL3_ORG_NAME,
  LEVEL4_ORG_NAME,
  LEVEL5_ORG_NAME,
  LEVEL6_ORG_NAME,
  '机器人渠道部-大区' as role,
  w.wrh_code,
  w.wrh_name,
  hr.robot_code
from dw.dim_fine_user_department_mapping as u 
left join dw.dim_fine_department as d on u.DEPT_ID=d.DEPT_ID
left join dw.dim_mannual_robo_warehouse_info as w on w.ctrer=d.LEVEL5_ORG_NAME
left join dw.api_hby_robot_operator_snapshot as hr
on hr.ctrer=d.LEVEL5_ORG_NAME and hr.snapshot_date=date_sub(current_date(),1)
where 
d.LEVEL2_ORG_CODE='100636' and LEVEL3_ORG_CODE='100056' and LEVEL4_ORG_CODE='100057'
and MANAGER_USERID=USER_ID
and ORG_LEVEL='5'
and hr.store_status='正常'
union 
select 
  u.USER_ID,
  u.USER_NAME,
  u.EMAIL,
  LEVEL1_ORG_NAME,
  LEVEL2_ORG_NAME,
  LEVEL3_ORG_NAME,
  LEVEL4_ORG_NAME,
  LEVEL5_ORG_NAME,
  LEVEL6_ORG_NAME,
  '机器人渠道部-督导' as role,
  w.wrh_code,
  w.wrh_name,
  hr.robot_code
from dw.dim_fine_user_department_mapping as u 
left join dw.dim_fine_department as d on u.DEPT_ID=d.DEPT_ID
left join dw.dim_mannual_robo_warehouse_info as w on w.sup_email = u.email
left join dw.api_hby_user_snapshot as hu 
on hu.fs_user_id=u.USER_ID and hu.snapshot_date=date_sub(current_date(),1)
left join dw.api_hby_robot_operator_snapshot as hr 
on hr.sprvsr_id=hu.hby_user_id and hr.snapshot_date=date_sub(current_date(),1)
where 
d.LEVEL2_ORG_CODE='100636' and LEVEL3_ORG_CODE='100056' and LEVEL4_ORG_CODE='100057'
and MANAGER_USERID=USER_ID
and ORG_LEVEL='6'
and hr.store_status='正常'
union 
select 
  USER_ID,
  USER_NAME,
  u.EMAIL,
  LEVEL1_ORG_NAME,
  LEVEL2_ORG_NAME,
  LEVEL3_ORG_NAME,
  LEVEL4_ORG_NAME,
  LEVEL5_ORG_NAME,
  LEVEL6_ORG_NAME,
  '机器人渠道部-总部' as role,
  'ALL' as wrh_code,
  'ALL' as wrh_name,
  'ALL' as robot_code
from dw.dim_fine_user_department_mapping as u 
left join dw.dim_fine_department as d on u.DEPT_ID=d.DEPT_ID
where 
d.LEVEL2_ORG_CODE='100636' and LEVEL3_ORG_CODE='100056' and ORG_LEVEL in ('3','4')
union 
select 
distinct 
  USER_ID,
  USER_NAME,
  u.EMAIL,
  LEVEL1_ORG_NAME,
  LEVEL2_ORG_NAME,
  LEVEL3_ORG_NAME,
  LEVEL4_ORG_NAME,
  LEVEL5_ORG_NAME,
  LEVEL6_ORG_NAME,
  '机器人渠道部-库管' as role,
  w.wrh_code,
  w.wrh_name,
  null as robot_code
from dw.dim_mannual_robo_warehouse_info as w
left join dw.dim_fine_user_department_mapping as u 
on u.email = w.email
left join dw.dim_fine_department as d on u.DEPT_ID=d.DEPT_ID
-- left join 
-- (select city_wrh_code,robot_code,max(snap_datetime) 
-- from dw.api_hby_robot_operator_snap 
-- group by city_wrh_code,robot_code) as r  
-- on r.city_wrh_code = w.wrh_code
where USER_ID is not null



CREATE TABLE dw.dim_cn_robo_rowauth (
    user_id             VARCHAR        COMMENT '用户ID',
    user_name           VARCHAR   COMMENT '用户姓名',
    email               VARCHAR   COMMENT '用户邮箱',
    level1_org_name     VARCHAR   COMMENT '一级组织名称',
    level2_org_name     VARCHAR   COMMENT '二级组织名称',
    level3_org_name     VARCHAR   COMMENT '三级组织名称',
    level4_org_name     VARCHAR   COMMENT '四级组织名称',
    level5_org_name     VARCHAR   COMMENT '五级组织名称',
    level6_org_name     VARCHAR   COMMENT '六级组织名称',
    role                VARCHAR   COMMENT '角色类型',
    wrh_code            VARCHAR   COMMENT '仓库编码',
    wrh_name            VARCHAR   COMMENT '仓库名称',
    robot_code          VARCHAR   COMMENT '机器人编码'
)
COMMENT '国内机器人数据权限表';




create table dw.dim_mannual_robo_warehouse_info(
ctrer varchar comment '大区',
wrh_code varchar comment '仓库代码',
wrh_name varchar comment '仓库名称',
suprvsr_name varchar comment '督导姓名',
splst_name varchar comment '专员姓名',
province varchar comment '省份',
city varchar comment '城市',
area varchar comment '区',
wrh_state varchar comment '仓库状态',
is_entity varchar comment '是否实体',
email varchar comment '邮箱',
role varchar comment '职务',
department varchar comment '部门',
update_time datetime comment '更新时间',
primary key(wrh_code) 
)


:ctrer,
:wrh_code,
:wrh_name,
:suprvsr_name,
:splst_name,
:province,
:city,
:area,
:wrh_state,
:email,
:role,
:department,
:update_time

INSERT INTO dw.dim_mannual_robo_warehouse_info
(
  ctrer,
  wrh_code,
  wrh_name,
  suprvsr_name,
  splst_name,
  province,
  city,
  area,
  wrh_state,
  is_entity,
  email,
  role,
  department,
  update_time
)
VALUES (
  :ctrer,
  :wrh_code,
  :wrh_name,
  :suprvsr_name,
  :splst_name,
  :province,
  :city,
  :area,
  :wrh_state,
  :is_entity,
  :email,
  :role,
  :department,
  :update_time)




  select 
  role.name as role_name, 
  role.id as role_id,
  user.userId as user_id_fr
from fine61db.FINE_CUSTOM_ROLE as role 
left join fine61db.FINE_USER_ROLE_MIDDLE as user 
on role.id=user.roleId
where role.id in ('15ed6386-e9b9-492f-becb-0af89d999816','4e0ca643-20d1-4348-ad91-157e7fd7cac6','6e11e1fa-0db8-4b75-b269-558543e19f4e','7502a278-e710-4a97-a1e4-007144b86a06')