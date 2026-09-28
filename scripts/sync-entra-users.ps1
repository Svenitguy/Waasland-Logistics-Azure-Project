<#
.SYNOPSIS
    WLCS - Entra ID Group Synchronization

.DESCRIPTION
    Voegt actieve gebruikers toe aan hun afdelingsgroep
    op basis van de waarde van het Department-attribuut.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ============================================================
# 1. Verbinden met Microsoft Graph
# ============================================================

Write-Host "Bezig met verbinden met Microsoft Graph..." -ForegroundColor Cyan

try {
    Connect-MgGraph `
        -TenantId "wlcservicescorp.onmicrosoft.com" `
        -Scopes "Group.ReadWrite.All", "User.Read.All" `
        -ErrorAction Stop

    $Context = Get-MgContext -ErrorAction Stop

    if (-not $Context) {
        throw "Geen Microsoft Graph-context beschikbaar."
    }

    Write-Host "Succesvol verbonden met Microsoft Graph." -ForegroundColor Green
    Write-Host "Tenant: $($Context.TenantId)" -ForegroundColor DarkGray
    Write-Host "Account: $($Context.Account)" -ForegroundColor DarkGray
}
catch {
    Write-Error "Microsoft Graph authenticatie mislukt: $($_.Exception.Message)"
    exit 1
}

# ============================================================
# 2. Department -> Entra ID Group DisplayName
# ============================================================

$GroupMap = @{
    "IT & Cloud Beheer"     = "dept-wlcs-it"
    "Directie & Management" = "dept-wlcs-management"
    "Administratie & HR"    = "dept-wlcs-office"
    "Logistiek & Magazijn"  = "dept-wlcs-logistics"
}

# ============================================================
# 3. Groepen ophalen
# ============================================================

Write-Host "`nEntra-groepen ophalen..." -ForegroundColor Cyan

$EntraGroups = @{}

foreach ($Dept in $GroupMap.Keys) {

    $GroupName = $GroupMap[$Dept]

    try {

        $Group = Get-MgGroup `
            -Filter "DisplayName eq '$GroupName'" `
            -Property Id, DisplayName `
            -ErrorAction Stop |
        Select-Object -First 1

        if ($null -eq $Group) {
            Write-Error "Groep '$GroupName' niet gevonden."
            continue
        }

        if ([string]::IsNullOrWhiteSpace($Group.Id)) {
            Write-Error "Groep '$GroupName' gevonden, maar Object ID is leeg."
            continue
        }

        $EntraGroups[$Dept] = $Group.Id

        Write-Host `
            "Groep gevonden: $($Group.DisplayName) -> $($Group.Id)" `
            -ForegroundColor Green
    }
    catch {

        Write-Error `
            "Fout bij ophalen van groep '$GroupName': $($_.Exception.Message)"
    }
}

# ============================================================
# 4. Controleren of alle groepen gevonden zijn
# ============================================================

if ($EntraGroups.Count -ne $GroupMap.Count) {

    Write-Error "Niet alle vereiste Entra-groepen konden worden gevonden."
    Write-Error "Synchronisatie wordt afgebroken om fouten te voorkomen."

    Write-Host "`nGevonden groepen:" -ForegroundColor Yellow

    foreach ($Entry in $EntraGroups.GetEnumerator()) {
        Write-Host `
            "$($Entry.Key) -> $($Entry.Value)" `
            -ForegroundColor Yellow
    }

    exit 1
}

Write-Host "`nAlle vereiste groepen zijn gevonden." -ForegroundColor Green

# ============================================================
# 5. Actieve gebruikers ophalen
# ============================================================

Write-Host "`nGebruikers ophalen uit tenant..." -ForegroundColor Cyan

try {

    $AllUsers = Get-MgUser `
        -All `
        -Property Id, DisplayName, Department, AccountEnabled `
        -ErrorAction Stop |
    Where-Object {
        $_.AccountEnabled -eq $true
    }

    Write-Host `
        "Aantal actieve gebruikers: $($AllUsers.Count)" `
        -ForegroundColor Green
}
catch {

    Write-Error `
        "Fout bij ophalen van gebruikers: $($_.Exception.Message)"

    exit 1
}

# ============================================================
# 6. Statistieken
# ============================================================

$AddedCount = 0
$AlreadyMemberCount = 0
$SkippedCount = 0
$ErrorCount = 0

# ============================================================
# 7. Synchronisatie
# ============================================================

Write-Host "`nStarten met synchronisatie..." -ForegroundColor Cyan

foreach ($User in $AllUsers) {

    # --------------------------------------------------------
    # Department ontbreekt
    # --------------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($User.Department)) {

        Write-Host `
            "Geen Department: $($User.DisplayName)" `
            -ForegroundColor DarkYellow

        $SkippedCount++
        continue
    }

    # --------------------------------------------------------
    # Department bestaat niet in GroupMap
    # --------------------------------------------------------

    if (-not $EntraGroups.ContainsKey($User.Department)) {

        Write-Host `
            "Geen groepsmapping voor Department '$($User.Department)': $($User.DisplayName)" `
            -ForegroundColor DarkYellow

        $SkippedCount++
        continue
    }

    # --------------------------------------------------------
    # Doelgroep bepalen
    # --------------------------------------------------------

    $TargetGroupId = $EntraGroups[$User.Department]
    $TargetGroupName = $GroupMap[$User.Department]

    # Extra beveiliging
    if ([string]::IsNullOrWhiteSpace($TargetGroupId)) {

        Write-Error `
            "Lege GroupId voor '$TargetGroupName'. Gebruiker: $($User.DisplayName)"

        $ErrorCount++
        continue
    }

    try {

        # ----------------------------------------------------
        # Controleer of gebruiker al lid is
        # ----------------------------------------------------

        $IsMember = Get-MgGroupMember `
            -GroupId $TargetGroupId `
            -All `
            -ErrorAction Stop |
        Where-Object {
            $_.Id -eq $User.Id
        }

        if ($IsMember) {

            Write-Host `
                "Reeds lid: $($User.DisplayName) -> $TargetGroupName" `
                -ForegroundColor Yellow

            $AlreadyMemberCount++
        }
        else {

            # ------------------------------------------------
            # Gebruiker toevoegen
            # ------------------------------------------------

            New-MgGroupMember `
                -GroupId $TargetGroupId `
                -DirectoryObjectId $User.Id `
                -ErrorAction Stop

            Write-Host `
                "Toegevoegd: $($User.DisplayName) -> $TargetGroupName" `
                -ForegroundColor Green

            $AddedCount++
        }
    }
    catch {

        Write-Error `
            "Fout bij $($User.DisplayName): $($_.Exception.Message)"

        $ErrorCount++
    }
}

# ============================================================
# 8. Resultaat
# ============================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "      GROEPSYNCHRONISATIE VOLTOOID" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "Toegevoegd       : $AddedCount" -ForegroundColor Green
Write-Host "Reeds lid        : $AlreadyMemberCount" -ForegroundColor Yellow
Write-Host "Overgeslagen     : $SkippedCount" -ForegroundColor DarkYellow
Write-Host "Fouten           : $ErrorCount" -ForegroundColor Red

Write-Host "========================================" -ForegroundColor Cyan
