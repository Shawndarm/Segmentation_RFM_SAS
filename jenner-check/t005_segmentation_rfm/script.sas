/*************************************************************************************************/
/***********************************  PROJET SEGMENTATION RFM  ***********************************/
/*************************************************************************************************/
/*                                                                                                 */
/*   Bundle: t005_segmentation_rfm                                                                 */
/*   Adapté depuis PGM/4_Contruction_segmentation_RFM.sas                                          */
/*                                                                                                 */
/*   À partir des indicateurs RFM (récence, fréquence, montant), le script applique des seuils     */
/*   pour produire les segments R1-R3, F1-F3, M1-M3, puis combine en RF1-RF3 (matrice 3x3 avec     */
/*   regroupements), puis en 9 segments RFM finaux.                                                */
/*                                                                                                 */
/*   La table WORK.COMMANDES est préchargée par autoexec.sas (échantillon ~80 commandes).          */
/*-----------------------------------------------------------------------------------------------*/
/*                          SEGMENTATION RFM                                                       */
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
    /* Précalculs pour la suite (INTCK et YEAR appliqués hors PROC SQL) */
    MOIS_BACK = INTCK('month', DATE_COMMANDE, '01JAN2023'd);
    ANNEE_COM = YEAR(DATE_COMMANDE);
    WHERE (montant_total_paye >= 0);
    DROP DATE_UP JOUR_TXT MOIS_TXT ANNEE_TXT;
RUN;

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

/*-----------------------------------------------------------------------------------------------*/
/*  A. APPLICATION DES REGLES DE DECOUPAGES RFM                                                  */
/*-----------------------------------------------------------------------------------------------*/
PROC SQL;
    CREATE TABLE APPLICATION_SEUIL AS
        SELECT
            num_client,
            RECENCE,
            FREQUENCE,
            MONTANT,
            /* Segmentation Récence : R3 = récent, R2 = actif, R1 = inactif */
            CASE
                WHEN RECENCE <= 6  THEN "R3"
                WHEN RECENCE <= 12 THEN "R2"
                WHEN RECENCE >  12 THEN "R1"
                ELSE "?"
            END AS SEG_RECENCE,
            /* Segmentation Fréquence : F1 = occasionnel, F2 = régulier, F3 = fidèle */
            CASE
                WHEN FREQUENCE = 1  THEN "F1"
                WHEN FREQUENCE <= 3 THEN "F2"
                WHEN FREQUENCE > 3  THEN "F3"
                ELSE "?"
            END AS SEG_FREQUENCE,
            /* Segmentation Montant : M1 < 50€, M2 = 50-100€, M3 >= 100€ */
            CASE
                WHEN MONTANT < 50    THEN "M1"
                WHEN MONTANT < 100   THEN "M2"
                WHEN MONTANT >= 100  THEN "M3"
                ELSE "?"
            END AS SEG_MONTANT
        FROM INDICATEURS_RFM;
QUIT;

PROC FREQ DATA=APPLICATION_SEUIL;
    TABLES SEG_RECENCE SEG_FREQUENCE SEG_MONTANT;
    TITLE "Distribution des segments R, F et M";
RUN;

/*-----------------------------------------------------------------------------------------------*/
/*  B. CONSTRUCTION DES SEGMENTS RF (3 groupes via combinaison RxF)                               */
/*-----------------------------------------------------------------------------------------------*/
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

PROC FREQ DATA=APPLICATION_SEUIL_RF;
    TABLES SEG_RF;
    TITLE "Distribution des 3 segments RF";
RUN;

/*-----------------------------------------------------------------------------------------------*/
/*  C. CONSTRUCTION DES 9 SEGMENTS RFM FINAUX                                                    */
/*-----------------------------------------------------------------------------------------------*/
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

PROC FREQ DATA=SEGMENT_RFM;
    TABLES SEG_RFM;
    TITLE "Distribution des 9 segments RFM finaux";
RUN;
