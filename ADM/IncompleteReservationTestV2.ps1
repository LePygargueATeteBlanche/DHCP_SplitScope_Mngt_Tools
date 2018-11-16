##################################################
###Mets la date dans une variable
$CurrentDate = (Get-Date).ToString('yyyy-MM-dd')
$CurrentDateMinus1d = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')
$fileResDHCP1 = Import-Csv -path "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\Reservation_DHCP1\Reservation_DHCP1_$CurrentDateMinus1d.csv"
$fileResDHCP2 = Import-Csv -path "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\Reservation_DHCP2\Reservation_DHCP2_$CurrentDateMinus1d.csv"
##################################################

##################################################
#Trouver les réservations asymétrique sur l'adresse IP (présente que d'un côté)
#Deux méthodes valide :
#1 utiliser compare-object => ne ressort que les différences
#2 utiliser group-object => Si toutes les adresses ressortent avec un compteur à 2 alors pas de différence
$AsymetricResIp=@()
$ResultAsymetricTest=@()
$IpAddress1=$fileResDHCP1.IpAddress
$IpAddress2=$fileResDHCP2.IpAddress
#$IpAddress1=("1.1.1.1","2.2.2.2","3.3.3.3","4.4.4.4","5.5.5.5","6.6.6.6","8.8.8.8")
#$IpAddress2=("2.2.2.2","4.4.4.4","1.1.1.1","3.3.3.3","7.7.7.7","5.5.5.5","9.9.9.9")
$AsymetricResIp=Compare-Object -ReferenceObject $IpAddress1 -DifferenceObject $IpAddress2
ForEach($Line in $AsymetricResIp){
    If($Line.SideIndicator -match "<="){
        $ResultAsymetricTest += New-Object PSObject -Property @{
        "IpReservation" = $Line.InputObject;
        "Infos" = "Réservation existe sur DHCP1 et pas sur DHCP2";
        }
    }
    ELseIf($Line.SideIndicator -match "=>"){
        $ResultAsymetricTest += New-Object PSObject -Property @{
        "IpReservation" = $Line.InputObject;
        "Infos" = "Réservation existe sur DHCP2 et pas sur DHCP1";
        }
    }
}
$ResultAsymetricTest
##################################################

##################################################
#Parmis les réservations symétriques sur l'IP, identifier les différences dans les détails (Hostname, ClientId, Description, Type)
$IpSymOnly=@()
If(($ResultAsymetricTest).Count -eq 0){ #Si le tableau Asymétrique est vide, alors les réservations sont toutes symétrique sur l'IP des deux côté
    $IpSymOnly=$IpAddress1 #Donc peut-importe quelle liste d'IP est importée ici
}
Else{#Si le tableau asymétrique n'est pas vide
    $AllIPs=$IpAddress1+$IpAddress2 #On liste toutes les IPs
    $AllUniqueIPs=$AllIPs|Sort-Object -Unique #On enlève les doublons
    ForEach($IP in $AllUniqueIPs){ #Pour chacune des ces IPs
        If(($ResultAsymetricTest.IpReservation).Contains($IP)){
        } #Si elle est contenue dans le tableau d'IPs asymétrique défini plus haut alors on l'ignore pour la suite.
        Else{
            $IpSymOnly+=$IP #Sinon, on l'ajoute dans le tableau IpSymétrique
        }
    }
}
<#Write-Host ""
Write-Host "Résultat IP symétrique"
$IpSymOnly#>
#Dans les deux cas, la variable de sortie finale est la même.
#Teste avec :
#$IpSymOnly|Group-Object|Where-Object {$_.Count -eq "1"}
#$IpSymOnly|Group-Object|Where-Object {$_.Count -eq "2"}
##################################################

##################################################
#Pour tester les variables détails pour chaque réservations, repartir de fileResDHCP1 et fileResDHCP2 et filtrant avec IpSymOnly si n'est pas vide
#Trier par IP des deux côté
#Pour chacune des IPs => Objet.Détail Compare-Object et si résultat alors différent

##################################################