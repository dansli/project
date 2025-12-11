select 
sku_id,
sum(case when receipt_status='1000' or receipt_status='300' then qty else 0 end) as total_received_qty, -- 已收货和已完成为收货数量
sum(case when receipt_status='100' then qty else 0 end) as on_way_qty -- 已审核为在途
from dw.v_dwd_receipt_detail 
where RECEIPT_TYPE='自营进货单'
union all 
select  
sku_id,

from dw.dwd_hd_transfer_order_detail 

