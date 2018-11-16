Reservation_DHCPx
Viens d'un script ps exe sur DHCP1 et DHCP2, remonte toutes le réservations active et innactive.
En tâche planifié sur DHCP1 à 20:05
En tâche planifié sur DHCP2 à 20:10
=> blinde le CPU, temporairement

InactiveReservationMergeFromDHCP1&2
Script ps sur SrvAdmin qui extrait les réservations inactive depuis les exports de DHCP1 et DHCP2,
puis fusionne en supprimant les doublons et les Actives sur l'un Inactives sur l'autres
et ajoute un compteur d'innactivité
=> en tâche planifiée tous le jours à 03:00, léger à l'éxecution.

-Cheminement :
Mettre en place compteur => ok
Compteur\COunt$Date.csv
1 points = 1 jours d'inactivité
- ATTENTION certaines adresses sont différentes sur DHCP1 & DHCP2 (une en bien une en BADADDRESS, 
description différentes, ...) et cela double le compteur
Les addresse "bugées" tombe sur un compteur égale au double du nombre de csv
=> bug patché, plus de dédoublement des adresses ip dans les exports
- Le nombre maximal du compteur est égal au nombre maximal de csv
=> égal à 60 modifiable

Bugs
- 1.2.3.4 DHCP1 Active
  1.2.3.4 DHCP2 Inactive
  Affiché comme Inactive depuis X jours
- Exportation des BadHostsName
  Effet indésirable remarqué, le comptage d'inactivité n'est plus correcte. Il reste bloqué à 17.
==> corrigés

Purge automatique des logs créés il y a plus de 60 jours
Code ajouté dans "InactiveReservationMergeFromDHCP1&2.ps1" exécuté tous les jours à 03:00 via Task Scheduler
- Les fichiers BadHostName n'était pas supprimés à cause d'un oubli dans le code
=> corrigé

Vérification de la valeur LastLogonTimestamp dans l'AD en fonction du HostName et du nom de domaine :
- Séparation hostname et nom de domaine => Ok
- Vérification dans l'AD via HostName et FQDN => Ok
- Ne plante pas à cause d'un HostName ou FQDN incorrect => Ok
- Création d'un tableau contenant HostName complet, LastLogonTimestamp et Days since last logon => Ok
- Fusion avec les tableaux de comptage de jours d'inactivité de la réservation IP et du tableau de détails => Ok
Erreur possible avec les HostName invalide contenant un point "." => Améliorarion possible, implémentation de VérifHostName (en test).
=> bug, à 3h le script n'a pu contacter aucun AD.
	soit à cause de l'horaire,
	soit à cause de la saturation du CPU.
	Tests :
	- Avec mon compte admin, exe du script => Ok
	  lancement de powershell avec "Start-Process powershell.exe -Crendential 'compte de service'" => Ok
	  lancement de la tâche planifié => Nok
	  modification de la tâche planifié, dans action ajout de "Crendential 'compte de service" à "Start-Process powershell.exe -File 'Script'" => Nok
Contact AD non fait avec la tâche planifiée :
Problème avec la tâche planifié
	- le compte svctp1 n'arrive pas à vérifier l'AD
	=> problème identifié
		le compte à bien les droits de lecture sur l'AD
		exe du script => ok
		exe de la tâche => nok
		Semble venir des nombreux noms de domaine invalide qui sont vérifier pui revérifier et qui font perdre beaucoup de temps
		=> tester l'ensemble de nom de domaine puis définir une liste de noms de domaine invalide.
			$nomdedomaine test-connection
			If (nomdedomaine invalide) alors ignore la vérification du FQDN
=> Test script via tâche planifié avec le compte de service à 03:00 = nok
=> Test script via tâche planifié avec le compte de service = nok
=> Test script via tâche planifié avec mon compte admin = nok
=> Test script via powershell avec le compte de service = ok
=> Test script via powershell avec mon compte admin = ok
==> Problème résolu, dans la tâche planifiée, décocher "Ne pas stocker le mot de passe"

Amélioration du script :
- Optimisation de la vérification dans l'AD.
	- meilleure protection contre les mauvais HostName divers et variés
	- deux boucle distincte pour la fusion des 3 tableaux
	- temps d'execution acceptable (1 à 2 minutes avec 500 valeurs contenant quelques mauvais HostName et/ou FQDN)

Modification de l'export des réservations depuis les DHCP.
Fusion du résultat des commande Get-DhcpServerv4Lease et Get-DhcpServerv4Reservation afin d'obtenir le type de réservations qui n'était jusque là pas présent dans les exports.
Cette valeur sera utile dans l'amélioration du script incomplete.
	
Reste à établir :
- une communication (mail à priori),
- une interface (opt.)Reservation_DHCPx
- amélioration du script incomplete (temps d'exécution très très long)
