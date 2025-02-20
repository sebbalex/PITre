SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

 
GO


CREATE PROCEDURE [@db_user].[ADD_REGISTRO_IN_DPA_REG_FASC]
@newIdRegistro INT,
@id_amm INT,
@result INT OUT

AS

declare @syscurrTit int

BEGIN

DECLARE currTit CURSOR FOR
SELECT system_id
FROM project
WHERE ID_AMM = @id_amm
AND CHA_TIPO_PROJ= 'T' AND ID_REGISTRO IS NULL

begin
-- SE IL NODO HA REGISTRO NULL ALLORA DEVONO ESSERE CREATI TANTI RECORD NELLA
-- DPA_REG_FASC QUANTI SONO I REGISTRI INTERNI ALL'AMMINISTRAZIONE
SET @result=0


OPEN currTit
FETCH NEXT FROM currTit
INTO @syscurrTit

WHILE @@FETCH_STATUS = 0

BEGIN
INSERT INTO DPA_REG_FASC
(

id_Titolario,
num_rif,
id_registro
)
VALUES
(

@syscurrTit,
1,
@newIdRegistro
)

IF (@@ROWCOUNT = 0)
BEGIN
SET @result=1
RETURN
END

FETCH NEXT FROM currTit  INTO  @syscurrTit
END



CLOSE currTit
DEALLOCATE currTit
END
END

GO


SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

