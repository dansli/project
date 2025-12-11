select

count(distinct t.tranid) as ord_cnt,
sum(t.sale_qty),
sum(t.incl_tax_rmb_amt),
sum(t.incl_tax_foreign_amt),
from
dw.dwd_trans_line as t
left JOIN dim_customer_subsidiary as c
on t.entity_id = c.cus_id