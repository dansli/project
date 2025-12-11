select
jxc.fildate,
jxc.gdgid as sku_hd_id,
jxc.storegid as robo_id,
s.code as robo_code,
s.name as robo_name,
s.rcode as robo_rcode,
jxc.qcqty as robo_qcqty,
jxc.qmqty as robo_qmqty
from sds.jxcsdrpt as jxc -- 门店库存
inner join sds.store as s 
on jxc.storegid=s.gid
where s.qd='机器人'; -- 21,942,798 20天

-- select QUARTER(fildate) from sds.JXCDRPT

-- 64000000/1097139.9

select 
jxc.fildate,
jxc.gdgid as sku_hd_id,
jxc.wrh as robo_wrh_id,
jxc.store as country_wrh_code,
w.code as robo_wrh_code,
w.name as robo_wrh_name,
jxc.qcqty,
jxc.qmqty
from sds.JXCDRPT as jxc -- 仓位库存 store是大仓 wrh是城市仓
inner join sds.warehouse as w 
on jxc.wrh=w.gid
where w.qd='机器人'; -- 27,517,778 311天


-- select * from dw.dim_goods where sku_hd_id='3078283'
select * from sds.store where gid='1015459'


select * from sds.warehouse where gid='1000023'

