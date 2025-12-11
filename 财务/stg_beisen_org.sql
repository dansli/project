/*
只取了启用的组织单元，但是保留了状态字段，以备以后需要。
org_type并不准确，很多都维护的不正确。
有不少人的北森userid并不是飞书的userid，是历史原因，所以手动做了映射。
有部分门店代码维护的是‘无’，转为了null值。
*/

create or replace view dw.stg_beisen_org as 
with org as (
  select 
    oid as org_id, -- 组织单元OId
    code as org_code, -- 组织单元编码
    name as org_name, -- 部门机构名称
    -- name_en_US as org_name_en, -- 部门机构名称英文
    status as org_status, -- 状态 0停用、1启用
    establishDate as establish_date, -- 设立日期
    startDate as effective_date, -- 生效日期
    -- stopDate, -- 失效日期 只有9999-12-31 00:00:00
    isVirtualOrg as is_virtual, -- 是否虚拟组织
    personInCharge as manager_userid, -- 部门负责人员工UserID
    case oIdOrganizationType 
      when 'fe5683f0-b531-4f65-9922-01e793401ea4' then '门店'
      when '3824f398-184b-4186-98e1-1eb72bf7ae01' then '办公室'
      when '28b887d5-a773-4628-adaa-69985396fd4f' then '机器人'
      else oIdOrganizationType 
    end as org_type, -- 组织类型实体对象业务数据GUID 
    pOIdOrgAdmin as parent_org_id, -- 行政维度上级组织OId
    -- pOIdOrgReserve2, -- 业务维度上级组织OId 例如所有门店和运营组的上级都是中国大陆北区
    -- isCurrentRecord, -- 是否当前生效 只有1
    -- shopOwner, -- 店长员工UserID 部分没维护，用部门负责人更准确
    -- description, -- 简介
    -- orderAdmin, -- 行政维度顺序号
    -- comment, -- 备注
    pOIdOrgAdmin_TreeLevel - 1 as org_level, -- 行政维度_层级 层级比实际多了一层，所以要-1
    replace(pOIdOrgAdmin_TreePath, '900111276/', '') as org_id_path, -- 行政维度_路径 开头的900111276/应该是租户id 没有实际用处
    -- pOIdOrgReserve2_TreePath, -- 业务维度_路径
    -- pOIdOrgReserve2_TreeLevel, -- 业务维度_层级
    firstLevelOrganization as level1_org_id, -- 一级组织单元OId
    secondLevelOrganization as level2_org_id, -- 二级组织单元OId
    thirdLevelOrganization as level3_org_id, -- 三级组织单元OId
    fourthLevelOrganization as level4_org_id, -- 四级组织单元OId
    fifthLevelOrganization as level5_org_id, -- 五级组织单元OId
    sixthLevelOrganization as level6_org_id, -- 六级组织单元OId
    seventhLevelOrganization as level7_org_id, -- 七级组织单元OId
    eighthLevelOrganization as level8_org_id, -- 八级组织单元OId
    ninthLevelOrganization as level9_org_id, -- 九级组织OId
    -- tenthLevelOrganization, -- 十级组织OId 十级目前都为空，暂时只需要到9级
    -- customproperties, -- 租户级别自定义字段
    -- stdIsDeleted, -- 是否删除 只有0
    replace(json_extract(replace(customproperties, '''', '"'), '$.extmdbm_111276_1676591923'), '"', '') as store_code -- 门店代码
  from BEISEN.Organizations 
  where status = 1 -- 状态 0停用、1启用  
),
feishu_userid_mapping as (
  select 
    beisen_userid,
    feishu_userid
  from values 
  (139065222, 'd64f5879', '司德'),
  (139065430, 'cd16346f', '胡健'),
  (139065792, '5e2977cg', '姚慧蓉'),
  (139074585, 'e6gf499b', '冯旭云'),
  (139074593, 'c4219be8', '储楚'),
  (139074636, '6g14ed9e', '宋泉'),
  (141776389, 'fdg63ad7', '由沂冰'),
  (141777027, '4d51abf5', '郭冬泳'),
  (148567701, 'fcde2e51', '刘楠'),
  (149025134, 'f657gb3f', '刘慧伦'),
  (150195530, '2g8c85af', '李尉铭'),
  (150203528, '3fg1b9ce', '董碧莹'),
  (151886590, '14aa9292', '邢旭智'),
  (152213089, 'de4a74g3', '卢永辉'),
  (153868750, 'd3a95c1b', '许恋恋'),
  (155083722, 'g59e821g', '李睦涵'),
  (155237464, 'egd62896', '顾思婕'),
  (155894848, 'cdada646', '何睿'),
  (157089048, 'ge4f756d', '冯乐颖'),
  (160348566, '8d753b6a', '安童'),
  (165262914, 'dc917737', '路晞'),
  (168271008, '77879gbg', 'Kaye Yu'),
  (168271010, 'bg72d2cf', 'Lee Eunjeong'),
  (168271011, 'b941bgff', 'YU Hon Man'),
  (168271013, '93d4c1d7', 'LAW Wai Lok'),
  (168271014, 'c8555c38', 'KUNG Ka Ho'),
  (168271017, 'f1f13773', 'KONG Yuen Man'),
  (168271022, '7c39e71g', 'LEUNG Tsz Shan'),
  (168272344, 'd19bb361', 'LEE Tat San'),
  (172312226, 'g8d167f6', 'Sasha Deng'),
  (172369454, 'g8gd8ebf', 'LI Kin Yu'),
  (172370256, '3372dd42', 'LI Yuen Kwan'),
  (174259494, '47gb8b51', 'Ying Wang'),
  (174843626, 'ae9e946b', 'Stella Du'),
  (177857536, 'dc6eg6f3', '陈佳妮'),
  (178539297, '395f9821', 'Zhang Jing Lei'),
  (181199905, '94e6be12', 'Nok Siriporn'),
  (181201442, '55a4aee3', 'Noii Nutchanika'),
  (181203100, 'dg121b92', 'Fai Thaphatkorn'),
  (181204579, 'ebb97e5a', 'Au Rattiya'),
  (181204868, '86g63bcg', 'Kae Duangduaen'),
  (185862852, '3ge7d93b', 'Ang Eng Soon'),
  (192989907, '15491731', 'Jiawen Ji') 
  as feishu_userid_mapping(beisen_userid, feishu_userid, user_name) 
)
select 
  o.org_id, -- 组织单元id
  o.org_code, -- 组织单元代码
  o.org_name, -- 组织单元名称
  o.org_status, -- 状态 0停用、1启用
  o.establish_date, -- 设立日期
  o.effective_date, -- 生效日期
  o.is_virtual, -- 是否虚拟组织
  ifnull(um.feishu_userid, o.manager_userid) as manager_userid, -- 部门负责人员工UserID
  o.org_type, -- 组织单元类型 门店、办公室、机器人
  if(o.store_code = '无', null ,o.store_code) as store_code, -- 门店代码
  o.parent_org_id, -- 上级组织单元OId
  po.org_code as parent_org_code, -- 上级组织单元代码
  po.org_name as parent_org_name, -- 上级组织单元名称
  o.org_level, -- 行政维度_层级
  o.org_id_path, -- 行政维度_路径OId
  case o.org_level 
    when 1 then o1.org_name 
    when 2 then concat(o1.org_name, '/', o2.org_name) 
    when 3 then concat(o1.org_name, '/', o2.org_name, '/', o3.org_name) 
    when 4 then concat(o1.org_name, '/', o2.org_name, '/', o3.org_name, '/', o4.org_name) 
    when 5 then concat(o1.org_name, '/', o2.org_name, '/', o3.org_name, '/', o4.org_name, '/', o5.org_name) 
    when 6 then concat(o1.org_name, '/', o2.org_name, '/', o3.org_name, '/', o4.org_name, '/', o5.org_name, '/', o6.org_name) 
    when 7 then concat(o1.org_name, '/', o2.org_name, '/', o3.org_name, '/', o4.org_name, '/', o5.org_name, '/', o6.org_name, '/', o7.org_name) 
    when 8 then concat(o1.org_name, '/', o2.org_name, '/', o3.org_name, '/', o4.org_name, '/', o5.org_name, '/', o6.org_name, '/', o7.org_name, '/', o8.org_name) 
    when 9 then concat(o1.org_name, '/', o2.org_name, '/', o3.org_name, '/', o4.org_name, '/', o5.org_name, '/', o6.org_name, '/', o7.org_name, '/', o8.org_name, '/', o9.org_name)
  end as org_name_path, -- 行政维度_路径名称
  o.level1_org_id, -- 一级组织单元OId
  o1.org_code as level1_org_code, -- 一级组织单元代码
  o1.org_name as level1_org_name, -- 一级组织单元名称
  o.level2_org_id, -- 二级组织单元OId
  o2.org_code as level2_org_code, -- 二级组织单元代码
  o2.org_name as level2_org_name, -- 二级组织单元名称
  o.level3_org_id, -- 三级组织单元OId
  o3.org_code as level3_org_code, -- 三级组织单元代码
  o3.org_name as level3_org_name, -- 三级组织单元名称
  o.level4_org_id, -- 四级组织单元OId
  o4.org_code as level4_org_code, -- 四级组织单元代码
  o4.org_name as level4_org_name, -- 四级组织单元名称
  o.level5_org_id, -- 五级组织单元OId
  o5.org_code as level5_org_code, -- 五级组织单元代码
  o5.org_name as level5_org_name, -- 五级组织单元名称
  o.level6_org_id, -- 六级组织单元OId
  o6.org_code as level6_org_code, -- 六级组织单元代码
  o6.org_name as level6_org_name, -- 六级组织单元名称
  o.level7_org_id, -- 七级组织单元OId
  o7.org_code as level7_org_code, -- 七级组织单元代码
  o7.org_name as level7_org_name, -- 七级组织单元名称
  o.level8_org_id, -- 八级组织单元OId
  o8.org_code as level8_org_code, -- 八级组织单元代码
  o8.org_name as level8_org_name, -- 八级组织单元名称
  o.level9_org_id, -- 九级组织单元OId
  o9.org_code as level9_org_code, -- 九级组织单元代码
  o9.org_name as level9_org_name, -- 九级组织单元名称
  not exists(select 1 from org as child where child.parent_org_id = o.org_id) as is_leaf_org -- 是否为末级组织单元 1是 0否
from org as o 
left join org as po 
on o.parent_org_id = po.org_id
left join org as o1
on o.level1_org_id = o1.org_id
left join org as o2
on o.level2_org_id = o2.org_id
left join org as o3
on o.level3_org_id = o3.org_id
left join org as o4
on o.level4_org_id = o4.org_id
left join org as o5
on o.level5_org_id = o5.org_id
left join org as o6
on o.level6_org_id = o6.org_id
left join org as o7
on o.level7_org_id = o7.org_id
left join org as o8
on o.level8_org_id = o8.org_id
left join org as o9
on o.level9_org_id = o9.org_id
left join feishu_userid_mapping as um 
on o.manager_userid = um.beisen_userid
