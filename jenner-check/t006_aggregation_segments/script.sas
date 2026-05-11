/*************************************************************************************************/
/***********************************  PROJET SEGMENTATION RFM  ***********************************/
/*************************************************************************************************/
/*                                                                                                 */
/*   Bundle: t006_aggregation_segments                                                             */
/*   Adapté depuis PGM/5_Rapport_et_Visuels_RFM.sas                                                */
/*                                                                                                 */
/*   Le script agrège la clientèle par segment RFM final pour calculer effectifs, CA total,        */
/*   ARPU, et distribution par âge / ancienneté / genre / inscription newsletter.                  */
/*                                                                                                 */
/*   Les tables WORK.CLIENTS et WORK.COMMANDES sont préchargées par autoexec.sas.                  */
/*   Adaptations :                                                                                 */
/*     - les dates sont parsées explicitement (INPUT/MDY) car arrivant en chaînes du CSV ;         */
/*     - INTCK/YEAR sont calculés en étape DATA avant agrégation ;                                 */
/*     - les SUM(condition) deviennent SUM(CASE WHEN ... THEN 1 ELSE 0 END).                       */
/*-----------------------------------------------------------------------------------------------*/
/*                          AGGREGATION PAR SEGMENT RFM                                            */
/*-----------------------------------------------------------------------------------------------*/

DATA WORK.CLIENTS_CLEAN;
    SET WORK.CLIENTS (RENAME=(date_creation_compte = DATE_INSCR_STR
                              date_naissance       = DATE_NAISS_STR));
    DATE_INSCRIPTION = INPUT(DATE_INSCR_STR, DDMMYY10.);
    DATE_NAISSANCE   = INPUT(DATE_NAISS_STR, DDMMYY10.);
    FORMAT DATE_INSCRIPTION DATE_NAISSANCE DDMMYY10.;
    IF (MISSING(A_ete_parraine) OR A_ete_parraine='?') THEN A_ete_parraine = 'NR';
    AGE = INTCK("YEAR", DATE_NAISSANCE, '01JAN2023'D);
    DROP DATE_INSCR_STR DATE_NAISS_STR;
RUN;

DATA WORK.COMMANDES_CLEAN;
    SET WORK.COMMANDES;
    DATE_UP   = UPCASE(date);
    JOUR_TXT  = SCAN(DATE_UP, 1, '-');
    MOIS_TXT  = SCAN(DATE_UP, 2, '-');
    ANNEE_TXT = SCAN(DATE_UP, 3, '-');
    SELECT (MOIS_TXT);
        WHEN ('JANV') MOIS_NUM = 1;
        WHEN ('FÉVR') MOIS_NUM = 2;
        WHEN ('MARS') MOIS_NUM = 3;
        WHEN ('AVR')  MOIS_NUM = 4;
        WHEN ('MAI')  MOIS_NUM = 5;
        WHEN ('JUIN') MOIS_NUM = 6;
        WHEN ('JUIL') MOIS_NUM = 7;
        WHEN ('AOUT') MOIS_NUM = 8;
        WHEN ('SEPT') MOIS_NUM = 9;
        WHEN ('OCT')  MOIS_NUM = 10;
        WHEN ('NOV')  MOIS_NUM = 11;
        WHEN ('DÉC')  MOIS_NUM = 12;
        OTHERWISE     MOIS_NUM = .;
    END;
    IF MOIS_NUM NE . THEN
        DATE_COMMANDE = MDY(MOIS_NUM, INPUT(JOUR_TXT, 8.), 2000 + INPUT(ANNEE_TXT, 8.));
    /* Précalculs avant agrégation PROC SQL */
    MOIS_BACK = INTCK('month', DATE_COMMANDE, '01JAN2023'd);
    ANNEE_COM = YEAR(DATE_COMMANDE);
    WHERE (montant_total_paye >= 0);
    DROP DATE_UP JOUR_TXT MOIS_TXT ANNEE_TXT;
RUN;

/* Fusion ventes pour avoir les attributs client */
PROC SQL;
    CREATE TABLE WORK.VENTES AS
    SELECT
        T1.*,
        T2.actif,
        T2.DATE_INSCRIPTION,
        T2.inscrit_NL,
        T2.A_ete_parraine,
        T2.Genre,
        T2.AGE
    FROM WORK.COMMANDES_CLEAN AS T1
    LEFT JOIN WORK.CLIENTS_CLEAN AS T2
        ON T1.num_client = T2.num_client;
QUIT;

PROC SQL;
    CREATE TABLE INDICATEURS_RFM AS
        SELECT
            num_client,
            MIN(MOIS_BACK)                                   AS RECENCE,
            COUNT(DISTINCT numero_commande)                  AS FREQUENCE,
            MEAN(montant_total_paye)                         AS MONTANT
        FROM WORK.VENTES
        WHERE ANNEE_COM BETWEEN 2021 AND 2022
        GROUP BY num_client;
QUIT;

PROC SQL;
    CREATE TABLE APPLICATION_SEUIL AS
        SELECT
            num_client, RECENCE, FREQUENCE, MONTANT,
            CASE WHEN RECENCE <= 6  THEN "R3"
                 WHEN RECENCE <= 12 THEN "R2"
                 WHEN RECENCE >  12 THEN "R1"
                 ELSE "?" END AS SEG_RECENCE,
            CASE WHEN FREQUENCE = 1  THEN "F1"
                 WHEN FREQUENCE <= 3 THEN "F2"
                 WHEN FREQUENCE >  3 THEN "F3"
                 ELSE "?" END AS SEG_FREQUENCE,
            CASE WHEN MONTANT <  50  THEN "M1"
                 WHEN MONTANT <  100 THEN "M2"
                 WHEN MONTANT >= 100 THEN "M3"
                 ELSE "?" END AS SEG_MONTANT
        FROM INDICATEURS_RFM;
QUIT;

DATA APPLICATION_SEUIL_RF;
    SET APPLICATION_SEUIL;
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

DATA SEGMENT_RFM;
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

/*-----------------------------------------------------------------------------------------------*/
/*  CLIENTELE_RFM : enrichissement de la clientèle avec son segment et son CA total              */
/*-----------------------------------------------------------------------------------------------*/
PROC SQL;
    CREATE TABLE CLIENTELE_RFM AS
    SELECT
        A.num_client,
        actif,
        inscrit_NL,
        Genre,
        A_ete_parraine,
        MAX(AGE)                         AS AGE,
        SUM(montant_total_paye)          AS CA_TOTAL,
        AVG(montant_total_paye)          AS CA_MOYEN,
        COUNT(DISTINCT numero_commande)  AS NB_COMMANDES,
        DATE_INSCRIPTION,
        B.SEG_RFM
    FROM WORK.VENTES AS A
    LEFT JOIN SEGMENT_RFM AS B
        ON A.num_client = B.num_client
    GROUP BY A.num_client, actif, A_ete_parraine, inscrit_NL, Genre, DATE_INSCRIPTION, B.SEG_RFM;
QUIT;

/*-----------------------------------------------------------------------------------------------*/
/*  AGGREGATION_SEGMENTS_RFM : KPIs par segment final                                            */
/*-----------------------------------------------------------------------------------------------*/
PROC SQL;
    CREATE TABLE AGGREGATION_SEGMENTS_RFM AS
    SELECT
        SEG_RFM,
        COUNT(*)                                                              AS EFFECTIF,
        SUM(CASE WHEN Genre = "Homme" THEN 1 ELSE 0 END)                      AS HOMMES,
        SUM(CASE WHEN Genre = "Femme" THEN 1 ELSE 0 END)                      AS FEMMES,
        SUM(CASE WHEN AGE >= 0  AND AGE <= 25 THEN 1 ELSE 0 END)              AS AGE_MOINS_DE_25,
        SUM(CASE WHEN AGE >  25 AND AGE <= 35 THEN 1 ELSE 0 END)              AS AGE_25_35_ANS,
        SUM(CASE WHEN AGE >  35 AND AGE <= 45 THEN 1 ELSE 0 END)              AS AGE_35_45_ANS,
        SUM(CASE WHEN AGE >  45 AND AGE <= 55 THEN 1 ELSE 0 END)              AS AGE_45_55_ANS,
        SUM(CASE WHEN AGE >  55 AND AGE <= 65 THEN 1 ELSE 0 END)              AS AGE_55_65_ANS,
        SUM(CASE WHEN AGE >  65 THEN 1 ELSE 0 END)                            AS AGE_PLUS_DE_65_ANS,
        SUM(inscrit_NL)                                                       AS INSCRITS_NL,
        SUM(CA_TOTAL)                                                         AS CA_TOTAL_SEG,
        AVG(CA_TOTAL)                                                         AS ARPU,
        AVG(NB_COMMANDES)                                                     AS NB_COMMANDES_MOYEN
    FROM CLIENTELE_RFM
    GROUP BY SEG_RFM;
QUIT;

PROC PRINT DATA=AGGREGATION_SEGMENTS_RFM;
    TITLE "KPIs par segment RFM";
RUN;
