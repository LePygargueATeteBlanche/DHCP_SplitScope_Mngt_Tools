Reservation_DHCPx
Viens d'un script ps exe sur DHCP1 et DHCP2, remonte toutes le r�servations active et innactive.
En t�che planifi� sur DHCP1 � 20:05
En t�che planifi� sur DHCP2 � 20:10
=> blinde le CPU, temporairement

InactiveReservationMergeFromDHCP1&2
Script ps sur SrvAdmin qui extrait les r�servations inactive depuis les exports de DHCP1 et DHCP2,
puis fusionne en supprimant les doublons et les Actives sur l'un Inactives sur l'autres
et ajoute un compteur d'innactivit�
=> en t�che planifi�e tous le jours � 03:00, l�ger � l'�xecution.

-Cheminement :
Mettre en place compteur => ok
Compteur\COunt$Date.csv
1 points = 1 jours d'inactivit�
- ATTENTION certaines adresses sont diff�rentes sur DHCP1 & DHCP2 (une en bien une en BADADDRESS, 
description diff�rentes, ...) et cela double le compteur
Les addresse "bug�es" tombe sur un compteur �gale au double du nombre de csv
=> bug patch�, plus de d�doublement des adresses ip dans les exports
- Le nombre maximal du compteur est �gal au nombre maximal de csv
=> �gal � 60 modifiable

Bugs
- 1.2.3.4 DHCP1 Active
  1.2.3.4 DHCP2 Inactive
  Affich� comme Inactive depuis X jours
- Exportation des BadHostsName
  Effet ind�sirable remarqu�, le comptage d'inactivit� n'est plus correcte. Il reste bloqu� � 17.
==> corrig�s

Purge automatique des logs cr��s il y a plus de 60 jours
Code ajout� dans "InactiveReservationMergeFromDHCP1&2.ps1" ex�cut� tous les jours � 03:00 via Task Scheduler
- Les fichiers BadHostName n'�tait pas supprim�s � cause d'un oubli dans le code
=> corrig�

V�rification de la valeur LastLogonTimestamp dans l'AD en fonction du HostName et du nom de domaine :
- S�paration hostname et nom de domaine => Ok
- V�rification dans l'AD via HostName et FQDN => Ok
- Ne plante pas � cause d'un HostName ou FQDN incorrect => Ok
- Cr�ation d'un tableau contenant HostName complet, LastLogonTimestamp et Days since last logon => Ok
- Fusion avec les tableaux de comptage de jours d'inactivit� de la r�servation IP et du tableau de d�tails => Ok
Erreur possible avec les HostName invalide contenant un point "." => Am�liorarion possible, impl�mentation de V�rifHostName (en test).
=> bug, � 3h le script n'a pu contacter aucun AD.
	soit � cause de l'horaire,
	soit � cause de la saturation du CPU.
	Tests :
	- Avec mon compte admin, exe du script => Ok
	  lancement de powershell avec "Start-Process powershell.exe -Crendential 'compte de service'" => Ok
	  lancement de la t�che planifi� => Nok
	  modification de la t�che planifi�, dans action ajout de "Crendential 'compte de service" � "Start-Process powershell.exe -File 'Script'" => Nok
Contact AD non fait avec la t�che planifi�e :
Probl�me avec la t�che planifi�
	- le compte svctp1 n'arrive pas � v�rifier l'AD
	=> probl�me identifi�
		le compte � bien les droits de lecture sur l'AD
		exe du script => ok
		exe de la t�che => nok
		Semble venir des nombreux noms de domaine invalide qui sont v�rifier pui rev�rifier et qui font perdre beaucoup de temps
		=> tester l'ensemble de nom de domaine puis d�finir une liste de noms de domaine invalide.
			$nomdedomaine test-connection
			If (nomdedomaine invalide) alors ignore la v�rification du FQDN
=> Test script via t�che planifi� avec le compte de service � 03:00 = nok
=> Test script via t�che planifi� avec le compte de service = nok
=> Test script via t�che planifi� avec mon compte admin = nok
=> Test script via powershell avec le compte de service = ok
=> Test script via powershell avec mon compte admin = ok
==> Probl�me r�solu, dans la t�che planifi�e, d�cocher "Ne pas stocker le mot de passe"

Am�lioration du script :
- Optimisation de la v�rification dans l'AD.
	- meilleure protection contre les mauvais HostName divers et vari�s
	- deux boucle distincte pour la fusion des 3 tableaux
	- temps d'execution acceptable (1 � 2 minutes avec 500 valeurs contenant quelques mauvais HostName et/ou FQDN)

Modification de l'export des r�servations depuis les DHCP.
Fusion du r�sultat des commande Get-DhcpServerv4Lease et Get-DhcpServerv4Reservation afin d'obtenir le type de r�servations qui n'�tait jusque l� pas pr�sent dans les exports.
Cette valeur sera utile dans l'am�lioration du script incomplete.
	
Reste � �tablir :
- une communication (mail � priori),
- une interface (opt.)Reservation_DHCPx
- am�lioration du script incomplete (temps d'ex�cution tr�s tr�s long)
