/*************************************************************************************************/
/***********************************  PROJET SEGMENTATION RFM  ***********************************/
/*************************************************************************************************/
/*                                                                                                 */
/*   Bundle: t004_indicateurs_rfm                                                                  */
/*   Adapté depuis PGM/3_Construction_analyse_indicateurs_RFM.sas                                  */
/*                                                                                                 */
/*   Le script construit pour chaque client les trois indicateurs RFM :                            */
/*     - RÉCENCE   : nombre de mois depuis la dernière commande (au 01JAN2023)                     */
/*     - FRÉQUENCE : nombre de commandes distinctes sur la période 2021-2022                       */
/*     - MONTANT   : panier moyen                                                                   */
/*   Puis classe les clients en déciles de montant via PROC RANK.                                  */
/*                                                                                                 */
/*   La table WORK.COMMANDES est préchargée par autoexec.sas (échantillon ~80 commandes).          */
/*   Adaptation : INTCK et YEAR sont calculés dans l'étape DATA, hors clause aggregate PROC SQL.   */
/*-----------------------------------------------------------------------------------------------*/
/*                          CONSTRUCTION DES INDICATEURS R-F-M                                    */
/*-----------------------------------------------------------------------------------------------*/

DATA WORK.COMMANDES_CLEAN;
    SET WORK.COMMANDES;
    DATE_UP = UPCASE(date);
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
    /* Précalcul du nombre de mois jusqu'à la fin de période et de l'année (cf. adaptation) */
    MOIS_BACK = INTCK('month', DATE_COMMANDE, '01JAN2023'd);
    ANNEE_COM = YEAR(DATE_COMMANDE);
    WHERE (montant_total_paye >= 0);
    FORMAT DATE_COMMANDE DDMMYY10.;
    DROP DATE_UP JOUR_TXT MOIS_TXT ANNEE_TXT;
RUN;

/* Construction des indicateurs RFM par client sur la période 2021-2022 */
PROC SQL;
    CREATE TABLE INDICATEURS_RFM AS
        SELECT
            num_client,
            MIN(MOIS_BACK)                                   AS RECENCE,
            COUNT(DISTINCT numero_commande)                  AS FREQUENCE,
            MEAN(montant_total_paye)                         AS MONTANT
        FROM WORK.COMMANDES_CLEAN
        WHERE ANNEE_COM BETWEEN 2021 AND 2022
        GROUP BY num_client;
QUIT;

/* Aperçu */
PROC PRINT DATA=INDICATEURS_RFM (OBS=10);
    TITLE "Indicateurs RFM — extrait (10 premiers clients)";
RUN;

/* Décile de montant via PROC RANK */
PROC RANK DATA=INDICATEURS_RFM
    OUT=RANG_MONTANT
    GROUPS=10;
    VAR MONTANT;
    RANKS RANG;
RUN;

/* Bornes par décile */
PROC SUMMARY DATA=RANG_MONTANT;
    CLASS RANG;
    VAR MONTANT;
    OUTPUT OUT=MONTANT_10_RANG
        MIN=MONTANT_MIN
        MAX=MONTANT_MAX;
RUN;

PROC PRINT DATA=MONTANT_10_RANG;
    TITLE "Bornes de montant par décile";
RUN;
