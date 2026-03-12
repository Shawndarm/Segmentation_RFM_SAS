/*************************************************************************************************/
/***********************************  PROJET SEGMENTATION RFM  ***********************************/
/*************************************************************************************************/

/*-----------------------------------------------------------------------------------------------*/
/*                                    1. AUDIT ET NETTOYAGE DES DONNES                           */
/*-----------------------------------------------------------------------------------------------*/

/*--------------------------------------  INITIALISATION  ---------------------------------------*/

LIBNAME DATA "C:\Users\dutau\Desktop\SAS S1\Projet\DATA\SAS";
LIBNAME RESUS "C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\SAS";
LIBNAME RESUX "C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL";


/*--------------------------------------  A. AUDIT PREALABLE  ---------------------------------------*/
PROC SQL;
    CREATE TABLE AUDIT_CLIENT        		/*Pour les clients*/
    AS SELECT
        /* VOLUMETRIE */
        COUNT(*)                        	AS NB_LIGNES,
        COUNT(DISTINCT NUM_CLIENT)      	AS NB_NUM_CLIENTS,
        /* VALEURS MANQUANTES */
        SUM(MISSING(NUM_CLIENT))        	AS NB_MISSING_NUM_CLIENT,
        SUM(MISSING(ACTIF))             	AS NB_MISSING_ACTIF,
        SUM(MISSING(VAR3))           		AS NB_MISSING_VAR3,
        SUM(MISSING(A_ETE_PARRAINE))    	AS NB_MISSING_A_ETE_PARRAINE,
        SUM(MISSING(GENRE))          		AS NB_MISSING_CIVILITE_CLIENT,
        SUM(MISSING(DATE_NAISSANCE))    	AS NB_MISSING_DATE_NAISSANCE,
        SUM(MISSING(INSCRIT_NL))        	AS NB_MISSING_INSCRIT_NL,
        /* PLAGES DE DATES */
        MAX(VAR3) FORMAT=DDMMYY10.          AS MAX_VAR3,
        MIN(VAR3) FORMAT=DDMMYY10.          AS MIN_VAR3,
        MAX(DATE_NAISSANCE) FORMAT=DDMMYY8. AS MAX_DATE_NAISSANCE FORMAT=DDMMYY10.,
        MIN(DATE_NAISSANCE) FORMAT=DDMMYY8. AS MIN_DATE_NAISSANCE FORMAT=DDMMYY10.,
        /* NOMBRE DE MODALITES (VARIABLES DISCRETES) */
        COUNT(DISTINCT GENRE)           	AS NB_MOD_GENRE,
        COUNT(DISTINCT A_ETE_PARRAINE)  	AS NB_MOD_A_ETE_PARRAINE,
        COUNT(DISTINCT ACTIF)           	AS NB_MOD_ACTIF,
        COUNT(DISTINCT INSCRIT_NL)      	AS NB_MOD_INSCRIT_NL
    FROM DATA.CLIENTS;
QUIT;
PROC TRANSPOSE DATA = AUDIT_CLIENT
	OUT= AUDIT_CLIENT_AVANT_NETTOYAGE
    (RENAME=(COL1=VALEUR));  RUN;

PROC SQL;
    CREATE TABLE AUDIT_COMMANDES                /*Pour les commandes*/
    AS SELECT
        /* VOLUMETRIE */
        COUNT(*)                                AS NB_LIGNES,
        COUNT(DISTINCT NUMERO_COMMANDE)         AS NB_NUM_COMMANDE_DIFF,
        COUNT(DISTINCT NUM_CLIENT)              AS NB_NUM_CLIENT_DIFF,
        /* PLAGES DES DATES */
        MIN(INPUT(DATE, DATE10.))               AS PLUS_ANCIENNE_COMMANDE FORMAT=DDMMYY10. ,
        MAX(INPUT(DATE, DATE10.))               AS PLUS_RECENTE_COMMANDE FORMAT=DDMMYY10. ,
        /* MONTANT TOTAL */
        MIN(MONTANT_TOTAL_PAYE)                 AS DEPENSE_MINIMUM,
        MAX(MONTANT_TOTAL_PAYE)                 AS DEPENSE_MAXIMUM,
        SUM(MISSING(MONTANT_TOTAL_PAYE))        AS NB_MISSING_MONTANT_TOTAL_PAYE,
        /* VERIFICATION DES MISSINGS ET NEGATIFS DU MONTANT_TOTAL */
        SUM(MISSING(MONTANT_TOTAL_PAYE) AND SUM(MONTANT_DES_PRODUITS, REMISE_SUR_PRODUITS, MONTANT_LIVRAISON, REMISE_SUR_LIVRAISON) = 0) AS NB_ANOMALIE_SOMME_NULLE,
        SUM(MISSING(MONTANT_TOTAL_PAYE) AND MISSING(SUM(MONTANT_DES_PRODUITS, REMISE_SUR_PRODUITS, MONTANT_LIVRAISON, REMISE_SUR_LIVRAISON))) AS NB_ANOMALIE_TOUT_VIDE,
        SUM(COALESCE(MONTANT_TOTAL_PAYE,0) < 0) AS NB_OBS_MONTANT_NEGATIF,   
        /* VERIFICATION COHERENCE (FLAG_MONTANT_CORRECT = 0) */
        SUM(COALESCE(ROUND(SUM(MONTANT_DES_PRODUITS, REMISE_SUR_PRODUITS, MONTANT_LIVRAISON, REMISE_SUR_LIVRAISON), 0.01), 0) 
            NE 
            COALESCE(ROUND(MONTANT_TOTAL_PAYE, 0.01), 0)) AS NB_INCOHERENCE_MONTANT_TOTAL            
    FROM DATA.COMMANDES;
QUIT;
PROC TRANSPOSE DATA = AUDIT_COMMANDES
	OUT= AUDIT_COMMANDES_AVANT_NETTOYAGE
    (RENAME=(COL1=VALEUR));  RUN;
PROC MEANS DATA=DATA.COMMANDES MIN MAX;
    VAR 
        MONTANT_DES_PRODUITS
        MONTANT_TOTAL_PAYE
        REMISE_SUR_PRODUITS
        MONTANT_LIVRAISON
        REMISE_SUR_LIVRAISON;
RUN;


/*--------------------------------------  B. NETTOYAGE  ---------------------------------------*/
%LET FIN_PERIODE=01JAN2023;  /* Car date la plus grande des datasets */

DATA DATA.CLIENTS_CLEAN ;    /* Nettoyage données Clients */
    SET DATA.CLIENTS (RENAME=(VAR3 = DATE_INSCRIPTION));
	/* IMPUTATION VALEURS MANQUANTES */
    IF (MISSING(A_ETE_PARRAINE) OR A_ETE_PARRAINE='?') THEN A_ETE_PARRAINE = 'NR';
	/* CALCUL DE L'AGE (EN ANNEES) */
    AGE=INTCK("YEAR", DATE_NAISSANCE, "&FIN_PERIODE."D);
	/* CREATION DES COLONNES ANNEE,MOIS et MOIS_AN D'INSCRIPTION */
	ANNEE_INSCRIPTION = YEAR(DATE_INSCRIPTION);
	MOIS_INSCRIPTION = MONTH(DATE_INSCRIPTION);
    IF MOIS_INSCRIPTION > 9 THEN
        MOIS_AN_INSCRIPTION = COMPRESS(ANNEE_INSCRIPTION !! "-" !! MOIS_INSCRIPTION);
    ELSE
        MOIS_AN_INSCRIPTION = COMPRESS(ANNEE_INSCRIPTION !! "-0" !! MOIS_INSCRIPTION);
RUN;

DATA DATA.COMMANDES_CLEAN;   /* Nettoyage données Commandes */
    SET DATA.COMMANDES;
    DATE = UPCASE(DATE);
    /* EXTRACTION DES PARTIES (Jour, Mois Texte, Année) */
    JOUR_TXT = SCAN(DATE, 1, '-');
    MOIS_TXT = SCAN(DATE, 2, '-');
    ANNEE_TXT = SCAN(DATE, 3, '-');
	/* MAPPING (Remplacement du texte par le chiffre correspondant) */
    SELECT (MOIS_TXT);
        WHEN ('JANV') MOIS_NUM = 01;
        WHEN ('FÉVR') MOIS_NUM = 02;
        WHEN ('MARS') MOIS_NUM = 03;
        WHEN ('AVR')  MOIS_NUM = 04;
        WHEN ('MAI')  MOIS_NUM = 05;
        WHEN ('JUIN') MOIS_NUM = 06;
        WHEN ('JUIL') MOIS_NUM = 07;
        WHEN ('AOUT') MOIS_NUM = 08;
        WHEN ('SEPT') MOIS_NUM = 09;
        WHEN ('OCT')  MOIS_NUM = 10;
        WHEN ('NOV')  MOIS_NUM = 11;
        WHEN ('DÉC')  MOIS_NUM = 12;
        OTHERWISE MOIS_NUM = .; /* Sécurité si faute de frappe */
    END;
    /* CREATION DE LA NOUVELLE COLONNE DATE */
    IF MOIS_NUM NE . THEN DO;
        DATE_COMMANDE = MDY(MOIS_NUM, JOUR_TXT, ANNEE_TXT);
    END;
	/* GESTION DES VALEURS NEGATIVES ET MANQUANTES POUR LE MONTANT */
	WHERE (MONTANT_TOTAL_PAYE >= 0);  /* On garde uniquement les lignes où le montant total payé existe ET est positif */
    FORMAT DATE_COMMANDE DDMMYY10.;
	DROP DATE JOUR_TXT MOIS_TXT ANNEE_TXT;
RUN;


/*--------------------------------------  C. FUSION SUR BASE COMMUNE  ---------------------------------------*/
PROC SQL;
    CREATE TABLE DATA.VENTES AS
    SELECT 
        T1.*,       	/* On garde tout de la table COMMANDES */
        T2.ACTIF,       /* On sélectionne les infos CLIENTS utiles */
        T2.DATE_INSCRIPTION,
		T2.INSCRIT_NL,
		T2.A_ETE_PARRAINE,
		T2.GENRE,
		T2.AGE,
        T2.MOIS_AN_INSCRIPTION
    FROM DATA.COMMANDES_CLEAN AS T1
    LEFT JOIN DATA.CLIENTS_CLEAN AS T2 /* Ainsi, seulement les clients ayant commandé seront segmentés */
    ON T1.NUM_CLIENT = T2.NUM_CLIENT;
QUIT;
/* EXPORT VERS CSV */
PROC EXPORT DATA = DATA.VENTES
    OUTFILE="C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL\ventes.xlsx"
    DBMS=XLSX REPLACE;
RUN;
