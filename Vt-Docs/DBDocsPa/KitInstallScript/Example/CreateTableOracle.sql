---NOME TABELLA E NOME COLONNA SEMPRE MAIUSCOLI !!!!
select count(*) into cnt from user_tables where table_name='APPS';
		if (cnt = 0) then
			execute immediate	
				'CREATE TABLE APPS ' ||
				'( ' ||
				'  SYSTEM_ID          NUMBER(10), ' ||
				'  APPLICATION        VARCHAR2(64 BYTE), ' ||
				'  DESCRIPTION        VARCHAR2(256 BYTE), ' ||
				'  COUNT_KEYS         VARCHAR2(1 BYTE), ' ||
				'  TIMEOUT            NUMBER(10), ' ||
				'  VER_TOLERANT       VARCHAR2(1 BYTE), ' ||
				'  FILING_SCHEME      NUMBER(10), ' ||
				'  VALID_ON_PROFILE   VARCHAR2(1 BYTE), ' ||
				'  READ_ONLY          VARCHAR2(1 BYTE), ' ||
				'  DEFAULT_EXTENSION  VARCHAR2(256 BYTE), ' ||
				'  OPEN_LAUNCH        VARCHAR2(1 BYTE), ' ||
				'  ON_DESKTOP         VARCHAR2(1 BYTE), ' ||
				'  DOS_MONITORING     VARCHAR2(1 BYTE), ' ||
				'  LANGUAGE           NUMBER(10), ' ||
				'  VIEWER             NUMBER(10), ' ||
				'  PRINTING           NUMBER(10), ' ||
				'  DISABLED           VARCHAR2(1 BYTE), ' ||
				'  OUTPUT_EXTS        VARCHAR2(50 BYTE), ' ||
				'  PDFCOMPAT          VARCHAR2(1 BYTE), ' ||
				'  INTEGRATED         VARCHAR2(1 BYTE), ' ||
				'  FILE_TYPES         LONG, ' ||
				'  SUPER_APP          VARCHAR2(1 BYTE), ' ||
				'  USE_UNCNAME        VARCHAR2(1 BYTE), ' ||
				'  DIRMON_STUBCHECK   VARCHAR2(1 BYTE), ' ||
				'  MIME_TYPE          VARCHAR2(100 BYTE) ' ||
				') TABLESPACE @ora_dattblspc_name';
		end if;