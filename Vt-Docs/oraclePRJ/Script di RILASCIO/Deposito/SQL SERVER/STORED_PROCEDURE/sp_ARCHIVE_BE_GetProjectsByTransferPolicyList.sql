USE [PCM_DEPOSITO_1]
GO
/****** Object:  UserDefinedFunction [DOCSADM].[fn_ARCHIVE_GetProjectsByTransferPolicyList]    Script Date: 05/02/2013 12:18:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================
-- Author:		Giovanni Olivari
-- Create date: 29/04/2013
-- Description:	Restituisce la lista dei fascicoli aggregati
-- =========================================================
ALTER PROCEDURE [DOCSADM].[sp_ARCHIVE_BE_GetProjectsByTransferPolicyList]
(	
	@transferPolicyList VARCHAR(1000)
)
AS
BEGIN

	DECLARE @sql_string nvarchar(MAX)
	DECLARE @countDistinct int = 0



	-- Create temp table
	--
	IF OBJECT_ID('tempdb..#transferPolicyListTable') IS NOT NULL DROP TABLE #transferPolicyListTable
	CREATE TABLE #transferPolicyListTable
	(
		ID int
	)

	SET @sql_string = CAST(N'
		INSERT INTO #transferPolicyListTable (ID)
		SELECT SYSTEM_ID FROM ARCHIVE_TransferPolicy
		WHERE SYSTEM_ID IN (' AS NVARCHAR(MAX)) + CAST(@transferPolicyList AS NVARCHAR(MAX)) + CAST(N')' AS NVARCHAR(MAX))
		
	PRINT @sql_string;

	EXECUTE sp_executesql @sql_string;



	-- Conteggio DISTINCT dei fascicoli da trasferire
	--
	SELECT @countDistinct = COUNT(DISTINCT Project_ID) 
	FROM ARCHIVE_TEMPPROJECT F 
	WHERE F.TRANSFERPOLICY_ID IN (SELECT ID FROM #transferPolicyListTable)
	AND F.DATRASFERIRE = 1

	PRINT @countDistinct



	--SET @sql_string = CAST(N'
	--	SELECT F.REGISTRO, F.TITOLARIO, F.CLASSETITOLARIO, F.TIPOLOGIA, YEAR(F.DATACHIUSURA) ''ANNO_CHIUSURA''
	--	, COUNT(*) TOTALE, ' AS NVARCHAR(MAX)) + CAST(@countDistinct AS NVARCHAR(MAX)) + CAST(' COUNTDISTINCT
	--	FROM ARCHIVE_TEMPPROJECT F
	--	WHERE F.DATRASFERIRE = 1
	--	AND F.TRANSFERPOLICY_ID IN (' AS NVARCHAR(MAX)) + CAST(@transferPolicyList AS NVARCHAR(MAX)) + CAST(')
	--	GROUP BY F.REGISTRO, F.TITOLARIO, F.CLASSETITOLARIO, F.TIPOLOGIA, YEAR(F.DATACHIUSURA)'AS NVARCHAR(MAX))

	SET @sql_string = CAST(N'
		SELECT REGISTRO, TITOLARIO, CLASSETITOLARIO, TIPOLOGIA, ANNO_CHIUSURA
		, COUNT(*) TOTALE, ' AS NVARCHAR(MAX)) + CAST(@countDistinct AS NVARCHAR(MAX)) + CAST(' COUNTDISTINCT
		FROM
		(
			SELECT DISTINCT F.PROJECT_ID, F.REGISTRO, F.TITOLARIO, F.CLASSETITOLARIO, F.TIPOLOGIA, YEAR(F.DATACHIUSURA) ''ANNO_CHIUSURA''
			FROM ARCHIVE_TEMPPROJECT F
			WHERE F.DATRASFERIRE = 1
			AND F.TRANSFERPOLICY_ID IN (' AS NVARCHAR(MAX)) + CAST(@transferPolicyList AS NVARCHAR(MAX)) + CAST(')
		) T1
		GROUP BY REGISTRO, TITOLARIO, CLASSETITOLARIO, TIPOLOGIA, ANNO_CHIUSURA'AS NVARCHAR(MAX))


	EXECUTE sp_executesql @sql_string;

END