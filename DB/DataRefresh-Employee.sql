-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters
-- command (Ctrl-Shift-M) to fill in the parameter
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET Ansi_Nulls ON
GO
SET Quoted_Identifier ON
GO
-- =============================================
-- Author:  Tim Farmer
-- Create date: 16 June 2022
-- Description: Retrieve data older than the date given
-- =============================================
CREATE OR ALTER PROCEDURE Datarefresh-Employee
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

SET @max =
(
  SELECT
    MAX(Id)
  FROM Plex_Personnel.dbo.Employee_v_e_f AS S
)
IF @max IS NULL
BEGIN
  SET @max = 1000
  Dbcc Checkident ('Plex_Personnel.dbo.Employee_v_e_f', Reseed, @max)
END

SET @lastupdate =
(
  SELECT
    Top 1 S.Table_Updated_Date AS Lastupdated
  FROM Plex_Personnel.dbo.Employee_v_e_f AS S
  ORDER BY
    S.Table_Updated_Date DESC
)
--SELECT @lastupdate

SET @rangestart =
(
  SELECT
    Top 1 S.Last_Altered AS Rangestart
  FROM Plex_Personnel.dbo.Employee_v_e_f AS S
  ORDER BY
    S.Last_Altered DESC
)
--SELECT @rangestart

SET @rangeend =
(
  SELECT
    GETDATE() AS Rangeend
)
--SELECT @rangeend

SET @linkedserver = N'PLEX_VIEWS'
SET @openquery = N'SELECT * FROM OPENQUERY(' + @linkedserver + ','''
SET @sql_Select = N'
                        SELECT
                          Table_Updated_Date = GETDATE()
                          , E.Plexus_Customer_No
                          , Cgm.Plexus_Customer_Code
                          , Last_Name = Pua.Last_Name
                          , First_Name = Pua.First_Name
						  , E.* '

SET @sql_From = N'
                      FROM Personnel_V_Employee_E AS E
                        LEFT JOIN Plexus_Control_V_Customer_Group_Member AS Cgm
                        ON Cgm.Plexus_Customer_No = S.Pcn
                        LEFT JOIN Plexus_Control_V_Plexus_User_E AS Pua
                        ON Pua.Plexus_Customer_No = S.Pcn
                          AND Pua.Plexus_User_No = S.Author_Pun
                        LEFT JOIN Plexus_Control_V_Plexus_User_E AS Pum
                        ON Pum.Plexus_Customer_No = S.Pcn
                          AND Pum.Plexus_User_No = S.Last_Altered_Pun '
--SET @sql_Where = N'WHERE S.Last_Altered >= CURRENT_TIMESTAMP '
--SET @sql_Order_By = N'ORDER BY Last_Altered DESC'')'
--
IF @rangestart > @lastupdate
BEGIN
  INSERT INTO Plex_Accelerated.Dbo.Stored_Procedure_Information_F
  EXEC(@openquery + @sql_Select + @sql_From) -- + @sql_Where + @sql_Order_By)
END

END
GO

EXECUTE Datarefresh-Employee;
GO
/*
DECLARE @rangestart Datetime2, @rangeend Datetime2
SELECT @rangestart, @rangeend

USE Plex_Accelerated;
SELECT
Table_Updated_Date
FROM [Plex_Accelerated].[dbo].[Stored_Procedure_Information_f] AS S
ORDER BY
Table_Updated_Date DESC
;

GO
*/
