options obs=100;
/*-----------------------------------------------------------------------------*/
/*  Sample data — 25 clients tirés au sort du fichier original DATA/RAW/      */
/*  clients.csv (4196 clients). Mêmes colonnes que l'original, format texte    */
/*  pour les dates (parsé via INPUT(..., DDMMYY10.) dans les scripts).        */
/*-----------------------------------------------------------------------------*/

data WORK.CLIENTS;
    length num_client $10 actif 8 date_creation_compte $10 A_ete_parraine $4 Genre $5 date_naissance $10 inscrit_NL 8;
    infile datalines dsd dlm=';';
    input num_client $ actif date_creation_compte $ A_ete_parraine $ Genre $ date_naissance $ inscrit_NL;
    datalines;
ID_99599;1;21/02/2016;OUI;Femme;23/09/1963;1
ID_407165;1;28/09/2018;NON;Homme;01/08/1975;1
ID_604458;1;22/07/2021;OUI;Femme;16/11/1966;1
ID_253433;1;26/02/2017;OUI;Femme;13/01/1950;1
ID_109694;1;05/05/2016;OUI;Femme;09/03/1954;1
ID_481741;1;05/11/2019;OUI;Homme;06/10/1968;1
ID_467536;1;26/09/2019;OUI;Femme;14/08/1981;1
ID_269388;1;03/03/2017;OUI;Femme;13/10/1952;1
ID_103666;1;26/03/2016;OUI;Femme;07/01/1978;1
ID_102825;1;19/03/2016;OUI;Femme;06/10/1978;1
ID_185379;1;02/12/2016;OUI;Femme;19/10/1956;1
ID_361382;1;01/04/2018;OUI;Femme;16/05/1964;1
ID_346920;1;27/10/2017;NON;Homme;07/01/1980;1
ID_215769;1;17/01/2017;OUI;Homme;08/02/1962;1
ID_107762;1;21/04/2016;NON;Homme;15/07/1968;1
ID_335865;1;02/09/2017;OUI;Femme;27/10/1975;1
ID_373928;1;27/06/2018;OUI;Homme;16/07/1950;1
ID_162078;1;05/11/2016;OUI;Femme;12/06/1955;1
ID_217164;1;19/01/2017;OUI;Femme;29/06/1968;1
ID_198083;1;08/01/2017;;Femme;30/10/1949;0
ID_254487;1;26/02/2017;;Homme;14/04/1974;0
ID_343543;1;14/09/2017;OUI;Femme;24/07/1982;1
ID_104339;1;26/03/2016;OUI;Femme;28/02/1968;1
ID_203619;1;13/01/2017;OUI;Homme;14/11/1949;1
ID_435560;1;16/04/2019;OUI;Femme;16/02/1955;1
;
run;
