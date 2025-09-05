
function Get-SmartData {
    $output = smartctl -A C: | Out-String
    $smartValues = @{}

    foreach ($line in $output -split "`n") {
        if ($line -match "Temperature") { $smartValues["Temperature"] = $line -split "\s+" | Select-Object -Last 1 }
        elseif ($line -match "Reallocated_Sector_Ct") { $smartValues["Reallocated Sectors"] = $line -split "\s+" | Select-Object -Last 1 }
        elseif ($line -match "Power_On_Hours") { $smartValues["Power-On Hours"] = $line -split "\s+" | Select-Object -Last 1 }
    }

    return $smartValues
}

# Function to determine health status
function Get-HealthStatus {
    param ($Temp, $Sectors)
    if ($Temp -gt 50 -or $Sectors -gt 5) { return "Critical", "Red" }
    elseif ($Temp -gt 40 -or $Sectors -gt 1) { return "Warning", "Yellow" }
    else { return "Good", "Green" }
}

# Function to log results
function Log-Results {
    param ($SmartData, $Status)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp | Status: $Status | Data: $($SmartData | Out-String)"
    Add-Content -Path "C:\disk_health_log.txt" -Value $entry
}

# Function to send notification
function Send-Alert {
    param ($Status)
    if ($Status -eq "Critical") {
        [System.Windows.Forms.MessageBox]::Show("Your disk health is CRITICAL! Backup your data immediately.", "Hard Drive Alert", "OK", "Error")
    }
}

# Create GUI Window
$smartData = Get-SmartData
if ($smartData.Count -eq 0) { Write-Host "SMART data unavailable"; exit }

$status, $color = Get-HealthStatus -Temp $smartData["Temperature"] -Sectors $smartData["Reallocated Sectors"]
Log-Results -SmartData $smartData -Status $status
Send-Alert -Status $status

$form = New-Object System.Windows.Forms.Form
$form.Text = "Hard Drive Health Monitor"
$form.Size = New-Object System.Drawing.Size(450,400)

$label = New-Object System.Windows.Forms.Label
$label.Text = "Status: $status"
$label.ForeColor = [System.Drawing.Color]::$color
$label.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Bold)
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(20,20)
$form.Controls.Add($label)

# Create Chart
$chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$chart.Size = New-Object System.Drawing.Size(400,250)
$chart.Location = New-Object System.Drawing.Point(20,50)
$chart.ChartAreas.Add("Default")

$series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
$series.Name = "SMART Attributes"
$series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Bar

foreach ($key in $smartData.Keys) {
    $series.Points.AddXY($key, $smartData[$key])
}

$chart.Series.Add($series)
$form.Controls.Add($chart)

$form.ShowDialog()

Add-Type -AssemblyName System.Windows.Forms