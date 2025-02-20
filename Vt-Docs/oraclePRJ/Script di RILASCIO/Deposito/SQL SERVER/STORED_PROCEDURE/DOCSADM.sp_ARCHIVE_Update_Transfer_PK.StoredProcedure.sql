USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Update_Transfer_PK]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Update_Transfer_PK]  ( @Description varchar (200) , @Note varchar (2000) , @System_ID int, @ID_Amministrazione int, @RowsAffected int out )
AS
BEGIN
UPDATE [DOCSADM].[ARCHIVE_Transfer]
SET  [Description] = @Description,
[Note] = @Note ,
[ID_Amministrazione] = @ID_Amministrazione 
WHERE ( [System_ID] = @System_ID )
set @RowsAffected = @@ROWCOUNT
END
GO
