USE [GFD_SVIL]
GO
/****** Object:  StoredProcedure [DOCSADM].[InsertDataInHistoryProf]    Script Date: 03/08/2013 11:14:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER Procedure [DOCSADM].[InsertDataInHistoryProf] @objType VARCHAR(4000),

@Idtemplate  VARCHAR(4000),

@idDocOrFasc VARCHAR(4000),

@Idoggcustom VARCHAR(4000),

@Idpeople VARCHAR(4000),

@Idruoloinuo VARCHAR(4000),

@Descmodifica VARCHAR(4000) as

--@Returnvalue INT OUTPUT  AS
Begin

/*AUTHOR:   Samuele Furnari



NAME:     InsertDataInHistoryProf



PURPOSE:  Store per l'inserimento di una voce nello storico dei campi 

profilati di documenti / fascicoli. 



******************************************************************************/

   Begin
      DECLARE @enHis CHAR = ''



-- Verifica del flag di attivazione storico per il campo

      if @objType = 'D'
      begin
         Select   @enHis = Enabledhistory From dpa_ogg_custom_comp
         Where id_ogg_custom = @Idoggcustom And id_template = @Idtemplate
      end
   --else
   --   Select   @enHis = Enabledhistory From dpa_ogg_custom_comp_fasc
   --   Where id_ogg_custom = @Idoggcustom And id_template = @Idtemplate
	



-- Se  attiva la storicizzazione del campo, viene inserita una riga nello storico

     

-- Se l'oggetto da storicizzare  un documento, viene inserita una riga 

-- nello storico dei documenti, altrimenti viene inserita in quella dei

-- fascicoli

         If (@objType = 'D' and @enHis = '1')
         begin
            Insert Into [DOCSADM].DPA_PROFIL_STO(Id_Template, Dta_Modifica, Id_Profile, Id_Ogg_Custom, Id_People, Id_Ruolo_In_Uo, Var_Desc_Modifica)
Values(@Idtemplate, GetDate(), @idDocOrFasc, @Idoggcustom, @Idpeople, @Idruoloinuo, @Descmodifica)
		end

      Else
      begin
         Insert Into [DOCSADM].Dpa_Profil_Fasc_Sto(Id_Template, Dta_Modifica, Id_Project, Id_Ogg_Custom, Id_People, Id_Ruolo_In_Uo, Var_Desc_Modifica)
Values(@Idtemplate, GetDate(), @idDocOrFasc, @Idoggcustom, @Idpeople, @Idruoloinuo, @Descmodifica)
 
      End

  
   --SET @Returnvalue = 0

End
end