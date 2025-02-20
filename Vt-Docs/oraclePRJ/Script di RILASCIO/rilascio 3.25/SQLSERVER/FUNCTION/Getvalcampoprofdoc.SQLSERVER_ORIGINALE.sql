
ALTER FUNCTION [DOCSADM].[getValCampoProfDoc](@DocNumber INT, @CustomObjectId INT)
RETURNS VARCHAR(400) AS 
BEGIN

/*
Si distinguono cinque casi:
1. @tipoOggetto = 'Corrispondente'
2. @tipoOggetto = 'CasellaDiSelezione'
3. @tipoOggetto = 'Contatore' 
4. @tipoOggetto = 'Contatore'
            con campo dpa_oggetti_custom.repertorio = 1
            e campo dpa_associazione_templatesid_oggetto not null 
5. nessuno dei precedenti          
*/

declare @result         VARCHAR(255)
declare @tipoOggetto varchar(255)
declare @tipoCont varchar(1)
declare @repert         numeric
declare @tipologiaDoc numeric

select top 1 @tipoOggetto = b.descrizione
      , @tipoCont = cha_tipo_Tar
      , @repert = a.repertorio
from  dpa_oggetti_custom a, dpa_tipo_oggetto b 
where  a.system_id = @CustomObjectId
and a.id_tipo_oggetto = b.system_id

if (@tipoOggetto = 'Corrispondente') 
BEGIN
      select @result  = cg.var_cod_rubrica + ' - ' + cg.var_DESC_CORR 
      from dpa_CORR_globali cg
            where cg.SYSTEM_ID = (
                  select valore_oggetto_db from dpa_associazione_templates 
                  where id_oggetto = @CustomObjectId and doc_number = @DocNumber)
return      @result  
end -- end if(@tipoOggetto = 'Corrispondente') 
    
--Casella di selezione (Per la casella di selezione serve un caso particolare perche i valori sono multipli)
if(@tipoOggetto = 'CasellaDiSelezione')     
BEGIN
       declare @item varchar(1000)
       declare curCasellaDiSelezione CURSOR LOCAL FOR 
                  select  
                  valore_oggetto_db from dpa_associazione_templates 
                        where id_oggetto = @CustomObjectId 
                             and doc_number = @DocNumber
                             and valore_oggetto_db != ''

       OPEN curCasellaDiSelezione
       FETCH NEXT FROM curCasellaDiSelezione INTO @item
       set @result = ''
       WHILE (@@FETCH_STATUS = 0) -- EXIT WHEN curCasellaDiSelezione%NOTFOUND;
       BEGIN
                IF(@result!='' and @result is not null)              
                             SET @result = @result + '; ' + @item 
                ELSE 
                              SET @result = @result + @item           
            FETCH NEXT FROM curCasellaDiSelezione INTO @item
        END
        CLOSE curCasellaDiSelezione
RETURN @result
end -- end if(@tipoOggetto = 'CasellaDiSelezione')  

IF (@tipoOggetto = 'Contatore' )
begin

-- restituisce 1 se il documento DocNumber  associato alla tipologia di documento 
--    contenente il contatore di repertorio con id = CustomObjectId
SELECT @tipologiaDoc = case when id_oggetto is not null then 1 else 0 end 
from dpa_associazione_templates
where doc_number=@DocNumber and id_oggetto=@CustomObjectId


                  IF @repert = 1 And @tipologiaDoc = 1
                  BEGIN
                  RETURN '#CONTATORE_DI_REPERTORIO#'
                  end elsE BEGIN 
                        select @result = docsadm.getContatoreDoc(@DocNumber,@tipoCont)  
                        from dpa_associazione_templates 
                        where id_oggetto = @CustomObjectId and doc_number = @DocNumber

                  RETURN @result
                  end
end -- end IF (@tipoOggetto = 'Contatore' )


--Tutti gli altri casi
select @result = valore_oggetto_db
from dpa_associazione_templates
where id_oggetto = @CustomObjectId and doc_number = @DocNumber
RETURN @result

End
