USE [Plex_Facts]
GO
/****** Object:  StoredProcedure [dbo].[DataRefresh_InvAdj]    Script Date: 7/12/2022 12:13:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:  Tim Farmer
-- Create date: 16 June 2022
-- Description: Retrieve data older than the date given
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].DataRefresh_InvAdj
  -- Add the parameters for the stored procedure here
  --@RangeEnd DATETIME = NULL
  AS BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET Nocount ON;

TRUNCATE TABLE [Dbo].[GL_Inventory_Adjustments_f]

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

SET @max = (SELECT MAX(Id) FROM Plex_Facts.Dbo.GL_Inventory_Adjustments_f AS GLA)
IF @max IS NULL
BEGIN
  SET @max = 1000
  Dbcc Checkident ('Plex_Facts.Dbo.GL_Inventory_Adjustments_f', Reseed, @max)
END

SET @MinDate = (SELECT Top 1 Period AS Lastupdated FROM Plex_Facts.Dbo.GL_Inventory_Adjustments_f AS GLA ORDER BY GLA.Table_Updated_Date DESC)
--SELECT @MinDate

SET @linkedserver = N'PLEX_VIEWS'
SET @openquery = N'SELECT * FROM OPENQUERY(' + @linkedserver + ','''
SET @sql_Select = N'SELECT
  Table_Updated_Date = GETDATE()
  , GLD.Plexus_Customer_No
  , CGM.Plexus_Customer_Code
  , GLD.Account_No
  , GLD.Description
  , Artificial_Date = CAST(LEFT(GLJ.Period, 4) + ''''-'''' + RIGHT(GLJ.Period, 2) + ''''-'''' + ''''01'''' AS DATE)  
  , GLJ.Period
  , Debit = SUM(GLD.Debit)
  , Credit = SUM(GLD.Credit)
  , Net_Abs = ROUND(ABS(SUM(GLD.Credit) - SUM(GLD.Debit)), 0) '
SET @sql_From = N'     FROM Accounting_v_GL_Journal_Dist_e AS GLD
LEFT JOIN Accounting_v_GL_Journal_e AS GLJ
  ON GLJ.Plexus_Customer_No = GLD.Plexus_Customer_No
    AND GLJ.Journal_Link = GLD.Journal_Link 
LEFT JOIN Plexus_Control_V_Customer_Group_Member AS CGM
  ON CGM.Plexus_Customer_No = GLD.Plexus_Customer_No'
--SET @sql_Where = N'   WHERE Table_Updated_Date > GETDATE() AND GLD.Account_No LIKE ''''%500130'''' '   
SET @sql_Where = N'   WHERE GLD.Account_No LIKE ''''%500130'''' '   
SET @sql_Group_By = N' GROUP BY
  GLD.Plexus_Customer_No
  , CGM.Plexus_Customer_Code
  , GLD.Account_No
  , GLD.Description
  ,GLJ.Period '
SET @sql_Order_By = N'  ORDER BY
  CGM.Plexus_Customer_Code
  , GLJ.Period DESC'')'

INSERT INTO Plex_Facts.Dbo.GL_Inventory_Adjustments_f
EXEC(@openquery + @sql_Select + @sql_From + @sql_Where + @sql_Group_By + @sql_Order_By)

--SELECT (@openquery + @sql_Select + @sql_From + @sql_Where + @sql_Group_By + @sql_Order_By)
END
