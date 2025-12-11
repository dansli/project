replace into ns.zods_taxandtotsel
select a.trandate,a.tranid,b.taxline_type,round(sum(a.tot_amount),2) tot_amount,round(sum(a.tax_amount),4) tax_amount,sum(a.stat) stat,max(ratepercent) ratepercent
from
(
  select a.trandate,a.tranid,0.00 tot_amount,SUM(a.foreignamount*-1) tax_amount,1 stat
  from ns.zods_taxline a
  group by a.trandate,a.tranid
  union all
  select tr.trandate,tr.tranid,SUM(trl.foreignamount*-1) tot_amount,0.00 tax_amount,0 stat
  from ns.transactionline trl left join ns.transaction tr on tr.id=trl.TRANSACTION
  where itemtype in('InvtPart')
        and tr.recordtype in ('invoice','creditmemo','salesorder','returnauthorization')
        and trl.isinventoryaffecting = 'F'
        and trl.IsCogs = 'F'
  group by tr.trandate,tr.tranid
) a left join 
        (
          select trandate,tranid,taxline_type,ratepercent
          from
          (
              select tr.trandate,tr.tranid,
                     case when b.tranid is not null and trl.foreignamount=0 and trl.ratepercent<>0 then '有税率有税金'
                          when trl.foreignamount=0 and trl.ratepercent<>0 then '有税率无税金'
                          when trl.foreignamount<>0 and trl.ratepercent=0 then '无税率有税金'
                          when trl.foreignamount=0 and trl.ratepercent=0 then '无税率无税金'
                          when trl.foreignamount<>0 and trl.ratepercent<>0 then '有税率有税金'
                     end as taxline_type,
                     case when trl.foreignamount=0 and trl.ratepercent<>0 then ratepercent else 0 end as ratepercent
              from ns.transactionline trl left join ns.transaction tr on tr.id=trl.TRANSACTION
                                          left join ns.zods_taxtypecnt b on tr.trandate=b.trandate and tr.tranid=b.tranid
              where itemtype in('TaxItem','TaxGroup')
                    and tr.recordtype in ('invoice','creditmemo','salesorder','returnauthorization')
                    and trl.isinventoryaffecting = 'F'
                    and trl.IsCogs = 'F'
          )
          where taxline_type<>'无税率无税金'
          group by trandate,tranid,taxline_type
        ) b on a.trandate=b.trandate and a.tranid=b.tranid
where a.trandate>=date_format(CURDATE + interval -3 day,'yyyyMMdd')
group by a.trandate,a.tranid,b.taxline_type