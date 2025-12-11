select 
o.num 定单单号,
o.FILDATE 定单日期,
o.VENDORNUM PO单号,
o.cls 单据类型,
w.code 仓库代码,
w.name 仓库名称,
g.code 商品代码,
g.code2 商品条码,
g.name 商品名称,
od.qty 定货数,
od.FCURTOTAL 定单外币金额,
d.FCURTOTAL 入库外币金额,
od.FCURTOTAL-d.FCURTOTAL 未到货外币金额,
o.demanddate 预计到货日期,
o.deaddate 到货终止日期,
o.fildate 创建日期,
m.statname 单据状态,
v.code 供应商代码,
v.name 供应商名称,
/*,od.srcnum 来源单号*/  
decode(bc.name||'['||bc.code||']','[]','',bc.name||'['||bc.code||']') 币种,
/*,s.num 自营进货单单号*/
o.psr 采购员,
od.price 单价,
od.total 定单金额,
od.acvqty 到货数量,
od.acvqty * od.price 到货金额,
od.qty-od.acvqty  未到货数,
(od.qty-od.acvqty)*od.price  未到货金额
from ord o
left join orddtl od
on o.num = od.num 
and o.cls = od.cls 
left join goodsh g
on od.gdgid = g.gid 
left join modulestat m
on o.stat = m.no
left join warehouse w
on o.wrh = w.gid
left join VENDOR v  
on o.VENDOR = v.gid 
left join BaseCurrency bc --,stkin s 
on and v.BASECURRENCY=bc.gid
left join 
(select d.ORDNUM,d.cls,d.GDGID,sum(d.FCURTOTAL) FCURTOTAL   
from stkin s 
left join stkinlog l
left join stkindtl d 
where s.num=l.num
and s.cls=l.cls
and s.num=d.ORDNUM
and s.cls=d.cls
and s.cls='自营进'
and l.stat in (300)
group by
d.ORDNUM,
d.cls,
d.GDGID) d
and o.num=d.ORDNUM
and od.GDGID=d.GDGID
where o.cls='自营进'

