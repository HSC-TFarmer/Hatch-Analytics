USE [Plex_Accelerated]
GO
/****** Object:  StoredProcedure [dbo].[DataRefresh_GLA]    Script Date: 7/12/2022 12:13:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  Tim Farmer
-- Create date: 16 June 2022
-- Description: Retrieve data older than the date given
-- =============================================
ALTER PROCEDURE [dbo].[DataRefresh_GLA]
  -- Add the parameters for the stored procedure here
  --@RangeEnd DATETIME = NULL
  AS BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET Nocount ON;

DECLARE @lastupdate Datetime2
  , @rangestart Datetime2
  , @rangeend Datetime2
  , @linkedserver VARCHAR(MAX)
  , @openquery    VARCHAR(MAX)
  , @sql_Select   VARCHAR(MAX)
  , @sql_From     VARCHAR(MAX)
  , @sql_Where    VARCHAR(MAX)
  , @sql_Group_By VARCHAR(MAX)
  , @sql_Order_By VARCHAR(MAX)
  , @max          INT
  , @MinDate VARCHAR(MAX) = ''
  , @MaxDate VARCHAR(MAX) = (SELECT CONVERT(CHAR(8), GETDATE(), 112))

SET @max = (SELECT MAX(Id) FROM Plex_Accelerated.Dbo.GL_Account_Activity_Detail_v_e_f AS GLA)
IF @max IS NULL
BEGIN
  SET @max = 1000
  Dbcc Checkident ('Plex_Accelerated.Dbo.GL_Account_Activity_Detail_v_e_f', Reseed, @max)
END

SET @MinDate = (SELECT Top 1 CONVERT(CHAR(10), GLA.Date, 112) AS Lastupdated FROM Plex_Accelerated.Dbo.GL_Account_Activity_Detail_v_e_f AS GLA ORDER BY GLA.Table_Updated_Date DESC)
--SELECT @MinDate

SET @linkedserver = N'PLEX_VIEWS'
SET @openquery = N'SELECT * FROM OPENQUERY(' + @linkedserver + ','''
SET @sql_Select = N'SELECT
						  Table_Updated_Date = GETDATE()
						  , GLA.Plexus_Customer_No
						  , GLA.Plexus_Customer_Code
						  , GLA.[Type]
						  , GLA.Period
						  , GLA.Date
						  , GLA.Number
						  , GLA.Account_No
						  , GLA.Description
						  , GLA.Debit
						  , GLA.Credit
						  , GLA.Currency_Code
						  , GLA.Voucher_No '
SET @sql_From = N'      FROM Accelerated_GL_Account_Activity_Detail_v_e AS GLA '
SET @sql_Where = N'     WHERE YEAR(GLA.Date) >= YEAR(GETDATE()) - 2  
--BETWEEN ' + @MinDate + N' AND ' + @MaxDate
--SET @sql_Where = N'     WHERE FORMAT(GLA.Date, ''''yyyyMMdd'''') >= '''' YEAR(' + (SELECT CONVERT(CHAR(8), @MinDate, 112)) + ') - 2' -- + ''''' AND ''''' + (SELECT CONVERT(CHAR(8), @MaxDate, 112)) + ''''' '
SET @sql_Order_By = N'  ORDER BY GLA.Date DESC'')'

INSERT INTO Plex_Accelerated.Dbo.GL_Account_Activity_Detail_v_e_f
EXEC(@openquery + @sql_Select + @sql_From + @sql_Where + @sql_Order_By)

--SELECT (@openquery + @sql_Select + @sql_From + @sql_Where + @sql_Order_By)
END
