USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Delete_Disposal_PK]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Delete_Disposal_PK]  ( @System_ID int, @RowsAffected int out  )
AS
BEGIN
DELETE [DOCSADM].[ARCHIVE_Disposal]
WHERE ( [System_ID] = @System_ID )
set @RowsAffected= @@ROWCOUNT
END
GO
