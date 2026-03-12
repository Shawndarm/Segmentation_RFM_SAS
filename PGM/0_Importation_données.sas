/*************************************************************************************************/
/***********************************  PROJET SEGMENTATION RFM  ***********************************/
/*************************************************************************************************/

/*-----------------------------------------------------------------------------------------------*/
/*                                  0. IMPORTATION DES DONNES                                    */
/*-----------------------------------------------------------------------------------------------*/

/*--------------------------------------  INITIALISATION  ---------------------------------------*/

LIBNAME DATA "C:\Users\dutau\Desktop\SAS S1\Projet\DATA\SAS";
LIBNAME RESUS "C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\SAS";
LIBNAME RESUX "C:\Users\dutau\Desktop\SAS S1\Projet\RESULT\EXCEL";


/*-------------------------------------  IMPORT DES DONNEES  ------------------------------------*/

*IMPORTATION DU FICHIER CLIENTS.CSV;
PROC IMPORT
    DATAFILE="C:\USERS\DUTAU\DESKTOP\SAS S1\PROJET\DATA\RAW\CLIENTS.CSV"
    OUT=DATA.CLIENTS
    DBMS=CSV
    REPLACE;
	DELIMITER=';';   *C'est le délimiteur des colonnes du fichier csv ;
    GETNAMES=YES;
RUN;
*IMPORTATION DU FICHIER COMMANDES.CSV;
PROC IMPORT
    DATAFILE="C:\USERS\DUTAU\DESKTOP\SAS S1\PROJET\DATA\RAW\COMMANDES.CSV"
    OUT=DATA.COMMANDES /*On crée donc des tables SAS à partir des fichiers CSV*/
    DBMS=CSV
    REPLACE;
	DELIMITER=';';   *C'est le délimiteur des colonnes du fichier csv;
    GETNAMES=YES;
RUN;


/*-------------------------------------  CONTENU DES DONNEES  ------------------------------------*/

PROC CONTENTS DATA=DATA.CLIENTS;
RUN;  *Pour obtenir des infos sur les attributs et varaibles;
PROC CONTENTS DATA=DATA.COMMANDES;
RUN;


