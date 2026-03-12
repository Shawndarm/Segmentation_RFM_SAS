/*************************************************************************************************/
/***********************************  PROJET SEGMENTATION RFM  ***********************************/
/*************************************************************************************************/

/*-----------------------------------------------------------------------------------------------*/
/*                                    2. ANALYSE DESCRIPTIVE DES CLIENTS                         */
/*-----------------------------------------------------------------------------------------------*/

/*--------------------------------------  INITIALISATION  ---------------------------------------*/

LIBNAME DATA "C:\Users\dutau\Desktop\SAS S1\Projet\DATA\SAS";
LIBNAME RESUS "C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\SAS";
LIBNAME RESUX "C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL";



      
/* REPARTITION DATES D'INSCRIPTION */
PROC FREQ DATA = DATA.VENTES;
	TABLES MOIS_AN_INSCRIPTION / NOPRINT NOCUM OUT = FREQ_DATE;
RUN;
/* EXPORT EXCEL */
PROC EXPORT DATA = FREQ_DATE
    OUTFILE="C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL\02_Analyse_descriptive_rapport.xlsx"
    DBMS=XLSX REPLACE;
    SHEET="FREQ_DATE_INSCRIPTION";
RUN;

/*---------------------------  A. ANALYSE DESCRIPTIVE DES CLIENTS DE LA BASE CLIENTS  ------------------------------*/
/* CARACTERISTIQUES CLIENTS */
PROC SQL;
	CREATE TABLE CARAC_CLIENTS AS
    SELECT 
        COUNT(DISTINCT NUM_CLIENT)       AS NB_CLIENTS,                              
        SUM(ACTIF=1)                     AS COMPTE_OUVERT,
        SUM(INSCRIT_NL=1)                AS INSCRIT_NL,
        SUM(GENRE="Femme")         		 AS NB_FEMMES,
        SUM(GENRE="Homme")         		 AS NB_HOMMES,
        SUM(MISSING(AGE))                AS AGE_INCONNU,
        SUM(AGE >= 0 AND AGE <= 25 )     AS AGE_MOINS_DE_25,
        SUM(AGE > 25 AND AGE <= 35)      AS AGE_25_35_ANS,
        SUM(AGE > 35 AND AGE <= 45)      AS AGE_35_45_ANS,
        SUM(AGE > 45 AND AGE <= 55)      AS AGE_45_55_ANS,
        SUM(AGE > 55 AND AGE <= 65)      AS AGE_55_65_ANS,
        SUM(AGE > 65)                    AS AGE_PLUS_DE_65_ANS,
        AVG(AGE)                         AS AGE_MOYEN
    FROM DATA.CLIENTS_CLEAN;
QUIT;
PROC TRANSPOSE DATA = CARAC_CLIENTS 
	OUT= CARAC_CLIENTS 
    (RENAME=(COL1=VALEUR));  RUN;
/* EXPORT  EXCEL */
PROC EXPORT DATA = CARAC_CLIENTS
    OUTFILE="C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL\02_Analyse_descriptive_rapport.xlsx"
    DBMS=XLSX REPLACE;
    SHEET="Base_5096_clients";
RUN;


/*---------------------------  B. ANALYSE DESCRIPTIVE DES CLIENTS AYANT REELLEMENT COMMANDE POSITIVEMENT  ------------------------------*/
PROC SQL;
    CREATE TABLE CLIENTS_COMMANDANT AS
    SELECT 
        NUM_CLIENT,
        ACTIF,
        INSCRIT_NL,
        GENRE,
        AVG(AGE) AS AGE  
    FROM DATA.VENTES     
    GROUP BY NUM_CLIENT, ACTIF, INSCRIT_NL, GENRE;
QUIT;
PROC SQL;
	CREATE TABLE CARAC_CLIENTS_COMMANDANT AS
    SELECT 
        COUNT(DISTINCT NUM_CLIENT)       AS NB_CLIENTS  ,                              
        SUM(ACTIF=1)                     AS COMPTE_OUVERT,
        SUM(INSCRIT_NL=1)                AS INSCRIT_NL,
        SUM(GENRE="Femme")         		 AS NB_FEMMES,
        SUM(GENRE="Homme")         		 AS NB_HOMMES,
        SUM(MISSING(AGE))                AS AGE_INCONNU,
        SUM(AGE >= 0 AND AGE <= 25 )     AS AGE_MOINS_DE_25,
        SUM(AGE > 25 AND AGE <= 35)      AS AGE_25_35_ANS,
        SUM(AGE > 35 AND AGE <= 45)      AS AGE_35_45_ANS,
        SUM(AGE > 45 AND AGE <= 55)      AS AGE_45_55_ANS,
        SUM(AGE > 55 AND AGE <= 65)      AS AGE_55_65_ANS,
        SUM(AGE > 65)                    AS AGE_PLUS_DE_65_ANS,
        AVG(AGE)                         AS AGE_MOYEN
    FROM CLIENTS_COMMANDANT;
QUIT;
PROC TRANSPOSE DATA = CARAC_CLIENTS_COMMANDANT 
	OUT = CARAC_CLIENTS_COMMANDANT 
    (RENAME=(COL1=VALEUR));  RUN;
/* EXPORT  EXCEL */
PROC EXPORT DATA = CARAC_CLIENTS_COMMANDANT
    OUTFILE="C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL\02_Analyse_descriptive_rapport.xlsx"
    DBMS=XLSX REPLACE;
    SHEET="Base_4196_clients";
RUN;



