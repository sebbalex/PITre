
ALTER procedure [DOCSADM].[dpa_setNumFasc] 

   @num_rec int,
   @messaggio  nvarchar
   
   AS
/*
questa procedura azzera il numero dei fasc, sotto i nodi di titolario elencati nell dpa_reg_fasc che hanno
il campo cha_automatico='1'. questo campo si rende necessario per gestire eventuali numerazioni  fasc sotto nodi
che non devono essere re.inizializzate ad inizio anno. per compatiilit� con gli altri clienti il valore di default del cmap o� '0'. a cura del PM p
porlo a '1' sotto i nodi interessati dall'azzeramento.
*/


/*
questa procedura è stata modificata: RESETTA a 1 il progressivo dei procedimentali
, in più filtrando per il o i soli titolari non chiusi
*/

begin
begin try
-- modifica Stefano
--vecchia procedura
--update DOCSADM.dpa_reg_fasc set num_rif=1 where cha_automatico='1' and convert(varchar,getdate(),3)='01/01';--to_char(getdate,'dd/mm')='01/01'

;with gerarchia as
(
select prActual.system_id
from PROJECT prActual
where prActual.ID_TITOLARIO=0  
AND prActual.cha_stato != 'C'
union all
select prActual.system_id
from PROJECT prActual inner join gerarchia g on prActual.ID_PARENT = g.system_id
where prActual.cha_tipo_proj = 'T' 
--where prParent.cha_tipo_proj = 'T'  
--AND prParent.cha_stato != 'C'
)
	--select SYSTEM_ID from gerarchia
	update DOCSADM.dpa_reg_fasc 
	set num_rif=1 
	where convert(varchar,getdate(),3)='01/01'
	and NUM_RIF>1
	and ID_TITOLARIO in (select SYSTEM_ID from gerarchia)	

	set @num_rec = @@ROWCOUNT
	--set @messaggio = 		

	--INSERT INTO temp_log_jobs    --Manca la tabella temp_log_jobs
	--		VALUES ('aggiornati '+ @num_rec +' record in tabella dpa_reg_fasc ', GETDATE());					
			
	--commit transaction
		
END TRY
BEGIN CATCH		
	
	SELECT @messaggio = ERROR_MESSAGE();
	raiserror(50001,0,0,@messaggio) -- parametri: id messaggio definito dall'utente ,
									-- severity definito dall'utente, State sempre arbitrario e 
									-- il messaggio dell'errore
	--rollback
	--INSERT INTO temp_log_jobs
          -- VALUES (   'Errore: ' +@messaggio+ ' in aggiornamento tabella dpa_reg_fasc ',
         --          GETDATE());
    --COMMIT                   
	
end catch                        


--commit transaction
--exception --when others then null;
end
