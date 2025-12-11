with base_data as (
    select 
        日期，
        仓位代码,
        仓位名称,
        商品代码,
        商品名称,
        在库数量,
        未发货数量,
        可用数量,
        库位
    from 
        (SELECT 
            A.zcalday 日期,
            A.warehouseId 仓位代码,
            c.Name 仓位名称,
            A.stockSku 商品代码,
            B.nameCN 商品名称,
            A.stockQuantity AS 在库数量,
            A.waitingQuantity AS 未发货数量,
            A.stockQuantity-waitingQuantity AS 可用数量,
            A.gridCode 库位
        from 
            ns.zmm_dwb003 A 
        LEFT JOIN 
            mb.mb_sku_code B 
            ON A.stockSku = B.stockSku
        LEFT JOIN 
            mb.mb_cangku C 
            ON A.warehouseId = C.id) as tmp_i
    where 
        仓位名称 in ('A131','A131-AliExpress','A131-GW','A131-GW-GJ','A131-lazada','A131-POPNOW','A131-shopee',
                    'A131-Tiktok','A131-tiktok-phmy','A131-Tiktok-SG','HKTH')),
item_md_oversea as (
    select
        itemid,
        CUSTITEM_PM_ITEM_MAIN_BARCODE as 商品条码,
        CUSTITEM_PM_ENGLISH_NAME as 商品英文名称,
        CUSTITEM_PM_ITEM_BOX as 箱规,
        CUSTITEM_PM_ITEM_CASE as 盒规,
        FIRST_CLASS_NAME_CN as 海外一级分类,
        SECOND_CLASS_NAME_CN as 海外二级分类,
        ZBUSINESS3_TXT as 商业三级分类,
        ZBUSINESS2_TXT as 商业二级分类,
        ZBUSINESS1_TXT as 商业一级分类,
        CUSTITEM_PM_CHINA_PRICE as 国内定价,
        ZLITTLETYPE_TXT as 海鼎类别,
        oversea_ip_name as 海外IP,
        CUSTITEM_PM_VOLUME as 单个体积,
        CUSTITEM_PM_VOLUME * CUSTITEM_PM_ITEM_BOX as 箱体积
    from 
        ns.dim_oversea_item),
item_md_hd as (
    select 
            ZGOODS,
            ZGID as 商品ID,
            ZIP as IP,
            ZIPRW as IP人物,
            ZIP1_TXT as 副IP,
            ZBZXS as 包装形式,
            ZDEF_CPX as 产品线,
            ZSTYLE as 款式,
            ZGROUNDDATE as 上市日期,
            ZSERIES as 系列编码,
            ZSERIES_TXT as 系列名称
        from dw.ZGOODS)
select 
    bd.日期,
    bd.仓位代码,
    bd.仓位名称,
    imhd.系列编码 as 主系列编码,
    imhd.系列名称,
    bd.商品代码,
    imo.商品条码,
    bd.商品名称,
    imo.商品英文名称,
    imhd.上市日期,
    imhd.产品线,
    imhd.IP,
    imo.海外IP,
    imo.海外一级分类,
    imo.海外二级分类,
    imo.商业一级分类,
    imo.商业二级分类,
    imo.商业三级分类,
    imhd.包装形式,
    imhd.款式,
    imo.箱规,
    imo.盒规,
    imo.国内定价 as 零售价,
    imo.单个体积,
    imo.箱体积,
    bd.可用数量 as 可用库存,
    '-only_in_HD-' as 配货在途
from
    base_data as bd
left join
    item_md_oversea as imo
    on bd.商品代码 = imo.itemid
left join
    item_md_hd as imhd
    on bd.商品代码 = imhd.ZGOODS