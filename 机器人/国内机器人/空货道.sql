select
    s.notify_time,
    rb.ctrer,
    hy.sprvsr_name,
    hy.splst_name,
    count(distinct s.machine_id) as machine_count,
    sum(s.total_count) as total_count,
    sum(s.empty_count) as empty_count
from
    hy.machine_slot_record_cn as s
    left join dw.api_hby_robot_operator as hy on s.machine_id = hy.robot_code
    left join sds.store as rb on s.machine_id = rb.rcode
where
    date_format (s.notify_time, '%Y-%m-%d %H:%i:00') between '${start}' and '${end}'
group by
    rb.ctrer,
    hy.sprvsr_name,
    hy.splst_name,
    s.notify_time