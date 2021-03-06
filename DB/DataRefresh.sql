USE [Plex_Accelerated]
GO
/****** Object:  StoredProcedure [dbo].[DataRefresh]    Script Date: 7/12/2022 12:13:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  Tim Farmer
-- Create date: 16 June 2022
-- Description: Retrieve data older than the date given
-- =============================================
ALTER PROCEDURE [dbo].[DataRefresh]
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

SET @max = (SELECT MAX(Id) FROM Plex_Accelerated.Dbo.Stored_Procedure_Information_F AS S)
IF @max IS NULL
BEGIN
  SET @max = 1000
  Dbcc Checkident ('Plex_Accelerated.Dbo.Stored_Procedure_Information_F', Reseed, @max)
END

SET @MinDate = (SELECT Top 1 CONVERT(CHAR(10), S.Table_Updated_Date, 112) AS Lastupdated FROM Plex_Accelerated.Dbo.Stored_Procedure_Information_F AS S ORDER BY S.Table_Updated_Date DESC)
--SELECT @MinDate

SET @linkedserver = N'PLEX_VIEWS'
SET @openquery = N'SELECT * FROM OPENQUERY(' + @linkedserver + ','''
SET @sql_Select = N'
                        SELECT
                          Table_Updated_Date = GETDATE()
                          , S.Pcn
                          , Cgm.Plexus_Customer_Code
                          , S.Created_Date
                          , S.Author_Pun
                          , Author_Last = Pua.Last_Name
                          , Author_First = Pua.First_Name
                          , S.Last_Altered
                          , S.Last_Altered_Pun
                          , Editor_Last = Pum.Last_Name
                          , Editor_First = Pum.First_Name
                          , S.Stored_Procedure_Name
                          , S.Specific_Name
                          , S.Stored_Procedure_Key
                          , S.Note
                          , S.Stored_Procedure_Text'
SET @sql_From = N'
                      FROM Accelerated_Stored_Procedure_Information_E AS S
                        LEFT JOIN Plexus_Control_V_Customer_Group_Member AS Cgm
                        ON Cgm.Plexus_Customer_No = S.Pcn
						AND Last_Altered >= GETDATE()
                        LEFT JOIN Plexus_Control_V_Plexus_User_E AS Pua
                        ON Pua.Plexus_Customer_No = S.Pcn
                          AND Pua.Plexus_User_No = S.Author_Pun
                        LEFT JOIN Plexus_Control_V_Plexus_User_E AS Pum
                        ON Pum.Plexus_Customer_No = S.Pcn
                          AND Pum.Plexus_User_No = S.Last_Altered_Pun '
SET @sql_Where = N'WHERE S.Last_Altered BETWEEN ' + @MinDate + N' AND ' + @MaxDate
SET @sql_Order_By = N'ORDER BY Last_Altered DESC'')'
SET @sql_Where = N'WHERE FORMAT(S.Last_Altered, ''''yyyyMMdd'''') BETWEEN ''''' + (SELECT CONVERT(CHAR(8), @MinDate, 112)) + ''''' AND ''''' + (SELECT CONVERT(CHAR(8), @MaxDate, 112)) + ''''' '

INSERT INTO Plex_Accelerated.Dbo.Stored_Procedure_Information_F
EXEC(@openquery + @sql_Select + @sql_From + @sql_Where + @sql_Order_By)

--SELECT (@openquery + @sql_Select + @sql_From + @sql_Where + @sql_Order_By)
END
