

CREATE proc [dbo].[spCreateDimDate] (
@startDate date = '2004-01-01'
,@days int = 6000
,@fiscalYearMonthOffset int = 6
)as 

begin

	IF OBJECT_ID('dbo.Tally') IS NULL print 'This proc requires a tally table'
	IF OBJECT_ID('dbo.DimDate') IS NULL 
	begin

	CREATE TABLE [dbo].[DimDate](
		[dateId] [int] NOT NULL,
		[dateDesc] [varchar](11) NOT NULL,
		[year] [int] NOT NULL,
		[yearMonth] [int] NOT NULL,
		[yearMonthDesc] [varchar](8) NOT NULL,
		[yearQuarter] [int] NOT NULL,
		[yearQuarterDesc] [varchar](7) NOT NULL,
		[fiscalYear] [int] NOT NULL,
		[fiscalYearDesc] [varchar](10) NOT NULL,
		[fiscalYearQuarter] [varchar](13) NOT NULL,
		[monthOfYear] [int] NOT NULL,
		[monthOfYearDesc] [varchar](9) NOT NULL,
		[dayOfMonth] [int] NOT NULL,
		[dayOfWeek] [int] NOT NULL,
		[dayOfWeekDesc] [varchar](9) NOT NULL,
		[dayOfWeekType] [varchar](7) NOT NULL,
		[weekOfYear] [int] NOT NULL,
		[yearWeek] [int] NOT NULL,
		[yearWeekDesc] [varchar](10) NOT NULL,
		[serialDate] [int] NOT NULL,
		[date] [date] NOT NULL,
	CONSTRAINT [PK_DimDate] PRIMARY KEY CLUSTERED 
		(
			[dateId] ASC
		) ON [PRIMARY]
	) ON [PRIMARY]

	end

merge DimDate as target using
(
	select 
		 datepart(year,dateadd(d,N,@startDate))*10000+datepart(month,dateadd(d,N,@startDate))*100+datepart(day,dateadd(d,N,@startDate)) as dateId
		,datename(day,dateadd(d,N,@startDate)) + ' ' + left(datename(month,dateadd(d,N,@startDate)),3) + ' ' + datename(year,dateadd(d,N,@startDate)) as dateDesc
		,datepart(year,dateadd(d,N,@startDate)) as year
		,datepart(year,dateadd(d,N,@startDate))*100+datepart(month,dateadd(d,N,@startDate)) as yearMonth
		,left(datename(month,dateadd(d,N,@startDate)),3) + ' ' + datename(year,dateadd(d,N,@startDate)) as yearMonthDesc
		,datepart(year,dateadd(d,N,@startDate)) * 100 + datepart(quarter,dateadd(d,N,@startDate)) as yearQuarter
		,datename(year,dateadd(d,N,@startDate)) + ' Q' + datename(quarter,dateadd(d,N,@startDate)) as yearQuarterDesc
		,datepart(year,dateadd(m,-@fiscalYearMonthOffset,dateadd(d,N,@startDate)))*100 + right(datename(year,dateadd(m,12-@fiscalYearMonthOffset,dateadd(d,N,@startDate))),2) as fiscalYear
		,'FY ' + datename(year,dateadd(m,-@fiscalYearMonthOffset,dateadd(d,N,@startDate))) + '/' + right(datename(year,dateadd(m,12-@fiscalYearMonthOffset,dateadd(d,N,@startDate))),2) as fiscalYearDesc
		,'FY ' + datename(year,dateadd(m,-@fiscalYearMonthOffset,dateadd(d,N,@startDate))) + '/' + right(datename(year,dateadd(m,12-@fiscalYearMonthOffset,dateadd(d,N,@startDate))),2) + ' Q' + datename(quarter,dateadd(m,12-@fiscalYearMonthOffset,dateadd(d,N,@startDate)))  as fiscalYearQuarter
		,datepart(month,dateadd(d,N,@startDate)) as monthOfYear
		,datename(month,dateadd(d,N,@startDate)) as monthOfYearDesc
		,datepart(day,dateadd(d,N,@startDate)) as dayOfMonth
		,datepart(weekday,dateadd(d,N,@startDate)) as dayOfWeek
		,datename(weekday,dateadd(d,N,@startDate)) as dayOfWeekDesc
		,case when datepart(weekday,dateadd(d,N,@startDate)) in (1,7) then 'Weekend' else 'Weekday' end as dayOfWeekType
		,datename(week,dateadd(d,N,@startDate)) as weekOfYear
		,datepart(year,dateadd(d,N,@startDate)) *100 + datepart(week,dateadd(d,N,@startDate)) as yearWeek
		,datename(year,dateadd(d,N,@startDate))  + ' Wk ' + datename(week,dateadd(d,N,@startDate)) as yearWeekDesc
		,datediff(d,'1900-01-01',dateadd(d,N,@startDate)) + 2 as serialDate
		,dateadd(d,N,@startDate) as date
	from 
		dbo.Tally 
	where
		N < @days
) as source 

on source.dateId = target.dateId

when not matched then 

insert
(
	 [dateId]
	,[dateDesc]
	,[year]
	,[yearMonth]
	,[yearMonthDesc]
	,[yearQuarter]
	,[yearQuarterDesc]
	,[fiscalYear]
	,[fiscalYearDesc]
	,[fiscalYearQuarter]
	,[monthOfYear]
	,[monthOfYearDesc]
	,[dayOfMonth]
	,[dayOfWeek]
	,[dayOfWeekDesc]
	,[dayOfWeekType]
	,[weekOfYear]
	,[yearWeek]
	,[yearWeekDesc]
	,[serialDate]
	,[date]
)
values
(
	 source.[dateId]
	,source.[dateDesc]
	,source.[year]
	,source.[yearMonth]
	,source.[yearMonthDesc]
	,source.[yearQuarter]
	,source.[yearQuarterDesc]
	,source.[fiscalYear]
	,source.[fiscalYearDesc]
	,source.[fiscalYearQuarter]
	,source.[monthOfYear]
	,source.[monthOfYearDesc]
	,source.[dayOfMonth]
	,source.[dayOfWeek]
	,source.[dayOfWeekDesc]
	,source.[dayOfWeekType]
	,source.[weekOfYear]
	,source.[yearWeek]
	,source.[yearWeekDesc]
	,source.[serialDate]
	,source.[date]
);

end



