# Utilitaire de base de données PostgreSQL

Cet utilitaire permet de pouvoir interagir avec une base de données PGSQL, pouvoir effectuer toutes les interractions normalement faisable sur un client PGSQL.
Il permet donc d'effectuer :
- L'insertion, extraction, suppression, mise à jour de données
- La gestion des droits utilisateurs
- Fonctionnalité de visualisation de données
- Configuration de l'application 
- Quelques commandes intégrés dans l'application pour la gestion de l'application


PROCEDURE D'INSTALLATION :
=======================
Téléchargez le fichier UtilitaireDatabaseWindows_V1.0.zip dans la branche "V1" de la page github.
Dézippez le fichier et lancez l'exécutable.
Cette application à besoin que le service Postgres soit activé.
Idéalement, lancez le en mode administrateur pour éviter des problèmes au niveau de l'activation automatique des services.


VIDEO DE PRESENTATION :
====================================

<iframe width="1280" height="720" src="https://www.youtube.com/embed/MO04eJpqQ1U" title="Présentation OpenAdmin" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

FONCTIONNEMENT :
====================================

L'application est divisé en plusieurs groupe de page : 

### Utilisateurs : 
- Gestion Utilisateur
  - Permet de gérer les droits de l'utilisateurs pour certaines tables.
  - Les onglets permettent de gérer les droits en cliquant dessus et les types de droit voulu.
  - L'application rajoute puis retire les droits, dans le cas où les deux champs sont rempli
- Création Utilisateur
  - Permet de créer un utilisateur en lui attribuant des droits, l'attribution des droits ne fonctionne pas complètement.
  - Cliquer sur les droits permet de les attribuer à l'utilisateur.
- Suppression Utilisateur
  - Permet de supprimer un utilisateur
  - Les utilisateurs sont disponible sur le côté droit de la page, ils sont cliquables.


### Gestion de Base de Données : 
- Export / Import
  - Permet d'exporter ou importer des données, seul l'export des fichiers CSV est utilisable pour le moment
- Gestion Base de Données
  - Permet de visualiser les tables et colonnes d'une Base de Données, la création de clé étrangère et reset de la clé primaire sont déconseillés car instable.
- Création Base de Données
  - Permet de créer une Base de Données vide


### Gestion Tables : 
- Gestion Table
  - Permet de renomer une colonne ou un table, permet aussi de créer les clé étrangères écrites sous la forme "FK_Table1_Table2"
- Création Table
  - Permet de créer une ou plusieurs table(s) avec un format JSON


### Requêtes : 
- Requêtes écrite
  - Permet d'effectuer des requêtes écrites, plusieurs pages sont créer pour visualiser les données lorsqu'elles sont trop nombreuses. 
- Requêtes Formulaire
  - Permet d'effectuer des requêtes en cliquant sur les options proposé, même fonctionnement que la page précédente mais ne gère que les requêtes comportant une seule sous-requête maximum mais elle devras être écrite dans le sous-menu "Condition".
- Data Visualisation
  - Permet de visualiser les données JSON ou retourné par une requête PGSQL, plusieurs type de graphiques sont disponible mais ne gère que les requêtes retournant des données chiffrés, plusieurs options sont disponible pour mieux visualiser les données.


### Options : 
- Connexion
  - Page de connexion avec un historique des dernières connexions et un bouton pour se connecter à la Base de Données enregistré par défaut
- Options
  - Permet de modifier les le compte par défaut, la couleur de l'application, les boutons pour la taille de la fenêtre et "Trouver PGSQL" ne fonctionnent pas
- Informations
  - Permet d'avoir plusieurs informations sur le nombre de compte, le poids, le nombre de tables, la version utilisé de PGSQL et les extensions présentent dans la Base de Données 


### Divers : 
- Tutoriel
  - Permet d'avoir accès a la documentation du mot clé SQL entré et de télécharger postgreSQL
- Contact
  - Permet de contacter le créateur de l'application
- Test
  - Rien d'important, Work In Progress

FONCTIONNEMENT ? :
====================================




PROBLEMES
==========================

Modification des droits
Attribution des droits lors de la création d'utilisateur
Suppression d'utilisateur si il possède déjà des droits
Gestion d'un utilisateur comportant des majuscules dans son nom
La taille de la fenêtre n'est pas réglable et provoque beaucoup de bug visuels
Les différents onglets crées dans la page Data Visualisation ne sont pas sauvegardés lorsqu'on change de page
Les requêtes comportant déjà les mots clé "LIMIT" ou "OFFSET" ne peuvent afficher qu'une seule page, veillez à ce que la requête choisi ne renvoie que 100 valeurs ou moins dans ce cas.


AMELIORATIONS
==========================

Meilleur affichage des données dans la section "Gestion Base de Données"
Permettre de créer une Base de Données avec un certain encodage et/ou des tables déjà existantes
Reset de clé étrangère 
Changer le type de données d'une colonne
Meilleur gestion des tables


FAQ
==========================

### L'action (mot-clé SQL) effectué ne fait rien, ne fonctionne pas ?

=> Avez-vous les droits d'effectuer l'action en question sur le compte que vous utilisez ?
=> Cherchez dans la page de gestion d'utilisateur les droits que vous avez.

### L'application reste bloqué sur la page de Connexion ?

## Première solution :

=> Lancez l'application en mode administrateur
=> appuyez sur la touche "²" et entrez la commande "pg search"
=> en fonction des résultats lancez "pg set XX" avec XX la version de postgres renvoyé par la commande précédente

## Deuxième solution :

=> Entrez dans la barre de recherche Windows "services"
=> Une fois dans la fenêtre des services, cherchez "postgres"
=> Activez le ou les services que vous voulez utiliser

Contacts:
=======================
- Discord: Luthor#2920
- email: killian.lopez@outlook.com
