USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Select_TempProfileViewByDisposalID]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Select_TempProfileViewByDisposalID]  ( @Disposal_ID int  )
AS
BEGIN


select distinct
	d.SYSTEM_ID DOCID-- system_id della profile
	, d.NUM_PROTO -- numero di protocollo
	, d.NUM_ANNO_PROTO
	, r.VAR_CODICE REGISTRO --tp.Registro
	, CG.VAR_CODICE UO --tp.UO
	, d.VAR_PROF_OGGETTO OGGETTODOCUMENTO --tp.OggettoDocumento
	, d.CHA_TIPO_PROTO TIPODOCUMENTO --tp.TipoDocumento
	, d.CREATION_DATE DATACREAZIONE --tp.DataCreazione
	, TA.VAR_DESC_ATTO TIPOLOGIA --tp.Tipologia
	--, tp.TipoTrasferimento_Versamento
	, T1.CODE
	, T2.CORR
	, tp.DASCARTARE
from ARCHIVE_TempProfileDisposal tp
left outer join PROFILE d on tp.Profile_ID = d.SYSTEM_ID
left outer join DPA_EL_REGISTRI r on d.ID_REGISTRO = r.SYSTEM_ID
left outer join DPA_CORR_GLOBALI CG ON d.ID_UO_CREATORE = CG.SYSTEM_ID
left outer join DPA_TIPO_ATTO TA ON d.ID_TIPO_ATTO = TA.SYSTEM_ID
left outer join
	(
	SELECT 
	  [ID],
	  STUFF((
		SELECT ' ; ' + [Name]
		FROM 
			(
			select distinct tp.profile_id ID, f.var_codice NAME--, f.ProjectCode NAME
			from ARCHIVE_TempProfileDisposal tp
			left outer join PROJECT_COMPONENTS pc on tp.profile_id = pc.link
			left outer join PROJECT p on pc.project_id = p.system_id
			left outer join PROJECT f on p.id_parent = f.system_id
			where tp.disposal_id = @Disposal_ID
						
			) T 
		WHERE (ID = T1.ID) 
		FOR XML PATH (''))
	  ,1,2,'') AS Code
	FROM 
		(			
		select distinct tp.profile_id ID, f.var_codice NAME--, f.ProjectCode NAME
		from ARCHIVE_TempProfileDisposal tp
		left outer join PROJECT_COMPONENTS pc on tp.profile_id = pc.link
		left outer join PROJECT p on pc.project_id = p.system_id
		left outer join PROJECT f on p.id_parent = f.system_id
		where tp.disposal_id = @Disposal_ID
		) T1
	GROUP BY ID	
	) T1 on tp.Profile_ID = T1.ID
left outer join
	(
	SELECT 
	  [ID],
	  STUFF((
		SELECT ' ; ' + CORR 
		FROM 
			(
			select distinct tp.profile_id ID, case
				when d.CHA_TIPO_PROTO = 'A' then COR_MITT.VAR_DESC_CORR
				when d.CHA_TIPO_PROTO = 'P' then COR_DEST.VAR_DESC_CORR
			end CORR
			from ARCHIVE_TempProfileDisposal tp
				--inner join ARCHIVE_TransferPolicy p on tp.TransferPolicy_ID = p.System_ID
				inner join PROFILE d on tp.Profile_ID = d.SYSTEM_ID
				left outer join DPA_DOC_ARRIVO_PAR MITT on tp.Profile_ID = MITT.ID_PROFILE and MITT.CHA_TIPO_MITT_DEST = 'M'
				left outer join DPA_DOC_ARRIVO_PAR DEST on tp.Profile_ID = DEST.ID_PROFILE and DEST.CHA_TIPO_MITT_DEST = 'D'
				left outer join DPA_CORR_GLOBALI COR_MITT on MITT.ID_MITT_DEST = COR_MITT.SYSTEM_ID
				left outer join DPA_CORR_GLOBALI COR_DEST on DEST.ID_MITT_DEST = COR_DEST.SYSTEM_ID
			where tp.Disposal_ID = @Disposal_ID --@Transfer_ID 
			--and p.Enabled = 1
			) T 
		WHERE (ID = T1.ID) 
		FOR XML PATH (''))
	  ,1,2,'') AS Corr
	FROM 
		(
		select distinct tp.profile_id ID, case
			when d.CHA_TIPO_PROTO = 'A' then COR_MITT.VAR_DESC_CORR
			when d.CHA_TIPO_PROTO = 'P' then COR_DEST.VAR_DESC_CORR
		end CORR
		from ARCHIVE_TempProfileDisposal tp
			--inner join ARCHIVE_TransferPolicy p on tp.TransferPolicy_ID = p.System_ID
			inner join PROFILE d on tp.Profile_ID = d.SYSTEM_ID
			left outer join DPA_DOC_ARRIVO_PAR MITT on tp.Profile_ID = MITT.ID_PROFILE and MITT.CHA_TIPO_MITT_DEST = 'M'
			left outer join DPA_DOC_ARRIVO_PAR DEST on tp.Profile_ID = DEST.ID_PROFILE and DEST.CHA_TIPO_MITT_DEST = 'D'
			left outer join DPA_CORR_GLOBALI COR_MITT on MITT.ID_MITT_DEST = COR_MITT.SYSTEM_ID
			left outer join DPA_CORR_GLOBALI COR_DEST on DEST.ID_MITT_DEST = COR_DEST.SYSTEM_ID
		where tp.Disposal_ID = @Disposal_ID --@Transfer_ID 
		) T1
	GROUP BY ID	
	) T2 on tp.Profile_ID=T2.ID
where tp.Disposal_ID = @Disposal_ID --@Disposal_ID 
--and p.Enabled = 1


END
GO
