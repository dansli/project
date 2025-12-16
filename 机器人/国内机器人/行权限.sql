select *
from dw.dim_fine_user_department_mapping as u 
left join dw.dim_fine_department as d on u.DEPT_ID=d.DEPT_ID
where 
  -- u.USER_NAME='郭晓鹏'
d.LEVEL2_ORG_CODE='100636' and LEVEL3_ORG_CODE='100056' and LEVEL4_ORG_CODE='100057'
and MANAGER_USERID=USER_ID