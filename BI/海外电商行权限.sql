CREATE TABLE
  dw.bi_overseas_region_rowauth_ec (
    user_id varchar(100) COMMENT '用户ID',
    user_name varchar(100) COMMENT '用户名',
    user_email varchar(100) COMMENT '邮箱',
    region_name varchar(100) COMMENT '区域名称',
    sub_name varchar(100) COMMENT '主体名称,all为所有行级权限',
    sub_region_flag varchar(50) COMMENT '根据区域/主体判断',
    PRIMARY KEY (user_id, region_name, sub_name)
  ) COMMENT = '海外电商看板行级权限'
insert into
  dw.bi_overseas_region_rowauth_ec
select
  u.FINE_USER_ID,
  u.USER_NAME,
  u.EMAIL,
  case
    when d.LEVEL2_ORG_CODE = '102228' then 'APAC'
    when d.LEVEL2_ORG_CODE = '101922' then 'EUR'
  end as region_name,
  'ALL' as sub_name,
  'region' as sub_region_flag
from
  dw.dim_fine_user_department_mapping as u
  left join dw.dim_fine_department as d on u.DEPT_ID = d.DEPT_ID
where
  (
    d.LEVEL2_ORG_CODE = '102228'
    and d.LEVEL3_ORG_CODE = '100458'
  ) -- 亚太区电商部
  or (
    d.LEVEL2_ORG_CODE = '101922'
    and d.LEVEL3_ORG_CODE = '102602'
  ) -- 欧洲区电商部