USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_LOG_Select_TransferANDPolicy]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_LOG_Select_TransferANDPolicy] 
(	
	@transferPolicyList VARCHAR(1000)
)
AS
BEGIN

	DECLARE @sql_string nvarchar(MAX)

	SET @sql_string = CAST(N'
		SELECT 
		[System_ID],
		[Timestamp], 
		[Action], 
		[ActionType], 
		[ActionObject], 
		[ObjectType], 
		[ObjectID]
		FROM [ARCHIVE_Log] 
		WHERE ObjectID IN (' AS NVARCHAR(MAX)) + CAST(@transferPolicyList AS NVARCHAR(MAX)) + CAST(')
		order by ObjectId desc 'AS NVARCHAR(MAX))
  
	print @sql_string
	
	EXECUTE sp_executesql @sql_string;

END
GO
