--------------------------------------------------------
--  DDL for Function GETVISIBILITA
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "ITCOLL_6GIU12"."GETVISIBILITA" (p_IdAmm number, p_Idmodello number)

RETURN INT IS result INT;
ragioneCC number;
ragioneComp number;
ragioneConos number;
ragioneRef number;
ragioneTO number;

BEGIN

begin
result := 0;

IF (p_IdAmm IS NOT NULL) THEN
BEGIN
SELECT DPA_AMMINISTRA.ID_RAGIONE_CC into ragioneCC FROM DPA_AMMINISTRA WHERE DPA_AMMINISTRA.SYSTEM_ID = p_IdAmm;
SELECT DPA_AMMINISTRA.ID_RAGIONE_COMPETENZA into ragioneComp FROM DPA_AMMINISTRA WHERE DPA_AMMINISTRA.SYSTEM_ID = p_IdAmm;
SELECT DPA_AMMINISTRA.ID_RAGIONE_CONOSCENZA into ragioneConos FROM DPA_AMMINISTRA WHERE DPA_AMMINISTRA.SYSTEM_ID = p_IdAmm;
SELECT DPA_AMMINISTRA.ID_RAGIONE_REFERENTE into ragioneRef FROM DPA_AMMINISTRA WHERE DPA_AMMINISTRA.SYSTEM_ID = p_IdAmm;
SELECT DPA_AMMINISTRA.ID_RAGIONE_TO into ragioneTO FROM DPA_AMMINISTRA WHERE DPA_AMMINISTRA.SYSTEM_ID = p_IdAmm;

IF (ragioneCC != 0 AND ragioneCC IS NOT NULL) THEN
SELECT COUNT(DPA_RAGIONE_TRASM.SYSTEM_ID) into result FROM DPA_RAGIONE_TRASM
WHERE DPA_RAGIONE_TRASM.CHA_EREDITA = '1' AND DPA_RAGIONE_TRASM.SYSTEM_ID IN
(SELECT DPA_AMMINISTRA.ID_RAGIONE_CC FROM DPA_AMMINISTRA
WHERE DPA_AMMINISTRA.SYSTEM_ID = p_IdAmm);
END IF;

IF (ragioneComp != 0 AND ragioneComp IS NOT NULL AND result < 1) THEN
SELECT COUNT(DPA_RAGIONE_TRASM.SYSTEM_ID) into result FROM DPA_RAGIONE_TRASM
WHERE DPA_RAGIONE_TRASM.CHA_EREDITA = '1' AND DPA_RAGIONE_TRASM.SYSTEM_ID IN
(SELECT DPA_AMMINISTRA.ID_RAGIONE_COMPETENZA FROM DPA_AMMINISTRA
WHERE DPA_AMMINISTRA.SYSTEM_ID = p_IdAmm);
END IF;

IF (ragioneConos != 0 AND ragioneConos IS NOT NULL AND result < 1) THEN
SELECT COUNT(DPA_RAGIONE_TRASM.SYSTEM_ID) into result FROM DPA_RAGIONE_TRASM
WHERE DPA_RAGIONE_TRASM.CHA_EREDITA = '1' AND DPA_RAGIONE_TRASM.SYSTEM_ID IN
(SELECT DPA_AMMINISTRA.ID_RAGIONE_CONOSCENZA FROM DPA_AMMINISTRA
WHERE DPA_AMMINISTRA.SYSTEM_ID = p_IdAmm);
END IF;

IF (ragioneRef != 0 AND ragioneRef IS NOT NULL AND result < 1) THEN
SELECT COUNT(DPA_RAGIONE_TRASM.SYSTEM_ID) into result FROM DPA_RAGIONE_TRASM
WHERE DPA_RAGIONE_TRASM.CHA_EREDITA = '1' AND DPA_RAGIONE_TRASM.SYSTEM_ID IN
(SELECT DPA_AMMINISTRA.ID_RAGIONE_REFERENTE FROM DPA_AMMINISTRA
WHERE DPA_AMMINISTRA.SYSTEM_ID = p_IdAmm);
END IF;

IF (ragioneTO != 0 AND ragioneTO IS NOT NULL AND result < 1) THEN
SELECT COUNT(DPA_RAGIONE_TRASM.SYSTEM_ID) into result FROM DPA_RAGIONE_TRASM
WHERE DPA_RAGIONE_TRASM.CHA_EREDITA = '1' AND DPA_RAGIONE_TRASM.SYSTEM_ID IN
(SELECT DPA_AMMINISTRA.ID_RAGIONE_TO FROM DPA_AMMINISTRA
WHERE DPA_AMMINISTRA.SYSTEM_ID = p_IdAmm);
END IF;
END;
END IF;

IF (p_Idmodello IS NOT NULL AND result < 1) THEN
SELECT COUNT(DPA_RAGIONE_TRASM.SYSTEM_ID) into result FROM DPA_RAGIONE_TRASM
WHERE DPA_RAGIONE_TRASM.CHA_EREDITA = '1' AND DPA_RAGIONE_TRASM.SYSTEM_ID IN
(SELECT DISTINCT DPA_MODELLI_MITT_DEST.ID_RAGIONE FROM DPA_MODELLI_MITT_DEST
WHERE DPA_MODELLI_MITT_DEST.ID_MODELLO = p_Idmodello);
END IF;

EXCEPTION
WHEN NO_DATA_FOUND THEN result := 1;
WHEN OTHERS THEN result := 1;
end;

IF(result > 0) THEN
result := 1;
ELSE
result := 0;
ENd IF;

RETURN result;

END getVisibilita;

/
