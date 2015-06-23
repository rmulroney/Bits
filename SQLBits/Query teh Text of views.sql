SELECT top 1 sysco.text as [View Definition]
FROM sys.syscomments sysco
JOIN sys.objects sysob ON sysco.id = sysob.object_id
JOIN sys.schemas syssh ON sysob.schema_id = syssh.schema_id
WHERE sysco.text like '%PropertyMappingFinance_toRevenue%'
AND syssh.name = 'dbo'
order by sysob.name;