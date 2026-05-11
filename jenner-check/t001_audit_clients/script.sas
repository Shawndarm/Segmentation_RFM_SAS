/*************************************************************************************************/
/***********************************  PROJET SEGMENTATION RFM  ***********************************/
/*************************************************************************************************/
/*                                                                                                 */
/*   Bundle: t001_audit_clients                                                                    */
/*   Adapté depuis la partie audit de PGM/1_Audit_Nettoyage_données.sas                            */
/*                                                                                                 */
/*   Le script d'origine fait un audit qualité sur les tables CLIENTS et COMMANDES                 */
/*   (volumétrie, valeurs manquantes, plages de dates, nombre de modalités).                       */
/*                                                                                                 */
/*   La table WORK.CLIENTS est préchargée par autoexec.sas (échantillon de 25 clients).            */
/*-----------------------------------------------------------------------------------------------*/
/*                          AUDIT PREALABLE — TABLE CLIENTS                                       */
/*-----------------------------------------------------------------------------------------------*/

/* Audit qualité sur la base CLIENTS */
PROC SQL;
    CREATE TABLE AUDIT_CLIENT AS SELECT
        /* VOLUMETRIE */
        COUNT(*)                                                       AS NB_LIGNES,
        COUNT(DISTINCT num_client)                                     AS NB_NUM_CLIENTS,
        /* VALEURS MANQUANTES */
        SUM(CASE WHEN num_client     IS NULL THEN 1 ELSE 0 END)        AS NB_MISSING_NUM_CLIENT,
        SUM(CASE WHEN actif          IS NULL THEN 1 ELSE 0 END)        AS NB_MISSING_ACTIF,
        SUM(CASE WHEN A_ete_parraine IS NULL THEN 1 ELSE 0 END)        AS NB_MISSING_A_ETE_PARRAINE,
        SUM(CASE WHEN Genre          IS NULL THEN 1 ELSE 0 END)        AS NB_MISSING_GENRE,
        SUM(CASE WHEN date_naissance IS NULL THEN 1 ELSE 0 END)        AS NB_MISSING_DATE_NAISSANCE,
        SUM(CASE WHEN inscrit_NL     IS NULL THEN 1 ELSE 0 END)        AS NB_MISSING_INSCRIT_NL,
        /* NOMBRE DE MODALITES (VARIABLES DISCRETES) */
        COUNT(DISTINCT Genre)                                          AS NB_MOD_GENRE,
        COUNT(DISTINCT A_ete_parraine)                                 AS NB_MOD_A_ETE_PARRAINE,
        COUNT(DISTINCT actif)                                          AS NB_MOD_ACTIF,
        COUNT(DISTINCT inscrit_NL)                                     AS NB_MOD_INSCRIT_NL
    FROM WORK.CLIENTS;
QUIT;

/* Transposition pour avoir un rapport vertical */
PROC TRANSPOSE DATA=AUDIT_CLIENT
    OUT=AUDIT_CLIENT_AVANT_NETTOYAGE
    (RENAME=(COL1=VALEUR));
RUN;

PROC PRINT DATA=AUDIT_CLIENT_AVANT_NETTOYAGE;
    TITLE "Audit qualité — Table CLIENTS";
RUN;
