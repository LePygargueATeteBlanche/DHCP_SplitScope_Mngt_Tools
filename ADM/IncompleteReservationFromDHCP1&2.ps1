###Mets la date dans une variable
$CurrentDate = (Get-Date).ToString('yyyy-MM-dd')
$CurrentDateMinus1d = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')

$fileResDHCP1 = Import-Csv -path "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\Reservation_DHCP1\Reservation_DHCP1_$CurrentDateMinus1d.csv"
$fileResDHCP2 = Import-Csv -path "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\Reservation_DHCP2\Reservation_DHCP2_$CurrentDateMinus1d.csv"

###Compare chaque lignes de "fileResDHCP1" à chaque lignes de "fileResDHCP2" en renvoie les différences dans un tableau qui est ensuite exporté dans un csv
###La comparaison est possible car les fichiers ont été triés de la même manière au moment de l'export avec : Sort-Object "IPAddress"
$arrResult_Comparaison1to2 = @()
Write-Host "Comparaison des réservations de DHCP1 avec DHCP2"
Write-Host "1/4 Comparaison des IP"
foreach ($line in $fileResDHCP1){
    If (-not($fileResDHCP2 | Where-Object {$_."IpAddress" -eq $line."IpAddress"})){
        $arrResult_Comparaison1to2 += $line
    }
}
Write-Host "2/4 Comparaison des Description"
foreach ($line in $fileResDHCP1){
    If (-not($fileResDHCP2 | Where-Object {$_."Description" -eq $line."Description"})){
        $arrResult_Comparaison1to2 += $line
    }
}
Write-Host "3/4 Comparaison des ClientId"
foreach ($line in $fileResDHCP1){
    If (-not($fileResDHCP2 | Where-Object {$_."ClientId" -eq $line."ClientId"})){
        $arrResult_Comparaison1to2 += $line
    }
}
Write-Host "4/4 Comparaison des HostName"
foreach ($line in $fileResDHCP1){
    If (-not($fileResDHCP2 | Where-Object {$_."HostName" -eq $line."HostName"})){
        $arrResult_Comparaison1to2 += $line
    }
}
Write-Host Exportation des résultats vers "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\IncompleteReservation_1to2\IncompleteReservation_1to2_$CurrentDateMinus1d.csv" ...
$arrResult_Comparaison1to2 | Sort-Object -Property "IpAddress" | Export-Csv "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\IncompleteReservation_1to2\IncompleteReservation_1to2_$CurrentDateMinus1d.csv"
Write-Host Terminé.


###Compare chaque lignes de "fileResDHCP2" à chaque lignes de "fileResDHCP1" en renvoie les différences dans un tableau qui est ensuite exporté dans un csv
$arrResult_Comparaison2to1 = @()
Write-Host "Comparaison des réservations de DHCP2 avec DHCP1"
Write-Host "1/4 Comparaison des IP"
foreach ($line in $fileResDHCP2){
    If (-not($fileResDHCP1 | Where-Object {$_."IpAddress" -eq $line."IpAddress"})){
        $arrResult_Comparaison2to1 += $line
    }
}
Write-Host "2/4 Comparaison des Description"
foreach ($line in $fileResDHCP2){
    If (-not($fileResDHCP1 | Where-Object {$_."Description" -eq $line."Description"})){
        $arrResult_Comparaison2to1 += $line
    }
}
Write-Host "3/4 Comparaison des ClientId"
foreach ($line in $fileResDHCP2){
    If (-not($fileResDHCP1 | Where-Object {$_."ClientId" -eq $line."ClientId"})){
        $arrResult_Comparaison2to1 += $line
    }
}
Write-Host "4/4 Comparaison des HostName"
foreach ($line in $fileResDHCP2){
    If (-not($fileResDHCP1 | Where-Object {$_."HostName" -eq $line."HostName"})){
        $arrResult_Comparaison2to1 += $line
    }
}
Write-Host Exportation des résultats vers "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\IncompleteReservation_2to1\IncompleteReservation_2to1_$CurrentDateMinus1d.csv" ...
$arrResult_Comparaison2to1 | Sort-Object -Property "IpAddress" | Export-Csv "C:\Users\User\Documents\DHCP_Reservation_Export_DHCP1&2\IncompleteReservation_2to1\IncompleteReservation_2to1_$CurrentDateMinus1d.csv"
Write-Host Terminé.