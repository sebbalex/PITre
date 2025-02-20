
/****** Object:  StoredProcedure [DOCSADM].[sp_modify_corr_esterno_IS]    Script Date: 03/04/2013 17:08:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [DOCSADM].[sp_modify_corr_esterno_IS] 
/*
versione della SP ad hoc per "Interoperabilit semplificata", by S. Furnari:
oltre a introdurre e gestire il nuovo parametro SimpInteropUrl , 
recepisce le modifiche introdotte in questa stessa versione 3.21 by C. Ferlito 
per gestire il nuovo campo var_desc_corr_old
*/
@idcorrglobale     INT				,
@desc_corr         VARCHAR(4000)    ,
@nome              VARCHAR(4000)    ,
@cognome           VARCHAR(4000)    ,
@codice_aoo        VARCHAR(4000)    ,
@codice_amm        VARCHAR(4000)    ,
@email             VARCHAR(4000)    ,
@indirizzo         VARCHAR(4000)    ,
@cap               VARCHAR(4000)    ,
@provincia         VARCHAR(4000)    ,
@nazione           VARCHAR(4000)    ,
@citta             VARCHAR(4000)    ,
@cod_fiscale       VARCHAR(4000)    ,
@telefono          VARCHAR(4000)    ,
@telefono2         VARCHAR(4000)    ,
@note              VARCHAR(4000)    ,
@fax               VARCHAR(4000)    ,
@var_iddoctype     INT				,
@inrubricacomune   CHAR(2000)		,
@tipourp           CHAR(2000)		,
@localita          VARCHAR(4000)    ,
@luogoNascita      VARCHAR(4000)    ,
@dataNascita       VARCHAR(4000)    ,
@titolo            VARCHAR(4000)    ,

-- aggiunto questo parametro e la gestione relativa rispetto alla vecchia versione
@SimpInteropUrl    VARCHAR(4000)    ,
@newid             INT OUTPUT      
--@returnvalue       INT OUTPUT 

AS
BEGIN

-- << REPERIMENTO_DATI >>

	DECLARE @error						INT
	DECLARE @no_data_error				INT
	DECLARE @cnt						INT
	DECLARE @cod_rubrica				VARCHAR(128)
	DECLARE @id_reg						INT
	DECLARE @idamm						INT
	DECLARE @new_var_cod_rubrica		VARCHAR(128)
	DECLARE @cha_dettaglio				CHAR(1) = '0'
	DECLARE @cha_tipourp				CHAR(1)
	DECLARE @myprofile					INT
	DECLARE @new_idcorrglobale			INT
	DECLARE @identitydettglobali		INT
	DECLARE @outvalue					INT         = 1
	DECLARE @rtn						INT
	DECLARE @v_id_doctype				INT
	DECLARE @identitydpatcanalecorr		INT
	DECLARE @chaTipoIE					CHAR(1)
	DECLARE @numLivello					INT          = 0
	DECLARE @idParent					INT
	DECLARE @idPesoOrg					INT
	DECLARE @idUO						INT
	DECLARE @idGruppo					INT
	DECLARE @idTipoRuolo				INT
	DECLARE @cha_tipo_corr				CHAR(1)
	DECLARE @chapa						CHAR(1)
	DECLARE @var_desc_old				VARCHAR(256)
	DECLARE @url						VARCHAR(4000)
   
	BEGIN
	
		SELECT   @cod_rubrica = var_cod_rubrica
			, @cha_tipourp = cha_tipo_urp
			, @id_reg = id_registro
			, @idamm = id_amm
			, @chapa = cha_pa
			, @chaTipoIE = cha_tipo_ie
			, @numLivello = num_livello
			, @idParent = id_parent
			, @idPesoOrg = id_peso_org
			, @idUO = id_uo
			, @idTipoRuolo = id_tipo_ruolo
			, @idGruppo = id_gruppo
			, @var_desc_old = var_desc_corr_old
			, @url = InteropUrl
		FROM DOCSADM.DPA_CORR_GLOBALI
		WHERE system_id = @idcorrglobale
		
		SELECT @no_data_error = @@ROWCOUNT
		
		IF (@no_data_error <> 0)
			PRINT 'select effettuata' 
		IF (@no_data_error = 0)
		BEGIN
			PRINT 'Primo blocco eccezione' 
			SET @outvalue = 0
			RETURN
		END
	END 
   
	IF(@tipourp IS NOT NULL AND @cha_tipourp IS NOT NULL AND @cha_tipourp != @tipourp)
		SET @cha_tipourp = @tipourp

   -- << DATI_CANALE_UTENTE >>
   
	IF @cha_tipourp = 'P'
	BEGIN
		SELECT   @v_id_doctype = id_documenttype
		FROM DOCSADM.DPA_T_CANALE_CORR
		WHERE id_corr_globale = @idcorrglobale
      
		SELECT @no_data_error = @@ROWCOUNT
      
		IF (@no_data_error = 0)
		BEGIN
			PRINT 'Secondo blocco eccezione' 
			SET @outvalue = 2
		END
	END 

	IF /* 0 */ @outvalue = 1
	BEGIN
		/* 1 */
		IF @cha_tipourp = 'U' OR @cha_tipourp = 'P'
			SET @cha_dettaglio = '1'
        /* 1 */

--VERIFICO SE IL CORRISP ?? STATO UTILIZZATO COME DEST/MITT DI PROTOCOLLI

		SELECT @myprofile = COUNT(ID_PROFILE)
		FROM DOCSADM.DPA_DOC_ARRIVO_PAR
		WHERE ID_MITT_DEST = @idcorrglobale
		
		PRINT '@myprofile'  + cast(@myprofile as varchar)
		
-- 1) non ?? stato mai utilizzato come corrisp in un protocollo
		/* 2 */ 
		IF(@myprofile = 0)
		BEGIN
			BEGIN
				PRINT 'start upd 3o'
				UPDATE DOCSADM.DPA_CORR_GLOBALI 
				SET var_codice_aoo = @codice_aoo
					,var_codice_amm = @codice_amm
					,var_email = @email
					,var_desc_corr = @desc_corr
					,var_nome = @nome
					,var_cognome = @cognome
					,cha_pa = @chapa
					,cha_tipo_urp = @cha_tipourp
					,InteropUrl = @SimpInteropUrl  
				WHERE system_id = @idcorrglobale
				
				SELECT   @error = @@ERROR
            
				IF (@error <> 0)
				BEGIN
					PRINT '3o blocco eccezione' 
					SET @outvalue = 3
					RETURN
				END
			END

			/* SE L'UPDATE SU DPA_CORR_GLOBALI ?? ANDTATA A BUON FINE PER UTENTI E UO DEVO AGGIORNARE IL RECORD SULLA DPA_DETT_GLOBALI */
						
			PRINT @cha_tipourp
			
			/* 3 */
			IF @cha_tipourp = 'U' OR @cha_tipourp = 'P' OR @cha_tipourp = 'F'
			
			-- << UPDATE_DPA_DETT_GLOBALI2 >>
         
			BEGIN
			
				DECLARE @PrintVar VARCHAR(4000)
				
				SELECT   @cnt = count(*)
				FROM DOCSADM.DPA_DETT_GLOBALI
				WHERE ID_CORR_GLOBALI = @idcorrglobale 
				
				SELECT   @error = @@ERROR
				
				IF (@error = 0)
				BEGIN
					IF (@cnt = 0)
					BEGIN
						SET @PrintVar = 'SONO NELLA INSERT,ID_CORR_GLOBALI =  '+cast(@idcorrglobale as varchar)
						PRINT @PrintVar
						INSERT INTO DOCSADM.DPA_DETT_GLOBALI
						(
							id_corr_globali
							, var_indirizzo
							, var_cap
							, var_provincia
							, var_nazione
							, var_cod_fiscale
							, var_telefono
							, var_telefono2
							, var_note
							, var_citta
							, var_fax
							, var_localita
							, var_luogo_nascita
							, dta_nascita
							, var_titolo
						)
						VALUES
						(
							@idcorrglobale
							, @indirizzo
							, @cap
							, @provincia
							, @nazione
							, @cod_fiscale
							, @telefono
							, @telefono2
							, @note
							, @citta
							, @fax
							, @localita
							, @luogoNascita
							, @dataNascita
							, @titolo
						)
                  
						SELECT   @error = @@ERROR
					END
               
					IF (@error = 0)
					BEGIN
						IF (@cnt = 1)
						BEGIN
							PRINT 'SONO NELLA UPDATE'
							 
							UPDATE DOCSADM.DPA_DETT_GLOBALI 
							SET var_indirizzo = @indirizzo
								,var_cap = @cap
								,var_provincia = @provincia
								,var_nazione = @nazione
								,var_cod_fiscale = @cod_fiscale
								,var_telefono = @telefono
								,var_telefono2 = @telefono2
								,var_note = @note
								,var_citta = @citta
								,var_fax = @fax
								,var_localita = @localita
								,var_luogo_nascita = @luogoNascita
								,dta_nascita = @dataNascita
								,var_titolo = @titolo  
							WHERE (id_corr_globali = @idcorrglobale)
							
							SELECT   @error = @@ERROR
							
						END
                  
						IF (@error = 0)
						BEGIN
							PRINT 'SONO NELLA MERGE' 
						END
					END
				END
				IF (@error <> 0)
				BEGIN
					SET @PrintVar = '4o blocco eccezione'+ str(@error)
					PRINT @PrintVar
					SET @outvalue = 4
					RETURN
				END
			END 
            /* 3 */

			--METTI QUI UPDATE SU DPA_T_CANALE_CORR
			--AGGIORNO LA DPA_T_CANALE_CORR

			BEGIN
				UPDATE DOCSADM.DPA_T_CANALE_CORR 
				SET id_documenttype = @var_iddoctype  
				WHERE id_corr_globale = @idcorrglobale
				
				SELECT   @error = @@ERROR
            
				IF (@error <> 0)
				BEGIN
					PRINT '5o blocco eccezione' 
					SET @outvalue = 5
					RETURN
				END
			END
		END
		ELSE
		-- caso 2) Il corrisp ?? stato utilizzato come corrisp in un protocollo
		-- NUOVO CODICE RUBRICA
		BEGIN
			SET @new_var_cod_rubrica = @cod_rubrica + '_' + STR(@idcorrglobale)
			
			-- << storicizzazione_corrisp2 >>
			BEGIN
         
				UPDATE DOCSADM.DPA_CORR_GLOBALI 
				SET dta_fine = GetDate()
					,var_cod_rubrica = @new_var_cod_rubrica
					,var_codice = @new_var_cod_rubrica
					,id_parent = NULL  
				WHERE system_id = @idcorrglobale
				
				SELECT @error = @@ERROR
				IF (@error <> 0)
				BEGIN
				   PRINT '6o blocco eccezione' 
				   SET @outvalue = 6
				   RETURN
				END
			END 
			BEGIN
	         
				IF (@inrubricacomune = '1')
					SET @cha_tipo_corr = 'C'
				ELSE
					SET @cha_tipo_corr = 'S'
				
				IF @myprofile <> 0
				BEGIN
					INSERT INTO DOCSADM.DPA_CORR_GLOBALI
					( 
						num_livello
						, cha_tipo_ie
						, id_registro
						, id_amm
						, var_desc_corr
						, var_nome
						, var_cognome
						, id_old
						, dta_inizio
						, id_parent
						, var_codice
						, cha_tipo_corr
						, cha_tipo_urp
						, var_codice_aoo
						, var_cod_rubrica
						, cha_dettagli
						, var_email
						, var_codice_amm
						, cha_pa
						, id_peso_org
						, id_gruppo
						, id_tipo_ruolo
						, id_uo
						, var_desc_corr_old     
						, InteropUrl
					)
					VALUES
					( 
						@numLivello
						, @chaTipoIE
						, @id_reg
						, @idamm
						, @desc_corr
						, @nome
						, @cognome
						, @idcorrglobale
						, GetDate()
						, @idParent
						, @cod_rubrica
						, @cha_tipo_corr
						, @cha_tipourp
						, @codice_aoo
						, @cod_rubrica
						, @cha_dettaglio
						, @email
						, @codice_amm
						, @chapa
						, @idPesoOrg
						, @idGruppo
						, @idTipoRuolo
						, @idUO
						, @var_desc_old 
						, @SimpInteropUrl
					)
				END
				ELSE
				BEGIN
				
					SET @newid = @@IDENTITY
					
					SET IDENTITY_INSERT dpa_corr_globali ON -- PERMETTE DI DEFINIRE UN VALORE DEL SYSTEM_ID
					
					INSERT INTO DOCSADM.DPA_CORR_GLOBALI
					(
						system_id
						, num_livello
						, cha_tipo_ie
						, id_registro
						, id_amm
						, var_desc_corr
						, var_nome
						, var_cognome
						, id_old
						, dta_inizio
						, id_parent
						, var_codice
						, cha_tipo_corr
						, cha_tipo_urp
						, var_codice_aoo
						, var_cod_rubrica
						, cha_dettagli
						, var_email
						, var_codice_amm
						, cha_pa
						, id_peso_org
						, id_gruppo
						, id_tipo_ruolo
						, id_uo
						, var_desc_corr_old     
						, InteropUrl
					)
					VALUES
					(
						@newid
						, @numLivello
						, @chaTipoIE
						, @id_reg
						, @idamm
						, @desc_corr
						, @nome
						, @cognome
						, @idcorrglobale
						, GetDate()
						, @idParent
						, @cod_rubrica
						, @cha_tipo_corr
						, @cha_tipourp
						, @codice_aoo
						, @cod_rubrica
						, @cha_dettaglio
						, @email
						, @codice_amm
						, @chapa
						, @idPesoOrg
						, @idGruppo
						, @idTipoRuolo
						, @idUO
						, @var_desc_old
						, @SimpInteropUrl
					)
					
					SET IDENTITY_INSERT dpa_corr_globali OFF
				END
	         
				PRINT '@newid-->' + cast(@newid as varchar)


				/* DOPO LA STORICIZZAZIONE DEL VECCHIO CORRISPONDENTE POSSO INSERIRE IL NUOVO CORRISPONDENTE NELLA DPA_CORR_GLOBALI */
	        
				-- << INSERIMENTO_NUOVO_CORRISP2 >>

				SELECT   @error = @@ERROR
				IF (@error <> 0)
				BEGIN
				   PRINT '7o blocco eccezione' 
				   SET @outvalue = 7
				   RETURN
				END
			END 


			/* DOPO L'INSERIMENTO DEL NUOVO CORRISPONDENTE POSSO INSERIRE IL RELATIVO RECORD NELLA DPA_DETT_GLOBALI, MA SOLO PER CORRISPONDENTI UTENTI
				E UNITA' ORGANIZZATIVE */
				
			/* 4 */ 
	        
			IF @cha_tipourp = 'U' OR @cha_tipourp = 'P'
	        
			-- PRENDO LA SYSTEM_ID APPENA INSERITA
			
			BEGIN
				SELECT   @identitydettglobali = @@IDENTITY
				PRINT '@identitydettglobali-->' + cast(@identitydettglobali as varchar)

				--<< inserimento_dettaglio_corrisp2 >>
				BEGIN
	                     
					SET IDENTITY_INSERT dpa_dett_globali ON
					
					INSERT INTO DOCSADM.DPA_DETT_GLOBALI
					(
						system_id
						, id_corr_globali
						, var_indirizzo
						, var_cap
						, var_provincia
						, var_nazione
						, var_cod_fiscale
						, var_telefono
						, var_telefono2
						, var_note
						, var_citta
						, var_fax
						, var_localita
						, var_luogo_nascita
						, dta_nascita
						, var_titolo
					)
					VALUES
					(
						@identitydettglobali
						, @newid
						, @indirizzo
						, @cap
						, @provincia
						, @nazione
						, @cod_fiscale
						, @telefono
						, @telefono2
						, @note
						, @citta
						, @fax
						, @localita
						, @luogoNascita
						, @dataNascita
						, @titolo
					)
					
					SET IDENTITY_INSERT dpa_dett_globali OFF
				
					SELECT @error = @@ERROR
	               
					IF (@error <> 0)
					BEGIN
						PRINT '8o blocco eccezione' 
						SET @outvalue = 8
						RETURN
					END
				END 
			END
	         
			 /* 4 */

			--INSERISCO IL CANALE PREFERITO DEL NUOVO CORRISP ESTERNO SIA ESSO UO, RUOLO, PERSONA
			
			-- << inserimento_dpa_t_canale_corr2 >>
	         
			BEGIN

				INSERT INTO DOCSADM.DPA_T_CANALE_CORR
				(
					id_corr_globale
					, id_documenttype
					, cha_preferito
				)
				VALUES
				(
					@newid
					, @var_iddoctype
					, '1'
				)
		            
				SELECT @error = @@ERROR, @identitydpatcanalecorr = @@identity
				IF (@error <> 0)
				BEGIN
					PRINT '9o blocco eccezione' 
					SET @outvalue = 9
					RETURN
				END
			END 
		END

		-- SE FA PARTE DI UNA LISTA, ALLORA LA DEVO AGGIORNARE.

		IF @newid IS NOT NULL
			UPDATE DOCSADM.DPA_LISTE_DISTR  
			SET ID_DPA_CORR = @newid 
			FROM DOCSADM.DPA_LISTE_DISTR d 
			WHERE d.ID_DPA_CORR = @idcorrglobale
	END

	/* 2 */
	/* 0 */
    RETURN @outvalue
    
END

