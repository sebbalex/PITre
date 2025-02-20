if exists (select * from dbo.sysobjects where id = object_id(N'[@db_user].[RDE_Autorizzazione]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [@db_user].[RDE_Autorizzazione]
GO

CREATE VIEW  @db_user.RDE_Autorizzazione
AS
SELECT DISTINCT  @db_user.DPA_EL_REGISTRI.SYSTEM_ID AS IdRegistroRemoto,  @db_user.PEOPLE.SYSTEM_ID AS IdUtenteRemoto
FROM    @db_user.DPA_TIPO_F_RUOLO INNER JOIN
@db_user.DPA_TIPO_FUNZIONE ON  @db_user.DPA_TIPO_F_RUOLO.ID_TIPO_FUNZ =  @db_user.DPA_TIPO_FUNZIONE.SYSTEM_ID INNER JOIN
@db_user.DPA_EL_REGISTRI INNER JOIN
@db_user.DPA_L_RUOLO_REG ON  @db_user.DPA_EL_REGISTRI.SYSTEM_ID =  @db_user.DPA_L_RUOLO_REG.ID_REGISTRO INNER JOIN
@db_user.DPA_CORR_GLOBALI ON  @db_user.DPA_L_RUOLO_REG.ID_RUOLO_IN_UO =  @db_user.DPA_CORR_GLOBALI.SYSTEM_ID INNER JOIN
@db_user.PEOPLEGROUPS ON  @db_user.DPA_CORR_GLOBALI.ID_GRUPPO =  @db_user.PEOPLEGROUPS.GROUPS_SYSTEM_ID INNER JOIN
@db_user.PEOPLE ON  @db_user.PEOPLEGROUPS.PEOPLE_SYSTEM_ID =  @db_user.PEOPLE.SYSTEM_ID ON
@db_user.DPA_TIPO_F_RUOLO.ID_RUOLO_IN_UO =  @db_user.DPA_L_RUOLO_REG.ID_RUOLO_IN_UO
WHERE  ( @db_user.DPA_TIPO_FUNZIONE.SYSTEM_ID IN (select id_tipo_funzione from @db_user.DPA_FUNZIONI where cod_funzione = 'PROTO_EME')) AND ( @db_user.DPA_CORR_GLOBALI.DTA_FINE IS NULL) AND
( @db_user.DPA_CORR_GLOBALI.CHA_TIPO_URP = 'R')
GO