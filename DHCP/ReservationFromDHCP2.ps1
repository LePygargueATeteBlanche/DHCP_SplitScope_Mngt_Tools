#Mets la date dans une variable
$CurrentDate = (Get-Date).ToString('yyyy-MM-dd')
$ReservationsDHCP2 = @()
#Utilise Get-DhcpServerv4Reservation sur tous les scopes (permet d'avoir tous les détails sauf AddressState)
#puis utilise les adresses IP du résultat dans un Get-DhcpServerv4Lease (permet d'avoir AddressState).
#"Fusion" des 2 résultats pour avoir un tableau contenant tous les détails
$Reservations = Get-DhcpServerv4Scope -ComputerName DHCP2.formation.lan | Get-DhcpServerv4Reservation
ForEach($Reservation in $Reservations){
    $ReservationLease = Get-DhcpServerv4Lease -ComputerName DHCP2.formation.lan -IPAddress $Reservation.IpAddress
    If($Reservation.Name -eq $ReservationLease.HostName){
        $ReservationsDHCP2 += New-Object PSObject -Property @{
        IpAddress = $Reservation.IpAddress;
        ScopeId = $Reservation.ScopeId;
        ClientId = $Reservation.ClientId;
        HostName = $Reservation.Name;
        AddressState = $ReservationLease.AddressState;
        Type = $Reservation.Type;
        Description = $Reservation.Description;
        }
    }
}
$ReservationsDHCP2 | Export-Csv -NoTypeInformation -path "\\SrvAdmin.admin.lan\DHCP_Reservation_Export_DHCP1&2\Reservation_DHCP2\Reservation_DHCP2_$CurrentDate.csv"
Write-Host "Résultat envoyé vers \\SrvAdmin.admin.lan\DHCP_Reservation_Export_DHCP1&2\Reservation_DHCP2\Reservation_DHCP2_$CurrentDate.csv"
