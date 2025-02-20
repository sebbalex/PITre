USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Update_Disposal]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Update_Disposal]  ( @Description varchar (200) , @Description_Original varchar (200) , @Note varchar (2000) , @Note_Original varchar (2000) , @ID_Amministrazione int,@ID_Amministrazione_Original int,@System_ID int, @RowsAffected int out  )
AS
BEGIN
UPDATE [DOCSADM].[ARCHIVE_Disposal]
SET  [Description] = @Description,
[Note] = @Note ,
[ID_Amministrazione] = @ID_Amministrazione 
WHERE
   (
    (([Description] IS NOT NULL AND @Description_Original IS NOT NULL AND [Description] = @Description_Original) OR ([Description] IS NULL AND @Description_Original IS NULL)) AND
    (([Note] IS NOT NULL AND @Note_Original IS NOT NULL AND [Note] = @Note_Original) OR ([Note] IS NULL AND @Note_Original IS NULL)) AND
      (([ID_Amministrazione] IS NOT NULL AND @ID_Amministrazione_Original IS NOT NULL AND [ID_Amministrazione] = @ID_Amministrazione_Original) OR ([ID_Amministrazione] IS NULL AND @ID_Amministrazione_Original IS NULL)) AND
    ( [System_ID] = @System_ID )
   )
set @RowsAffected =@@ROWCOUNT
END
GO
