/*************************************************************************************************/
/***********************************  PROJET SEGMENTATION RFM  ***********************************/
/*************************************************************************************************/
/*                                                                                                 */
/*   Bundle: t003_analyse_descriptive                                                              */
/*   Adapté depuis PGM/2_Analyse_descriptive.sas                                                   */
/*                                                                                                 */
/*   Le script résume la base clients : effectifs par genre, par tranche d'âge, et calcule l'âge   */
/*   moyen. Originalement l'auteur produit aussi une PROC FREQ sur le mois-année d'inscription.    */
/*                                                                                                 */
/*   La table WORK.CLIENTS est préchargée par autoexec.sas (échantillon 25 clients).               */
/*   Adaptations : les SUM(condition) sont reformulés en SUM(CASE WHEN ... THEN 1 ELSE 0 END) ;    */
/*   les dates arrivent en chaînes (CSV d'origine) et sont parsées via INPUT(..., DDMMYY10.).      */
/*-----------------------------------------------------------------------------------------------*/
/*                          ANALYSE DESCRIPTIVE DES CLIENTS                                       */
/*-----------------------------------------------------------------------------------------------*/

DATA WORK.CLIENTS_CLEAN;
    SET WORK.CLIENTS (RENAME=(date_naissance = DATE_NAISS_STR));
    /* La date arrive en chaîne depuis le CSV — conversion explicite */
    DATE_NAISSANCE = INPUT(DATE_NAISS_STR, DDMMYY10.);
    AGE = INTCK("YEAR", DATE_NAISSANCE, '01JAN2023'D);
    FORMAT DATE_NAISSANCE DDMMYY10.;
    DROP DATE_NAISS_STR;
RUN;

/* Caractéristiques de la base clients */
PROC SQL;
    CREATE TABLE CARAC_CLIENTS AS
    SELECT
        COUNT(DISTINCT num_client)                                          AS NB_CLIENTS,
        SUM(CASE WHEN actif      = 1       THEN 1 ELSE 0 END)               AS COMPTE_OUVERT,
        SUM(CASE WHEN inscrit_NL = 1       THEN 1 ELSE 0 END)               AS INSCRIT_NL,
        SUM(CASE WHEN Genre      = "Femme" THEN 1 ELSE 0 END)               AS NB_FEMMES,
        SUM(CASE WHEN Genre      = "Homme" THEN 1 ELSE 0 END)               AS NB_HOMMES,
        SUM(CASE WHEN AGE IS NULL          THEN 1 ELSE 0 END)               AS AGE_INCONNU,
        SUM(CASE WHEN AGE >= 0  AND AGE <= 25 THEN 1 ELSE 0 END)            AS AGE_MOINS_DE_25,
        SUM(CASE WHEN AGE >  25 AND AGE <= 35 THEN 1 ELSE 0 END)            AS AGE_25_35_ANS,
        SUM(CASE WHEN AGE >  35 AND AGE <= 45 THEN 1 ELSE 0 END)            AS AGE_35_45_ANS,
        SUM(CASE WHEN AGE >  45 AND AGE <= 55 THEN 1 ELSE 0 END)            AS AGE_45_55_ANS,
        SUM(CASE WHEN AGE >  55 AND AGE <= 65 THEN 1 ELSE 0 END)            AS AGE_55_65_ANS,
        SUM(CASE WHEN AGE >  65               THEN 1 ELSE 0 END)            AS AGE_PLUS_DE_65_ANS,
        AVG(AGE)                                                            AS AGE_MOYEN
    FROM WORK.CLIENTS_CLEAN;
QUIT;

/* Transposition pour rapport vertical */
PROC TRANSPOSE DATA=CARAC_CLIENTS
    OUT=CARAC_CLIENTS_T (RENAME=(COL1=VALEUR));
RUN;

PROC PRINT DATA=CARAC_CLIENTS_T;
    TITLE "Caractéristiques de la base clients";
RUN;

/* Répartition par genre */
PROC FREQ DATA=WORK.CLIENTS_CLEAN;
    TABLES Genre / NOCUM;
    TITLE "Répartition par genre";
RUN;
