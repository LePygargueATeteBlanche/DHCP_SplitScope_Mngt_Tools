##################################################
#Déclaration de dates
$CurrentDate = (Get-Date).ToString('yyyy-MM-dd')
$CurrentDateM1d = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')
#$CurrentDate0 = "2017-11-14"
$ExpirationDate = 60
$LogExpirationDate = 60
$CurrentDateMxd = (Get-Date).AddDays(-$ExpirationDate).ToString('yyyy-MM-dd')
##################################################

##################################################
#Importe les réservations de DHCP1 et applique le filtre "Réservation Inactive"
$fileResDHCP1 = Import-Csv -path "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\Reservation_DHCP1\Reservation_DHCP1_$CurrentDateM1d.csv" |
    Where-Object {$_."AddressState" -eq "InactiveReservation"} |
    Sort-Object -Property "IpAddress"
#Importe les réservations de DHCP2 et applique le filtre "Réservation Inactive"
$fileResDHCP2 = Import-Csv -path "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\Reservation_DHCP2\Reservation_DHCP2_$CurrentDateM1d.csv" |
    Where-Object {$_."AddressState" -eq "InactiveReservation"} |
    Sort-Object -Property "IpAddress"
##################################################

##################################################
#Boucle de comparaison des réservations inactives sur DHCP1 et 1
#Résultat équivalent à un InnerJoin SQL : Si IP (innactives) présente sur 1 et 2 => Ajoute dans l'array $Export
#Sinon ne fait rien. Permet d'éliminer les réservations actives sur l'un et innactives sur l'autre
#Basé sur l'HostName. Les réservations non idenique sur le nom ne remonteront pas ici. => Voir script "IncompleteReservation"
$ExportGoodHostName = @();
$ExportBadHostName = @();
ForEach($line1 in $fileResDHCP1){
    ForEach($line2 in $fileResDHCP2){
        #Property "IPAddress","ScopeId","AddressState","ClientId","Description","HostName"
        If(($line1.IpAddress -eq $line2.IpAddress) -and ($line1.HostName -eq $line2.HostName)){
            $ExportGoodHostName += New-Object PSObject -Property @{
            IpAddress = $line1.IpAddress;
            ScopeId = $line1.ScopeId;
            AddressState = $line1.AddressState;
            ClientId = $line1.ClientId;
            Description = $line1.Description;
            HostName = $line1.HostName;
            }
        }
        If(($line1.IpAddress -eq $line2.IpAddress) -and ($line1.HostName -ne $line2.HostName)){
            $ExportBadHostName += New-Object PSObject -Property @{
            IpAddress = $line1.IpAddress;
            ScopeId = $line1.ScopeId;
            AddressState = $line1.AddressState;
            ClientId = $line1.ClientId;
            Description = $line1.Description;
            HostName = $line1.HostName;
            }
        }
    }
}

$ExportGoodHostName | Export-Csv -Path "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\InactiveReservation\InactiveReservation_$CurrentDateM1d.csv"
Write-Output "Le fichier InactiveReservation_$CurrentDateM1d.csv a été créé avec succès."
$ExportBadHostName | Export-Csv -Path  "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\BadHostName\InactiveReservation_BHN_$CurrentDateM1d.csv"
Write-Output "Le fichier InactiveReservation_BHN_$CurrentDateM1d.csv a été créé avec succès."
##################################################

##################################################
#Comparaison d'un nombres défini de fichier CSV ($ExpirationDate) pour repérer les réservations InActives pendant un nombre de jours d'affilés définis
#Ces fichiers sont importés via un Get-ChildItem après avoir été triés par Date pour récupérer les x plus récent.
Write-Host "Comparaison de $ExpirationDate fichiers CSV de $CurrentDateM1d à $CurrentDateMxd et vérification du LastLogonDate dans l'AD"
$CSVFiles = Get-ChildItem -Path "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\InactiveReservation" |
    Sort-Object -Descending |
    Select-Object -First $ExpirationDate
$Tab = @();
#L'ensemble du contenu des CSV est importé dans un Array $Tab
ForEach($CSV in $CSVFiles){
    $Temp = Import-Csv $CSV.FullName
    $Tab += $Temp
}
##Property "IPAddress","ScopeId","AddressState","ClientId","Description","HostName"
##################################################

##################################################
#Cet Array est passé dans un Group-Object pour ajouter un compteur en éliminant les doublons d'adresses IP et en triant au passage
#Cela ne supprime pas les doublons de nom d'hôte. Ainsi 2 ip différentes peuvent être réservées pour le même hôte.
#Ici Name <=> IpAddress
$CompteurTemp = $Tab |
    ForEach-Object{ $_.IpAddress} |
    Group-Object -NoElement |
    Select-Object -Property "Count","Name" |
    Sort-Object -Descending -Property Count
##################################################

##################################################
#Vérification LastLogonTimestamp dans l'AD
Write-Host "Vérification LastLogonDate dans l'AD :"
$Détail = Import-Csv -Path "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\InactiveReservation\InactiveReservation_$CurrentDateM1d.csv" | Sort-Object -Descending -Property HostName
$FullHostNames = $Détail.HostName | Sort-Object -Descending -Property HostName
$RésultatsVerifAD = @()
$FullHostNamesAndFqdnObject = @()
<#
Expression régulière
([A-za-z0-9\-]+\.[A-Za-z0-9\-]+\.[A-Za-z]+([A-Za-z0-9\.\-])*)
() <=> Groupe de capture
[A-za-z0-9\-]+ <=> Jeu de caractères de "A à Z", de "a à z", de "0 à 9" et le tiret "-". "\" est pour échaper les caractères spéciaux.
\. <=> point
"+" doit matcher avec 1 ou plus dans le jeu ou groupe de capture précédent précédent.
"*" <=> doit matcher avec 0 ou plus dans le jeu ou groupe de capture précédent précédent.
#>
$ValidHostnameRegex = "([A-za-z0-9\-]+\.[A-Za-z0-9\-]+\.[A-Za-z]+([A-Za-z0-9\.\-])*)"

#Elimination les hostname invalide
Write-Host " -Elimination des noms invalides"
$ValidHostnamesArray = @()
ForEach($FullHostname in $FullHostNames){
    If($FullHostname -match $ValidHostnameRegex){
        $ValidHostnamesArray += $FullHostname
    }
}

ForEach($ValidFullHostname in $ValidHostnamesArray){
    #Séparation du HostName et du FQDN qui sont ajoutés dans un nouvel objet.
    $Temp = $ValidFullHostname -Split "\.",2
    $HostName = $Temp[0]
    $FQDN = $Temp[1]
    $FullHostNamesAndFqdnObject += New-Object PSObject -Property @{
        "HostName" = $HostName;
        "FQDN" = $FQDN;
    }
}

#A partir de la liste des FQDN, liste des FQDN sans doublons
#Permet de les tester individuellement et déterminer quel domaine est joignable ou pas.
Write-Host " -Définition des domaines joignables"
$ContactableDomain = @()
$UniqueFQDN = $FullHostNamesAndFqdnObject.FQDN | Sort-Object -Unique
ForEach($FQDN in $UniqueFQDN){
    If(Test-Connection -ComputerName $FQDN -Count 2 -Delay 1 -Quiet){
        $ContactableDomain += $FQDN
    }
}
Write-Host
Write-Host "Domaines joignables :"
$ContactableDomain
Write-Host

ForEach($Line in $FullHostNamesAndFqdnObject){
    Clear-Variable LastLogon,Inactivity,Temp,FQDN,HostName -Scope Script -ErrorAction Ignore
    If($ContactableDomain.Contains($Line.FQDN)){ #Pour chaque ligne test si le FQDN correspond à un domaine joignable défini plus haut.
        Write-Host $Line.HostName" + "$Line.FQDN
        $LastLogon = Get-ADComputer -ErrorAction Continue -Server $Line.FQDN -Identity $Line.HostName -Properties * | Select-Object -ExpandProperty "LastLogonDate"
    }
    $VerifAD = New-Object PSObject
    $VerifAD | Add-Member -MemberType NoteProperty -Name "Hostname" -Value (($Line.HostName)+"."+($Line.FQDN))
    #Si $LastLogon n'est pas nul ou vide, alors ajout de la valeur de la variable dans l'objet résultat
    If($LastLogon -and $LastLogon -ne $null -and $LastLogon -ne "Invalid"){
        $VerifAD | Add-Member -MemberType NoteProperty -Name "Last_logon" -Value $LastLogon
        #Calcul du nombres de jours sans connexion
        $Inactivity = New-TimeSpan -Start $LastLogon -End (Get-Date)
        $VerifAD | Add-Member -MemberType NoteProperty -Name "Days_since_last_logon" -Value $Inactivity.Days
    #Sinon ajout écrit "HostName not found", sous entendu l'HostName n'existe pas/plus dans l'AD
    }ElseIf ($LastLogon -eq $null){
        $VerifAD | Add-Member -MemberType NoteProperty -Name "Last_logon" -Value "HostName_invalid"
        $VerifAD | Add-Member -MemberType NoteProperty -Name "Days_since_last_logon" -Value "Unknown"
    }
$RésultatsVerifAD += $VerifAD
}
$RésultatsVerifAD = $RésultatsVerifAD | Sort-Object -Descending -Property HostName
##################################################

##################################################
#Le Group-Object sur la liste d'adresses IP (export des réservations Inactives auparavant) plus haut élimine les doublons en ajoutant un compteur.
#La vérification du LastLogonTimestamp dans l'AD donne un tableau contenant HostName, Date du LastLogon, Jours depuis le LastLogon
#Cette partie réunit les information de "InactiveReservation" / Détails, "RésultatsVerifAD", et "CompteurTemp" en prenant soin de ne rien mélanger
#Pour chaque Lignes de compteur et pour chaque Lignes de Détails et pour chaque Lignes de RésultatsVerifAD :
# => Si IP de Ligne compteur = IP de Ligne détail
# => Et Si IP de Ligne VerifAD = IP de Ligne détail
# => Alors Nouvel objet contenant LigneDétail, LigneCompteur et LigneVerifAD
Write-Host "Comparaison des CSV et ajout du LastLogonDate"
$RésultatCompteurInactivité = @()
ForEach($LigneCompteur in $CompteurTemp){
    ForEach($LigneDétail in $Détail){
        If(($LigneCompteur.Name -eq $LigneDétail.IpAddress)){
        $RésultatCompteurInactivité += New-Object PSObject -Property @{
        "Reservation_inactivity_in_days_(60_max)" = $LigneCompteur.Count;
        "HostName" = $LigneDétail.HostName;
        "AD_LastLogonTimestamp" = $LigneVerifAD.'Last_logon';
        "Days_since_last_logon" = $LigneVerifAD.'Days_since_last_logon';
        "IpAddress" = $LigneDétail.IpAddress;
        "ScopeId" = $LigneDétail.ScopeId;
        "AddressState" = "InactiveReservation";
        "ClientId" = $LigneDétail.ClientId;
        "Description" = $LigneDétail.Description;
        }
        }
    }
#Write-Host ($RésultatCompteurInactivité).Count" / "($CompteurTemp).Count
}

$RésultatFinal = @()
ForEach($LigneVerifAD in $RésultatsVerifAD){
    ForEach($LigneRésultatCompteurInactivité in $RésultatCompteurInactivité){
        If($LigneVerifAD.HostName -eq $LigneRésultatCompteurInactivité.HostName){
        $RésultatFinal += New-Object PSObject -Property ([ordered]@{
        "Reservation_inactivity_in_days_(60_max)" = $LigneRésultatCompteurInactivité."Reservation_inactivity_in_days_(60_max)";
        "HostName" = $LigneRésultatCompteurInactivité.HostName;
        "AD_LastLogonTimestamp" = $LigneVerifAD."Last_logon";
        "Days_since_last_logon" = $LigneVerifAD."Days_since_last_logon";
        "IpAddress" = $LigneRésultatCompteurInactivité.IpAddress;
        "ScopeId" = $LigneRésultatCompteurInactivité.ScopeId;
        "AddressState" = $LigneRésultatCompteurInactivité."AddressState";
        "ClientId" = $LigneRésultatCompteurInactivité.ClientId;
        "Description" = $LigneRésultatCompteurInactivité.Description;
        })
        }
    }
}
$RésultatFinal | Export-Csv -Path "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\Compteur d'inactivité\DhcpInactiveReservationCount_$CurrentDateM1d.csv"
Write-Host "Exportation des résultats vers: C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\Compteur d'inactivité\DhcpInactiveReservationCount_$CurrentDateM1d.csv"
##################################################

##################################################
#Purge des logs créés il y a plus de $LogExpirationDate jours
Write-Host "Suppression des logs créés il y a plus de $LogExpirationDate jours"
#Déclaration de dates
$LastWrite = (Get-Date).AddDays(-$LogExpirationDate).ToString('yyyy-MM-dd')
#Déclarations des chemins
$TargetFolder1 = "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\Reservation_DHCP1"
$TargetFolder2 = "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\Reservation_DHCP2"
$TargetFolderIR = "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\InactiveReservation"
$TargetFolderCI = "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\Compteur d'inactivité"
$TargetFolderBH = "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\BadHostName"
#Importations des fichiers
$Files = Get-ChildItem -Path $TargetFolder1, $TargetFolder2, $TargetFolderIR, $TargetFolderCI, $TargetFolderBH |
Where-Object {$_.LastWriteTime -le "$LastWrite"}
#Boucle de suppression
ForEach($File in $Files){
    If($File -ne $NULL){
        Write-Host "Deleting $File"
        Remove-Item $File.FullName
    }
}
Write-Host "No more files to delete"
##################################################