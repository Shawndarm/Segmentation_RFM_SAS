/*************************************************************************************************/
/***********************************  PROJET SEGMENTATION RFM  ***********************************/
/*************************************************************************************************/

/*-----------------------------------------------------------------------------------------------*/
/*                             3. CONSTRUCTION ET ANALYSE DES INDICATEURS RFM                    */
/*-----------------------------------------------------------------------------------------------*/

/*--------------------------------------  INITIALISATION  ---------------------------------------*/

LIBNAME DATA "C:\Users\dutau\Desktop\SAS S1\Projet\DATA\SAS";
LIBNAME RESUS "C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\SAS";
LIBNAME RESUX "C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL";


/**************    A. CONSTRUCTION DES INDICATEURS R-F-M     ********************/ 

PROC SQL;
	CREATE TABLE RESUS.INDICATEURS_RFM  AS 
		SELECT
			NUM_CLIENT,
			MIN(INTCK('month', DATE_COMMANDE, '01JAN2023'd)) AS RECENCE,   
		    COUNT(DISTINCT (NUMERO_COMMANDE)) AS FREQUENCE,
            MEAN(MONTANT_TOTAL_PAYE) AS MONTANT
	FROM DATA.VENTES
	WHERE 2021 <= YEAR(DATE_COMMANDE) <=  2022   /* Périmètre d'analyse 2ans (2021 et 2022) */
	GROUP BY NUM_CLIENT;
QUIT; 

/*******************************             B-1. ANALYSE DE LA RECENCE             **************************************/ 

PROC FREQ DATA = RESUS.INDICATEURS_RFM ;
TABLE RECENCE / NOPRINT OUTCUM OUTPCT OUT = FREQ_RECENCE;
RUN;
/* EXPORT  EXCEL */
PROC EXPORT DATA = FREQ_RECENCE
    OUTFILE="C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL\03_Construction_Analyse_indicateurs_rapport.xlsx"
    DBMS=XLSX REPLACE;
    SHEET="RECENCE_ANALYSE";
RUN;

/*******************************             B-2. ANALYSE DE LA FREQUENCE             **************************************/ 

PROC FREQ DATA = RESUS.INDICATEURS_RFM; 
TABLE FREQUENCE / NOPRINT OUTCUM OUTPCT OUT = FREQ_FREQUENCE;
RUN;
/* EXPORT  EXCEL */
PROC EXPORT DATA = FREQ_FREQUENCE
    OUTFILE="C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL\03_Construction_Analyse_indicateurs_rapport.xlsx"
    DBMS=XLSX REPLACE;
    SHEET="FREQUENCE_ANALYSE";
RUN;

/*******************************             B-3. ANALYSE DU MONTANT             **************************************/ 

PROC RANK DATA = RESUS.INDICATEURS_RFM
	OUT = RANG_MONTANT
 	GROUPS = 10;
	VAR MONTANT;
	RANKS RANG;
RUN;
PROC SUMMARY DATA = RANG_MONTANT;
	CLASS RANG;
	VAR MONTANT;
	OUTPUT OUT = MONTANT_10_RANG
	MIN = MONTANT_MIN
	MAX = MONTANT_MAX;
RUN;
/* EXPORT  EXCEL */
PROC EXPORT DATA = MONTANT_10_RANG
    OUTFILE="C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL\03_Construction_Analyse_indicateurs_rapport.xlsx"
    DBMS=XLSX REPLACE;
    SHEET="MONTANT_ANALYSE";
RUN;


