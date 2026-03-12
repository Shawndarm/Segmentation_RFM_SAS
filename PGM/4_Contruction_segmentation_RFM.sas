/*************************************************************************************************/
/***********************************  PROJET SEGMENTATION RFM  ***********************************/
/*************************************************************************************************/

/*-----------------------------------------------------------------------------------------------*/
/*                             4. CONSTRUCTION DE LA SEGMENTATION RFM                                  */
/*-----------------------------------------------------------------------------------------------*/

/*--------------------------------------  INITIALISATION  ---------------------------------------*/

LIBNAME DATA "C:\Users\dutau\Desktop\SAS S1\Projet\DATA\SAS";
LIBNAME RESUS "C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\SAS";
LIBNAME RESUX "C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL";


/****************************              A. APPLICATION DES REGLES DE DECOUPAGES RFM             ***********************************/ 

PROC SQL;
	CREATE TABLE RESUS.APPLICATION_SEUIL AS
		SELECT
			NUM_CLIENT,
			RECENCE,
			FREQUENCE,
			MONTANT,
		 	/* SEGMENTATION RECENCE */
		    CASE 
				WHEN RECENCE <= 6  THEN "R3"
				WHEN RECENCE <= 12 THEN "R2"
				WHEN RECENCE >  12 THEN "R1"
				ELSE "?"
			END AS SEG_RECENCE,
    		/* SEGMENTATION FREQUENCE */
			CASE 
				WHEN FREQUENCE = 1   THEN "F1"
				WHEN FREQUENCE <= 3  THEN "F2"
				WHEN FREQUENCE > 3   THEN "F3"
				ELSE "?"
			END AS SEG_FREQUENCE,
		    /* SEGMENTATION MONTANT */
			CASE 
				WHEN MONTANT < 50    THEN "M1"
				WHEN MONTANT < 100  THEN "M2"
				WHEN MONTANT >= 100   THEN "M3"
				ELSE "?"
			END AS SEG_MONTANT
		FROM RESUS.INDICATEURS_RFM;
QUIT;
PROC FREQ DATA = RESUS.APPLICATION_SEUIL;
	TABLES SEG_RECENCE SEG_FREQUENCE SEG_MONTANT;
RUN;


/****************************              B.1. CROISEMENT RECENCE ET FREQUENCE           ***********************************/ 

PROC FREQ DATA = RESUS.APPLICATION_SEUIL;
	TABLE SEG_RECENCE*SEG_FREQUENCE / NOPRINT OUT = CROISEMENT_RECENCE_FREQUENCE NOFREQ NOROW NOCOL;
RUN;
/* EXPORT EXCEL */
PROC EXPORT DATA = CROISEMENT_RECENCE_FREQUENCE
    OUTFILE="C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL\04_Construction_Segmentation_rapport.xlsx"
    DBMS=XLSX REPLACE;
	SHEET="RF";
RUN;
/****************************              CONSTRUCTION DES SEGMENTS RF             ***********************************/ 

DATA APPLICATION_SEUIL_RF;
    SET RESUS.APPLICATION_SEUIL;
    IF (SEG_RECENCE = "R1" AND SEG_FREQUENCE = "F1") 
	OR (SEG_RECENCE = "R1" AND SEG_FREQUENCE = "F2") THEN SEG_RF = "RF1";
    ELSE IF (SEG_RECENCE = "R1" AND SEG_FREQUENCE = "F3")
         OR (SEG_RECENCE = "R2" AND SEG_FREQUENCE = "F1")
         OR (SEG_RECENCE = "R2" AND SEG_FREQUENCE = "F2")
         OR (SEG_RECENCE = "R3" AND SEG_FREQUENCE = "F1") THEN SEG_RF = "RF2";
    ELSE IF (SEG_RECENCE = "R2" AND SEG_FREQUENCE = "F3")
         OR (SEG_RECENCE = "R3" AND SEG_FREQUENCE = "F2")
         OR (SEG_RECENCE = "R3" AND SEG_FREQUENCE = "F3") THEN SEG_RF = "RF3";
    ELSE SEG_RF = "?";
RUN;
PROC FREQ DATA = APPLICATION_SEUIL_RF;
	TABLE SEG_RF;
RUN;

/****************************              B.2. CONSTRUCTION DES SEGMENTS RF-M             ***********************************/ 

PROC FREQ DATA =  APPLICATION_SEUIL_RF;
	TABLE SEG_RF*SEG_MONTANT / NOPRINT OUT  = CROISEMENT_RF_MONTANT NOFREQ NOROW NOCOL;
RUN;
/* EXPORT EXCEL */
PROC EXPORT DATA = CROISEMENT_RF_MONTANT
    OUTFILE="C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL\04_Construction_Segmentation_rapport.xlsx"
    DBMS=XLSX REPLACE;
	SHEET="RFM";
RUN;

/****************************              CREATION DES DES SEGMENTS RFM             ***********************************/ 

DATA RESUS.SEGMENT_RFM;
    SET APPLICATION_SEUIL_RF;
    IF      SEG_RF = "RF1" AND SEG_MONTANT = "M1" THEN SEG_RFM = "RFM1";
    ELSE IF SEG_RF = "RF1" AND SEG_MONTANT = "M2" THEN SEG_RFM = "RFM2";
    ELSE IF SEG_RF = "RF1" AND SEG_MONTANT = "M3" THEN SEG_RFM = "RFM3";
    ELSE IF SEG_RF = "RF2" AND SEG_MONTANT = "M1" THEN SEG_RFM = "RFM4";
    ELSE IF SEG_RF = "RF2" AND SEG_MONTANT = "M2" THEN SEG_RFM = "RFM5";
    ELSE IF SEG_RF = "RF2" AND SEG_MONTANT = "M3" THEN SEG_RFM = "RFM6";
    ELSE IF SEG_RF = "RF3" AND SEG_MONTANT = "M1" THEN SEG_RFM = "RFM7";
    ELSE IF SEG_RF = "RF3" AND SEG_MONTANT = "M2" THEN SEG_RFM = "RFM8";
    ELSE IF SEG_RF = "RF3" AND SEG_MONTANT = "M3" THEN SEG_RFM = "RFM9";
    ELSE SEG_RFM = "?";
RUN;
PROC FREQ DATA = RESUS.SEGMENT_RFM;
	TABLE SEG_RFM;
RUN;
