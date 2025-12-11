with base_contract_data as 
    (select
        i.InvoiceNo as 合同编号,
        i.date as 合同日期,
        i.totalSalePrice as 商品国内售价总额_CNY,
        i.orderPricce as 合同金额,
        i.tradeCurrency as 交易币种,
        i.fobEnName as 贸易条款,
        i.freightDesc as 收款备注,
        i.orderNoStr as 订单号,
        i.hdOrderNo as 出库单号,
        i.dolDocumentBatchNo as 报关文件, -- 待确认
        i.documentBatchNo as 清关文件, -- 待确认
        date_format(i.paymentTime,'yyyy-MM-dd') as 付款时间,
        date_format(i.pickTime,'yyyy-MM-dd') as 拣货时间,
        date_format(i.deliveryTime,'yyyy-MM-dd') as 出库时间,
        date_format(i.finishTime,'yyyy-MM-dd') as 完成时间, -- 判断用
        date_format(i.cancelTime,'yyyy-MM-dd') as 取消时间, -- 判断用
        date_diff(date_format(i.deliveryTime,'yyyy-MM-dd'),
                    date_format(i.paymentTime,'yyyy-MM-dd')) as 实际库内流转时间,
        '- None -' as 标准库内流转时间,
        case 
            when i.contractState = 1 then '未付款'
            when i.contractState = 2 then '已付款'
            when i.contractState = 3 then '待发货'
            when i.contractState = 4 then '已发货'
            when i.contractState = 5 then '已完成'
            when i.contractState = 6 then '已作废'
            else '-ERROR-' 
        end as 合同状态,
        i.eta,
        i.ata,
        i.etd,
        i.atd,
        date_format(i.consignmentTime,'yyyy-MM-dd') as 清关放行时间,
        date_format(i.inStorageTime,'yyyy-MM-dd') as 入库时间,
        date_diff(i.ata,i.deliveryTime) as DTD实际用时,
        i.dtdStandardTime as DTD标准时效,
        date_diff(i.ata,i.paymentTime) as 实际订单总用时,
        '- None -' as 标准订单总用时,
        '- None -' as 差异天数_base,
        i.exceptionMsg as 异常原因,
        i.operator as 运营商，
        i.customerCode as 客户编码，
        i.customerFullName as 客户全称,
        i.channelCnName as 客户渠道,
        case 
            when ii.name = '台湾,中国' then '中国台湾'
            when ii.name = '香港,中国' then '中国香港'
            when ii.name = '澳门' then '中国澳门'
            else ii.name
        end as 客户,
        case 
            when i.freightDesc like '%威海%' then '威海'
        end as 韩国威海发运，
        case 
            when i.transportType = 1 then 'SEA'
            when i.transportType = 2 then 'AIR'
            when i.transportType = 3 then 'LAND'
            when i.transportType = 4 then 'TRAIN'
     		else i.transportType
        end as 运输方式,
        case 
            when iii. cargoState = 1 then '可发货'
            when iii. cargoState = 2 then '拣货中'
            when iii. cargoState = 3 then '已发货'
            when iii. cargoState = 4 then '等开船'
            when iii. cargoState = 5 then '已开船'
            when iii. cargoState = 6 then '已到港'
            when iii. cargoState = 7 then '清关中'
            when iii. cargoState = 8 then '已交货'
        end as 货物状态,
        nvl(iv.国家,'-') as 国家,
        nvl(iv.客户名称,'其他') as 客户名称,
        nvl(iv.区域,'其他') as 区域
    from 
        (select 
            InvoiceNo,date,totalSalePrice,orderPricce,tradeCurrency,
            fobEnName,freightDesc,orderNoStr,hdOrderNo,dolDocumentBatchNo,
            documentBatchNo,paymentTime,pickTime,deliveryTime,finishTime,
            cancelTime,eta,ata,etd,atd,consignmentTime,inStorageTime,
            contractState,transportType,exceptionMsg,operator,customerCode,
            customerFullName,channelCnName,countryRegioncode,dtdStandardTime
        from 
            sds_int.ads_oversea_supplychain_contract_detail
        where 
            date between '${start}' and '${end}'
            and 1=1<parameter>and InvoiceNo in ('${InvoiceNo}')</parameter>
            and 1=1<parameter>and orderNoStr in ('${orderNoStr}')</parameter>
            and 1=1<parameter>and hdOrderNo in ('${hdOrderNo}')</parameter>
            and 1=1<parameter>and contractState in ('${contractState}')</parameter>
            and 1=1<parameter>and customerFullName in ('${customerFullName}')</parameter>
            and 1=1<parameter>and channelCnName in ('${channelCnName}')</parameter>
            and 1=1<parameter>and transportType in ('${transportType}')</parameter>) as i
    left join 
        ns.CUSTOMRECORD_HC_TRADING_COUNTRY as ii
        on i.countryRegioncode = ii.custrecord_hc_tc_name_en
    left join 
        (select 
            distinct 
                InvoiceNo, 
                cargoState 
        from 
            sds_int.ads_oversea_supplychain_order_detail) as iii
        on i.InvoiceNo = iii.InvoiceNo
    left join 
        (SELECT distinct 客户代码, 客户渠道, 国家, 客户名称, 区域 
         FROM sds_int.dim_oversea_supplychain_customer_region_relationship) AS iv
        ON i.channelCnName = iv.客户渠道
    where 
        1=1<parameter>and 货物状态 in ('${cargoState}')</parameter>
        and 1=1<parameter>and 国家 in ('${country}')</parameter>
        and 1=1<parameter>and 客户名称 in ('${customer_name}')</parameter>
        and 1=1<parameter>and 区域 in ('${area}')</parameter>
    ),


add_transtype_ordertype as 
    (select 
        *,
        concat(客户名称,nvl(韩国威海发运,''),运输方式) as 客户_运输方式,
        CASE 
            WHEN 货物状态 IS NULL THEN '在库'
            WHEN 货物状态 IS NOT NULL THEN
                CASE 
                    WHEN 入库时间 IS NULL THEN 
                        CASE 
                            WHEN ata IS NOT NULL THEN '在途，已到港'
                            ELSE '在途，未到港'
                        END
                    ELSE '已入仓'
                END
        ELSE NULL
    END as 订单状态
    from 
        base_contract_data),
Actual_order_limitation_detail as 
    (select 
        *,
        CASE 
            WHEN 订单状态 = '在库' THEN FLOOR(DATEDIFF(CURDATE(), CAST(付款时间 AS DATE)))
            ELSE FLOOR(DATEDIFF(CAST(出库时间 AS DATE), CAST(付款时间 AS DATE)))
        END as 库内流转,
        CASE 
            WHEN 订单状态 = '在库' THEN 0
            WHEN 订单状态 = '已入仓' THEN FLOOR(date_diff(cast(atd as date),cast(出库时间 as date)))
            WHEN 订单状态 = '在途，未到港' THEN FLOOR(date_diff(cast(etd as date),cast(出库时间 as date)))
            WHEN 订单状态 = '在途，已到港' THEN FLOOR(date_diff(cast(atd as date),cast(出库时间 as date)))
        END as 起运前置期,
        CASE 
            WHEN 订单状态 = '在库' THEN 0
            WHEN 订单状态 = '在途，未到港' THEN FLOOR(date_diff(cast(eta as date),cast(etd as date)))
            WHEN 订单状态 = '在途，已到港' THEN FLOOR(date_diff(cast(ata as date),cast(atd as date)))
            WHEN 订单状态 = '已入仓' THEN FLOOR(date_diff(cast(ata as date),cast(atd as date)))
        END as 港到港运输,
        CASE 
            WHEN 订单状态 = '在库' THEN 0
            WHEN 订单状态 = '在途，未到港' THEN 0
            WHEN 订单状态 = '在途，已到港' THEN 0
            WHEN 订单状态 = '已入仓' THEN FLOOR(date_diff(cast(清关放行时间 as date),cast(ata as date)))
        END as 进口清关,
        CASE 
            WHEN 订单状态 = '在库' THEN 0
            WHEN 订单状态 = '在途，未到港' THEN 0
            WHEN 订单状态 = '在途，已到港' THEN 0
            WHEN 订单状态 = '已入仓' THEN FLOOR(date_diff(cast(入库时间 as date),cast(清关放行时间 as date)))
        END as 入仓时间
    from 
        add_transtype_ordertype),
add_order_standard_time_limition as 
    (select 
        i.*,
        i.库内流转 + i.起运前置期 + i.港到港运输 + i.进口清关 + i.入仓时间 as 实际订单时效,
        ii.库内流转 as 库内流转_std,
        ii.起运前置期 as 起运前置期_std,
        ii.港到港运输 as 港到港运输_std,
        ii.进口清关 as 进口清关_std,
        ii.入仓时间 as 入仓时间_std,
        nvl(ii.下单到门标准时间,0) as 下单到门标准时间_std,
        floor(i.库内流转 - ii.库内流转) as 库内流转_gap,
        floor(i.起运前置期 - ii.起运前置期) as 起运前置期_gap,
        floor(i.港到港运输 - ii.港到港运输) as 港到港运输_gap,
        floor(i.进口清关 - ii.进口清关) as 进口清关_gap,
        floor(i.入仓时间 - ii.入仓时间) as 入仓时间_gap,
        floor(i.库内流转 - ii.库内流转) + floor(i.起运前置期 - ii.起运前置期) +
            floor(i.港到港运输 - ii.港到港运输) + floor(i.进口清关 - ii.进口清关) +
            floor(i.入仓时间 - ii.入仓时间) as 差异天数
    from 
        Actual_order_limitation_detail as i
    left join 
        (select 
            渠道_统一,运输方式,渠道_运输方式,下单到门标准时间,库内流转,
            起运前置期,港到港运输,进口清关,入仓时间,港到港_清关,清关_入仓,DTD标准
        from 
            sds_int.dim_oversea_supplychain_order_time_limition as ii)
    on i.客户_运输方式 = ii.渠道_运输方式),
add_order_risk_judgement as 
    (select 
        *,
        CASE 
            WHEN 订单状态 = '在库' THEN 
                CASE 
                    WHEN 库内流转_gap > 0 THEN '库内有风险'
                    ELSE '库内正常'
                END
            ELSE 0
        END AS 在库风险状态，
        CASE 
            WHEN 订单状态 = '已入仓' THEN 
                CASE 
                    WHEN 差异天数 > 0 THEN '已入仓异常'
                    ELSE '已入仓正常'
                END
            ELSE 0
        END AS 入仓风险判断,
        CASE
            WHEN 订单状态 = '在库' THEN 0
            WHEN 订单状态 = '已入仓' THEN 0
            WHEN 订单状态 = '在途，未到港' THEN
                CASE
                    WHEN 差异天数 > 0 THEN '在途异常'
                    ELSE '在途正常'
                END
            WHEN 订单状态 = '在途，已到港' THEN
                CASE
                    WHEN 差异天数 > 0 THEN '在途异常'
                    ELSE '在途正常'
                END
        END AS 在途异常判断       
    from
        add_order_standard_time_limition),
add_order_risk_judgement_saving_product as 
    (select 
        *,
        CASE
            WHEN 入仓风险判断 = '已入仓异常' then 
                case 
                    when  (差异天数 - 库内流转_gap) > 0 THEN '已入仓异常_不攒货'
                    else 0
                end
            ELSE 0
        END AS 入仓_异常_不攒货判断,
        CASE
            when 在途异常判断 = '在途异常' then 
                case
                    when (差异天数 - 库内流转_gap) > 0 then '在途异常_不攒货'
                    else 0
                end
            else 0
        end as 在途_异常_不攒货判断
    from add_order_risk_judgement),
add_order_amount_by_risk_judgement as 
    (select
        *,
        date_add(付款时间,interval 下单到门标准时间_std day) as 下单到门标准时间,
        case
            when 入仓风险判断 = '已入仓异常' then 1
            when 在途异常判断 = '在途异常' then 1
        end as 异常订单性质,
        case
            when 在库风险状态 = '库内正常' then 商品国内售价总额_CNY
            else 0
        end as 在库正常金额,
        case 
            when 在库风险状态 = '库内有风险' then 商品国内售价总额_CNY
            else 0
        end as 在库有风险金额,
        case
            when 在途异常判断 = '在途正常' then 商品国内售价总额_CNY
            else 0
        end as  在途正常金额,
        case
            when 在途异常判断 = '在途异常' then 商品国内售价总额_CNY
            else 0
        end as  在途异常金额,
        case 
            when 入仓风险判断 = '已入仓正常' then 商品国内售价总额_CNY
            else 0
        end as 已入仓正常金额,
        case 
            when 入仓风险判断 = '已入仓异常' then 商品国内售价总额_CNY
            else 0
        end as 已入仓异常金额,
        case 
            when 在途_异常_不攒货判断 = '在途异常_不攒货' then 商品国内售价总额_CNY
            else 0
        end as 在途异常_不攒货金额,
        case 
            when 入仓_异常_不攒货判断 = '已入仓异常_不攒货' then 商品国内售价总额_CNY
            else 0
        end as 已入仓异常_不攒货金额
    from add_order_risk_judgement_saving_product)
SELECT 
    -- 基本信息
    合同编号,合同日期, 商品国内售价总额_CNY, 合同金额, 交易币种, 贸易条款, 收款备注, 订单号, 
    出库单号, 报关文件, 清关文件, 付款时间, 拣货时间, 出库时间, 库内流转_std AS 标准库内流转时间, 实际库内流转时间, 
    合同状态, 货物状态, 运输方式, etd, atd, eta, ata, 清关放行时间, 入库时间, DTD实际用时, DTD标准时效, 
    实际订单总用时, 标准订单总用时 AS 标准订单总用时_待定, 差异天数_base AS 差异天数_待定, 异常原因, 运营商, 
    客户编码, 客户全称, 客户渠道,
    -- AJ列之后(包含自建表)
    区域, 客户, 韩国威海发运, 客户_运输方式, 订单状态,
    -- 实际订单时效
    实际订单时效, 库内流转 AS 库内流转_实际, 起运前置期 AS 起运前置期_实际, 港到港运输 AS 港到港运输_实际, 
    进口清关 AS 进口清关_实际, 入仓时间 AS 入仓时间_实际,
    -- 与标准时效对比
    差异天数 AS 实际订单时效_对比, 库内流转_gap AS 库内流转_对比, 起运前置期_gap AS 起运前置期_对比, 
    港到港运输_gap AS 港到港运输_对比, 进口清关_gap AS 进口清关_对比, 入仓时间_gap AS 入仓时间_对比,
    -- 标准时效
    库内流转_std AS 库内流转_标准, 起运前置期_std AS 起运前置期_标准, 港到港运输_std AS 港到港运输_标准, 
    进口清关_std AS 进口清关_标准, 入仓时间_std AS 入仓时间_标准, 下单到门标准时间_std AS 下单到门标准时间_标准,
    -- 异常判断
    在库风险状态 AS 在库_有风险判断, 入仓风险判断 AS 已入仓_异常判断, 在途异常判断 AS 在途_异常判断, 
    入仓_异常_不攒货判断 AS 已入仓异常_不攒货判断, 在途_异常_不攒货判断 AS 在途异常_不攒货判断,
    -- 生成透视表区域
    下单到门标准时间 AS 订单预计到达时间, 异常订单性质, 在库正常金额, 在库有风险金额, 在途正常金额, 
    在途异常金额, 已入仓正常金额, 已入仓异常金额, 在途异常_不攒货金额, 已入仓异常_不攒货金额
FROM 
    add_order_amount_by_risk_judgement