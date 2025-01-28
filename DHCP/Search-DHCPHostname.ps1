# This PowerShell script connects to a specified DHCP server and retrieves all DHCP scopes.
# It searches for a specific hostname within the leases of each scope, checks the machine's 
# connectivity using a ping test, and displays the results in a formatted table.
#
# Parameters:
# - $DhcpServer: The address or name of the DHCP server to query.
# - $SearchHostname: The hostname (or partial hostname) to search for in the leases.
#
# Workflow:
# 1. Retrieve all scopes from the DHCP server using Get-DhcpServerv4Scope.
# 2. Iterate through each scope and fetch the active leases using Get-DhcpServerv4Lease.
# 3. Filter the leases to match the specified hostname.
# 4. Use Test-Connection to check if the machine is reachable (active or inactive).
# 5. Output the results in a clean, formatted table including:
#    - Scope ID
#    - Scope Name
#    - IP Address
#    - Hostname
#    - MAC Address
#    - Connectivity State (Active/Inactive)

# Define the DHCP server address and the hostname to search for
$DhcpServer = "DHCP_Server_Address"
$SearchHostname = "Target_Hostname"

# Get the list of all DHCP scopes on the specified server
$scopes = Get-DhcpServerv4Scope -ComputerName $DhcpServer

# Initialize an array to store all results
$finalResults = @()

# Iterate through each scope to search for the specified hostname
foreach ($scope in $scopes) {
    # Get all DHCP leases for the current scope
    $leases = Get-DhcpServerv4Lease -ComputerName $DhcpServer -ScopeId $scope.ScopeId

    # Filter the leases to find matches for the target hostname
    $match = $leases | Where-Object { $_.HostName -like "*$SearchHostname*" }

    # If any matches are found, process them
    if ($match) {
        # Iterate through the matched leases and gather detailed information
        $results = $match | ForEach-Object {
            # Check if the machine is reachable using a ping command
            $ping = Test-Connection -ComputerName $_.IPAddress -Count 1 -Quiet

            # Create a custom object to store the relevant data
            [PSCustomObject]@{
                ScopeId    = $_.ScopeId       # Scope ID of the lease
                ScopeName  = $scope.Name      # Name of the scope
                IPAddress  = $_.IPAddress     # IP address assigned to the machine
                HostName   = $_.HostName      # Hostname of the machine
                MacAddress = $_.MacAddress    # MAC address of the machine
                State      = if ($ping) {     # Check the ping response to determine the state
                               "Active"       # Active if ping is successful
                           } else { 
                               "Inactive"     # Inactive if ping fails
                           }
            }
        }

        # Add the results to the final array
        $finalResults += $results
    }
}

# Display the final results in a single formatted table
if ($finalResults.Count -gt 0) {
    $finalResults | Format-Table -Property ScopeId, ScopeName, IPAddress, HostName, MacAddress, State -AutoSize
} else {
    Write-Host "No matching results found." -ForegroundColor Yellow
}
