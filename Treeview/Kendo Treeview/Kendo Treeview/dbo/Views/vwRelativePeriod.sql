




CREATE view [dbo].[vwRelativePeriod] as 

select 1 as RelativePeriodID, 'Current Period' as RelativePeriodType
union 
select 2 as RelativePeriodID, 'Year to date' as RelativePeriodType
union
select 3 as RelativePeriodID, 'Prior year' as RelativePeriodType
union
select 4 as RelativePeriodID, 'YTD last year' as RelativePeriodType
union
select 5 as RelativePeriodID, 'Prior period' as RelativePeriodType
union
select 6 as RelativePeriodID, 'Last 12 periods' as RelativePeriodType
union
select 7 as RelativePeriodID, 'Full Fiscal Year' as RelativePeriodType
union
select 8 as RelativePeriodID, 'Same period last year' as RelativePeriodType
union
select 9 as RelativePeriodID, 'Life to Date' as RelativePeriodType





