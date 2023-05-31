# Utilitaire de base de données PostgreSQL

Cet utilitaire permet de pouvoir interagir avec une base de données PGSQL, pouvoir effectuer toutes les interractions normalement faisable sur un client PGSQL.
Il permet donc d'effectuer :
- L'insertion, extraction, suppression, mise à jour de données
- La gestion des droits utilisateurs
- Fonctionnalité de visualisation de données
- Configuration de l'application 
- Quelques commandes intégrés dans l'application pour la gestion de l'application


INSTALLATION PROCEDURE:
=======================
Téléchargez le fichier UtilitaireDatabaseWindows_V1.0.zip dans la branche "V1" du projet.
Dézippez le fichier et lancez l'exécutable.
Cette application à besoin que le service Postgres soit activé.
Idéalement, lancez le en mode administrateur pour éviter des problèmes au niveau de l'activation automatique des services.


Fonctionnement :
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
  - Les utilisateurs sont 


HOW TO USE?:
====================================




PROBLEMS
==========================

Modification des droits
Attribution des droits lors de la création d'utilisateur
Suppression d'utilisateur si il possède déjà des droits


FREQUENTLY ASKED QUESTIONS
==========================

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
