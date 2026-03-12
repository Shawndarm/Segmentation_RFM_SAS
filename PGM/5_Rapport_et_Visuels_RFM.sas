/*************************************************************************************************/
/***********************************  PROJET SEGMENTATION RFM  ***********************************/
/*************************************************************************************************/

/*-----------------------------------------------------------------------------------------------*/
/*                             5. ANALYSE FINALE DE LA SEGMENTATION RFM                                  */
/*-----------------------------------------------------------------------------------------------*/

/*--------------------------------------  INITIALISATION  ---------------------------------------*/

LIBNAME DATA "C:\Users\dutau\Desktop\SAS S1\Projet\DATA\SAS";
LIBNAME RESUS "C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\SAS";
LIBNAME RESUX "C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL";


/****************************              A. RECUPERATION RFM             ***********************************/
PROC SQL;
    CREATE TABLE RESUS.CLIENTELE_RFM AS
    SELECT 
        A.NUM_CLIENT,
        ACTIF,
        INSCRIT_NL,
        GENRE,
		A_ETE_PARRAINE,
        MAX(AGE) AS AGE,
		SUM(MONTANT_TOTAL_PAYE) AS CA_TOTAL,
		AVG(MONTANT_TOTAL_PAYE) AS CA_MOYEN,
        COUNT(DISTINCT NUMERO_COMMANDE) AS NB_COMMANDES,
		DATE_INSCRIPTION,
		B.SEG_RFM
    FROM DATA.VENTES AS A 
	LEFT JOIN RESUS.SEGMENT_RFM AS B 
		ON A.NUM_CLIENT = B.NUM_CLIENT
    GROUP BY A.NUM_CLIENT, ACTIF, A_ETE_PARRAINE, INSCRIT_NL, GENRE,DATE_INSCRIPTION, B.SEG_RFM ;
QUIT;

/****************************              B. AGGREGATION PAR SEGMENTS             ***********************************/
PROC SQL;
	CREATE TABLE RESUS.AGGREGATION_SEGMENTS_RFM AS
    SELECT 
        SEG_RFM,
        COUNT(*) AS EFFECTIF,
        (COUNT(*))/4196 AS PCT_EFFECTIF,
		SUM(GENRE="Homme") AS HOMMES,
		SUM(GENRE="Femme") AS FEMMES,
		SUM(MISSING(AGE))                AS AGE_INCONNU,
        SUM(AGE >= 0 AND AGE <= 25 )     AS AGE_MOINS_DE_25,
        SUM(AGE > 25 AND AGE <= 35)      AS AGE_25_35_ANS,
        SUM(AGE > 35 AND AGE <= 45)      AS AGE_35_45_ANS,
        SUM(AGE > 45 AND AGE <= 55)      AS AGE_45_55_ANS,
        SUM(AGE > 55 AND AGE <= 65)      AS AGE_55_65_ANS,
        SUM(AGE > 65)                    AS AGE_PLUS_DE_65_ANS,
		SUM(INTCK("YEAR", DATE_INSCRIPTION, '01JAN2023'D) >= 5) AS ANCIENNETE_SUP_5_ANS,
		SUM( (INTCK("YEAR", DATE_INSCRIPTION, '01JAN2023'D) < 5) 
         AND (INTCK("YEAR", DATE_INSCRIPTION, '01JAN2023'D) >= 2) ) AS ANCIENNETE_2_5_ANS,
		SUM(INTCK("YEAR", DATE_INSCRIPTION, '01JAN2023'D) < 2 ) AS ANCIENNETE_INF_2_ANS,
		SUM(MISSING(DATE_INSCRIPTION))                AS ANCIENNETE_INCONNUE,
		SUM(INSCRIT_NL) AS INSCRITS_NL,
		AVG(INSCRIT_NL) AS PCT_INSCRITS_NL,
		SUM(CA_TOTAL) AS CA_TOTAL_SEG,
		AVG(CA_TOTAL) AS ARPU,
		AVG(NB_COMMANDES) AS NB_COMMANDES_MOYEN
    FROM RESUS.CLIENTELE_RFM
    GROUP BY SEG_RFM;
QUIT;
/* EXPORT  EXCEL */
PROC EXPORT DATA = RESUS.AGGREGATION_SEGMENTS_RFM
    OUTFILE="C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL\05_Présentation_résultats_rapport.xlsx"
    DBMS=XLSX REPLACE;
RUN;

