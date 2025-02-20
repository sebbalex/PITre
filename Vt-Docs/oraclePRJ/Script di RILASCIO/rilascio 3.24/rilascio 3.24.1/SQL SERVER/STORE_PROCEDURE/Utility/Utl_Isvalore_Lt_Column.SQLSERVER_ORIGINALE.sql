

ALTER FUNCTION [DOCSADM].[Utl_Isvalore_Lt_Column]
(
	@Valore		VARCHAR(1000)
	,@Mytable	VARCHAR(100)
	,@mycol		VARCHAR(100) 
)

RETURNS INT -- returns 0 if lentgh(valore) less then  Data_Length of the column mycol
AS
BEGIN 
	DECLARE @Cnt			INT
	DECLARE @returnvalue	INT 

	SET @returnvalue = -1

	SELECT @cnt = CASE DATA_TYPE WHEN 'varchar' then CHARACTER_MAXIMUM_LENGTH else NUMERIC_PRECISION end - Len('A') 
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE Table_Name=upper(@Mytable) AND Column_Name = upper(@Mycol) 
		
	IF @Cnt>=0 
	BEGIN 	
		SET @returnvalue = 0  
	END

	RETURN @Returnvalue 
END 
