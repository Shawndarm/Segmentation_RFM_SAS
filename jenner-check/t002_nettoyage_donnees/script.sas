/*************************************************************************************************/
/***********************************  PROJET SEGMENTATION RFM  ***********************************/
/*************************************************************************************************/
/*                                                                                                 */
/*   Bundle: t002_nettoyage_donnees                                                                */
/*   Adapté depuis la partie nettoyage de PGM/1_Audit_Nettoyage_données.sas                        */
/*                                                                                                 */
/*   Le script transforme la date au format "DD-mois-YY" (ex: 05-mars-21) en date SAS              */
/*   via SCAN + SELECT/WHEN, et impute les valeurs manquantes du parrainage.                       */
/*                                                                                                 */
/*   Les tables WORK.CLIENTS et WORK.COMMANDES sont préchargées par autoexec.sas (25 clients +     */
/*   ~80 commandes). Les dates clients arrivent comme chaînes ; converties via INPUT(...).         */
/*-----------------------------------------------------------------------------------------------*/
/*                          NETTOYAGE — CLIENTS ET COMMANDES                                      */
/*-----------------------------------------------------------------------------------------------*/

%LET FIN_PERIODE = 01JAN2023;

/* Nettoyage CLIENTS — imputation NR, calcul âge, extraction mois/année d'inscription */
DATA WORK.CLIENTS_CLEAN;
    SET WORK.CLIENTS (RENAME=(date_creation_compte = DATE_INSCR_STR
                              date_naissance       = DATE_NAISS_STR));
    /* Conversion des chaînes dd/mm/yyyy -> dates SAS */
    DATE_INSCRIPTION = INPUT(DATE_INSCR_STR, DDMMYY10.);
    DATE_NAISSANCE   = INPUT(DATE_NAISS_STR, DDMMYY10.);
    FORMAT DATE_INSCRIPTION DATE_NAISSANCE DDMMYY10.;
    /* Imputation valeurs manquantes du parrainage */
    IF (MISSING(A_ete_parraine) OR A_ete_parraine='?') THEN A_ete_parraine = 'NR';
    /* Calcul de l'âge en années */
    AGE = INTCK("YEAR", DATE_NAISSANCE, "&FIN_PERIODE."D);
    /* Création des colonnes ANNEE, MOIS et MOIS_AN d'inscription */
    ANNEE_INSCRIPTION = YEAR(DATE_INSCRIPTION);
    MOIS_INSCRIPTION  = MONTH(DATE_INSCRIPTION);
    IF MOIS_INSCRIPTION > 9 THEN
        MOIS_AN_INSCRIPTION = COMPRESS(ANNEE_INSCRIPTION !! "-" !! MOIS_INSCRIPTION);
    ELSE
        MOIS_AN_INSCRIPTION = COMPRESS(ANNEE_INSCRIPTION !! "-0" !! MOIS_INSCRIPTION);
    DROP DATE_INSCR_STR DATE_NAISS_STR;
RUN;

/* Nettoyage COMMANDES — parsing de la date au format "DD-mois-YY" via SCAN + SELECT/WHEN */
DATA WORK.COMMANDES_CLEAN;
    SET WORK.COMMANDES;
    DATE_UP = UPCASE(date);
    /* Extraction des parties Jour, Mois texte, Année */
    JOUR_TXT  = SCAN(DATE_UP, 1, '-');
    MOIS_TXT  = SCAN(DATE_UP, 2, '-');
    ANNEE_TXT = SCAN(DATE_UP, 3, '-');
    /* Mapping mois texte -> numéro */
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
    /* Recomposition de la date */
    IF MOIS_NUM NE . THEN DO;
        DATE_COMMANDE = MDY(MOIS_NUM, INPUT(JOUR_TXT, 8.), 2000 + INPUT(ANNEE_TXT, 8.));
    END;
    /* On garde uniquement les lignes avec montant positif */
    WHERE (montant_total_paye >= 0);
    FORMAT DATE_COMMANDE DDMMYY10.;
    DROP date DATE_UP JOUR_TXT MOIS_TXT ANNEE_TXT;
RUN;

PROC PRINT DATA=WORK.CLIENTS_CLEAN (OBS=5);
    TITLE "Clients nettoyés — extrait";
RUN;
PROC PRINT DATA=WORK.COMMANDES_CLEAN (OBS=5);
    TITLE "Commandes nettoyées — extrait";
RUN;
