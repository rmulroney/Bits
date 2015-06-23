/*


data: [ {
          AccountName: "SciFi",
          movies: [
            { title: "Star Wars: A New Hope", year: 1977 },
            { title: "Star Wars: The Empire Strikes Back", year: 1980 },
            { title: "Star Wars: Return of the Jedi", year: 1983 }
          ]
      }, {
          AccountName: "Drama",
          movies: [
            { title: "The Shawshenk Redemption", year: 1994 },
            { title: "Fight Club", year: 1999 },
            { title: "The Usual Suspects", year: 1995 }
          ]
      }
    ]


data: [ {
          Level0: "Assets",
          Level1: [
            { AccountName: "Fixed Assets", AccountNumber: "1-1000" },
            { AccountName: "Trade Creditors", AccountNumber: "1-2000" },
            { AccountName: "Cash at Bank", AccountNumber: "1-3000" },
          ]
      }, {
          AccountName: "Liabilites",
          movies: [
            { AccountName: "Bank Loan", AccountNumber: "2-1000" },
            { AccountName: "Debtors", AccountNumber: "2-2000" },
            { AccountName: "Non-Current", AccountNumber: "2-3000" },
          ]
      }
    ]


	*/




;WITH cte AS (
    SELECT 0 AS lvl, AccountID, AccountName, AccountParentID, CAST(AccountID AS VARCHAR(128)) AS Sort		
    FROM dbo.vwHierAccount WHERE AccountParentID  IS NULL
	UNION ALL
    SELECT p.lvl + 1, c.AccountID, c.AccountName, c.AccountParentID, CAST(p.Sort + '/' + CAST(c.AccountID AS VARCHAR) AS VARCHAR(128))
    FROM dbo.vwHierAccount c
    INNER JOIN cte p ON p.AccountID = c.AccountParentID
)
SELECT 
    AccountID, 
    SPACE(lvl * 4) + AccountName AS sAccountName, 
	AccountName,
    Sort,
    AccountParentID , 
	lvl,	
	lag(lvl, 1,0) OVER (ORDER BY sort) as prevLv,
	lead(lvl, 1,0) OVER (ORDER BY sort) as nextLv,
	
	SPACE(lvl * 4) + 
	case when lvl = 0 then 'Level0: "' + accountname + '", '		
		 else 
		 Case when lag(lvl, 1,0) OVER (ORDER BY sort) < lvl  then 'Level' + convert(varchar(3), lvl) + ': [' 
			  when lag(lvl, 1,0) OVER (ORDER BY sort) > lvl  then ']},' 
			  else '' end  +
			'{ AccountName: "' + AccountName +'", Nodeid: ' + convert(varchar(6), AccountID) + 
			case when lead(lvl, 1,0) OVER (ORDER BY sort) > lvl  then '' else '}' end 
	end


FROM cte
ORDER BY Sort


