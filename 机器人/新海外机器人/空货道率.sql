select
    custom_id,
    machine_id,
    CASE
        WHEN custom_id IN ('POPMARTUK') THEN CONVERT_TZ (extract_time, 'Asia/Shanghai', 'Europe/London')
        WHEN custom_id IN ('FRANCE-SOGEEK', 'France', 'Germany') THEN CONVERT_TZ (extract_time, 'Asia/Shanghai', 'Europe/Paris')
        WHEN custom_id IN ('Australia-popmart', 'Australia-TOP-1') THEN CONVERT_TZ (extract_time, 'Asia/Shanghai', 'Australia/Sydney')
        WHEN custom_id IN ('New-Zealand') THEN CONVERT_TZ (extract_time, 'Asia/Shanghai', 'Pacific/Auckland')
        WHEN custom_id IN ('USA', 'USA-AH', 'USA_LA528') THEN CONVERT_TZ (
            extract_time,
            'Asia/Shanghai',
            'America/Los_Angeles'
        )
        WHEN custom_id IN ('CAN_SYoung', 'CAN', 'CAN_Token', 'CAN_Mindzai') THEN CONVERT_TZ (extract_time, 'Asia/Shanghai', 'America/Toronto')
        ELSE extract_time
    END AS extract_time_transformed,
    extract_time,
    count(distinct slot_id) as slot_count,
    sum(
        case
            when state = 'empty' then 1
            else 0
        end
    ) as empty_count
from
    sds.hy_get_machine_slots_info_recode
group by
    custom_id,
    machine_id,
    CASE
        WHEN custom_id IN ('POPMARTUK') THEN CONVERT_TZ (extract_time, 'Asia/Shanghai', 'Europe/London')
        WHEN custom_id IN ('FRANCE-SOGEEK', 'France', 'Germany') THEN CONVERT_TZ (extract_time, 'Asia/Shanghai', 'Europe/Paris')
        WHEN custom_id IN ('Australia-popmart', 'Australia-TOP-1') THEN CONVERT_TZ (extract_time, 'Asia/Shanghai', 'Australia/Sydney')
        WHEN custom_id IN ('New-Zealand') THEN CONVERT_TZ (extract_time, 'Asia/Shanghai', 'Pacific/Auckland')
        WHEN custom_id IN ('USA', 'USA-AH', 'USA_LA528') THEN CONVERT_TZ (
            extract_time,
            'Asia/Shanghai',
            'America/Los_Angeles'
        )
        WHEN custom_id IN ('CAN_SYoung', 'CAN', 'CAN_Token', 'CAN_Mindzai') THEN CONVERT_TZ (extract_time, 'Asia/Shanghai', 'America/Toronto')
        ELSE extract_time
    END,
    extract_time