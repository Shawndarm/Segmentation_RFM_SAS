# Projet CRM — Segmentation RFM

> **Master MoSEF** — Université Paris 1 Panthéon-Sorbonne
> Réalisé par **Roland Dutauziet**, **Maeva N'Guessan** et **Lina Ragala**

---

## Présentation

Ce projet s'inscrit dans une démarche CRM visant à segmenter la clientèle d'une entreprise à l'aide de la méthode **RFM (Récence, Fréquence, Montant)**. À partir de données clients et commandes brutes, l'objectif est de produire une segmentation opérationnelle permettant d'orienter les actions marketing selon le profil de chaque client.

L'analyse couvre la période **01/01/2021 – 31/12/2022** et porte sur **4 196 clients** pour un CA total de **1,19M€**.

---

## Structure du projet
```
projet-segmentation-rfm/
│
├── DATA/
│   ├── RAW/
│   │   ├── clients.csv
│   │   └── commandes.csv
│   └── SAS/
│       ├── clients.sas7bdat
│       ├── clients_clean.sas7bdat
│       ├── commandes.sas7bdat
│       ├── commandes_clean.sas7bdat
│       └── ventes.sas7bdat
│
├── PGM/
│   ├── 0_Importation_données.sas
│   ├── 1_Audit_Nettoyage_données.sas
│   ├── 2_Analyse_descriptive.sas
│   ├── 3_Construction_analyse_indicateurs.sas
│   ├── 4_Construction_segmentation_RFM.sas
│   └── 5_Rapport_et_Visuels_RFM.sas
│
├── RESULT/
│   ├── EXCEL/
│   │   ├── 02_Analyse_descriptive_rapport.xlsx
│   │   ├── 03_Construction_Analyse_indicateurs.xlsx
│   │   ├── 04_Construction_Segmentation.xlsx
│   │   ├── 05_Présentation_résultats_rapport.xlsx
│   │   ├── data_rapport.xlsx.bak
│   │   ├── ventes.xlsx
│   │   └── ventes.xlsx.bak
│   └── SAS/
│       ├── aggregation_segments_rfm.sas7bdat
│       ├── application_seuil.sas7bdat
│       ├── clientele_rfm.sas7bdat
│       ├── indicateurs_rfm.sas7bdat
│       └── segment_rfm.sas7bdat
│
├── Segmentation_RFM_Roland_Maeva_Lina.pdf
├── pbi_segmentation.pbix
└── README.md
```

---

## Sommaire de l'analyse

1. Audit des données
2. Analyse descriptive des clients
3. Construction et analyse des indicateurs RFM
   - Analyse de la récence
   - Analyse de la fréquence
   - Analyse du montant
4. Construction de la segmentation
5. Présentation des résultats

---

## Méthodologie

### 1. Audit des données

- **Clients** : bonne qualité globale, quelques anomalies sur les dates et le parrainage
- **Commandes** : structure fiable, montants parfois incohérents ou manquants
- **Nettoyage** : renommage, imputation, calcul de l'âge, normalisation des dates, correction des montants
- **Fusion** : création de la table `VENTES` par jointure client, enrichie avec les attributs clients

### 2. Analyse descriptive

| Indicateur | Valeur |
|------------|--------|
| Nombre de clients | 4 196 |
| Nombre de commandes | 11 100 |
| Fréquence moyenne | 2,65 |
| Panier moyen | 106,59 € |
| CA total | 1,19 M€ |

La clientèle est majoritairement féminine (81,18 %) et concentrée dans la tranche 45–55 ans (30,80 %).

### 3. Indicateurs RFM

**Récence** — nombre de mois depuis la dernière commande :

| Segment | Seuil | Description |
|---------|-------|-------------|
| R3 | <= 6 mois | Clients récents |
| R2 | 6–12 mois | Clients actifs sur l'année |
| R1 | > 12 mois | Clients inactifs |

**Fréquence** — nombre d'achats :

| Segment | Seuil | Description |
|---------|-------|-------------|
| F1 | = 1 achat | Clients occasionnels |
| F2 | 2–3 achats | Clients réguliers |
| F3 | > 3 achats | Clients fidèles |

**Montant** — panier moyen par décile :

| Segment | Seuil | Description |
|---------|-------|-------------|
| M1 | < 50 € | Petits paniers (déciles 1–4) |
| M2 | 50–100 € | Paniers moyens (déciles 4–7) |
| M3 | > 100 € | Forte valeur (déciles 7–10) |

### 4. Segmentation RF

Le croisement Récence × Fréquence produit trois grands groupes :

| Segment | Description | Part |
|---------|-------------|------|
| RF1 | Inactifs / Faible potentiel | 34,51 % |
| RF2 | Clients standards / À développer | 32,79 % |
| RF3 | Actifs / Premium | 32,70 % |

### 5. Résultats — 9 segments RFM

| Segment | Nb clients | CA Total | ARPU | Fréq. moy. | Description |
|---------|------------|----------|------|------------|-------------|
| RFM1 | 604 | 27 031 € | 45 € | 1,41 | Anciens clients ayant peu dépensé |
| RFM2 | 406 | 44 919 € | 111 € | 1,55 | Anciens clients standards |
| RFM3 | 438 | 144 791 € | 331 € | 1,55 | Anciens gros clients en churn |
| RFM4 | 543 | 31 792 € | 59 € | 1,75 | Clients réguliers, petits paniers |
| RFM5 | 413 | 65 150 € | 158 € | 2,16 | Client type, panier moyen |
| RFM6 | 420 | 193 345 € | 460 € | 2,15 | Clients à fort pouvoir d'achat |
| RFM7 | 356 | 54 466 € | 153 € | 4,13 | Fidèles mais petits paniers |
| RFM8 | 499 | 169 808 € | 340 € | 4,69 | Très bons clients |
| RFM9 | 517 | 454 311 € | 879 € | 4,64 | VIP / Elite — traitement privilégié |

---

## Outils utilisés

- **Langage :** SAS
- **Visualisation :** Power BI (`pbi_segmentation.pbix`)
- **Exports :** Excel (rapports intermédiaires et finaux)

---

## Livrables

- `Segmentation_RFM_Roland_Maeva_Lina.pdf` — présentation complète des résultats
- `pbi_segmentation.pbix` — dashboard interactif Power BI
- Programmes SAS commentés dans le dossier `PGM/`
