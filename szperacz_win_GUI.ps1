# szperacz_win_GUI.ps1 - dla Windows
# Krzysztof Lipa-Izdebski, Lipiec 2025

# Skrypt szuka wartości konta (tak naprawdę stringu) w plikach tekstowych
# Ignoruje .git, *.log, *.bak) - o ile tego chcesz - tam jest taki haczyk do odznaczenia :)

# Uwaga: raczej nie wskazuj do przeszukania całego dysku np D:/
# GUI daje taką możliwość i da się to zrobić, ale to słaby pomysł, naprawdę :)

# Jeżli otrzymałeś tyen kod w pliku szperacz_win_GUI.txt
# to: 
# 1) zamień nazwę pliku na szperacz_win_GUI.ps1
# 2) Uruchom powłokę poweshell i wykonaj:
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# 3) Przejdź do katalogu, w którym umieściłeś skrypt i wykonaj:
# ./szperacz_win_GUI.ps1

#STARTUJEMY! :)
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ==== SPLASH SCREEN ====
$splash = New-Object Windows.Window
$splash.WindowStyle = 'None'
$splash.ResizeMode = 'NoResize'
$splash.WindowStartupLocation = 'CenterScreen'
$splash.Width = 300
$splash.Height = 120
$splash.Topmost = $true

$panel = New-Object Windows.Controls.StackPanel
$panel.HorizontalAlignment = 'Center'
$panel.VerticalAlignment = 'Center'

$text = New-Object Windows.Controls.TextBlock
$text.Text = "Szperacz - GUI startuje..."
$text.FontSize = 16
$text.Margin = '0,20,0,0'
$text.HorizontalAlignment = 'Center'
$panel.Children.Add($text) | Out-Null
$splash.Content = $panel
$splash.Show()
Start-Sleep -Seconds 1.5
$splash.Close()

# ==== XAML UI ====
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Szperacz - Wyszukiwanie konta w plikach" Width="650" Height="500" ResizeMode="CanMinimize">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
            <TextBlock Text="Account name:" VerticalAlignment="Center" Margin="0,0,5,0"/>
            <TextBox Name="AccountBox" Width="200"/>
            <CheckBox Name="IgnoreCheck" Content="Ignore .log / .bak / .git" IsChecked="True" Margin="20,0,0,0"/>
        </StackPanel>

        <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,10">
            <TextBlock Text="Selected folder:" VerticalAlignment="Center" Margin="0,0,5,0"/>
            <TextBox Name="FolderBox" Width="400" IsReadOnly="True"/>
            <Button Name="BrowseButton" Content="Browse..." Margin="10,0,0,0" Width="80"/>
        </StackPanel>

        <Button Name="SearchButton" Grid.Row="2" Content="Start Search" Width="120" Height="30" Margin="0,0,0,10" HorizontalAlignment="Left"/>

        <TextBox Name="ResultBox" Grid.Row="3" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap"
                 FontFamily="Consolas" FontSize="12" IsReadOnly="False"/>

        <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,10,0,0">
            <Button Name="SaveButton" Content="Save to File" Width="100" Margin="0,0,10,0"/>
            <Button Name="CloseButton" Content="Close" Width="80"/>
        </StackPanel>
    </Grid>
</Window>
"@

# ==== PARSOWANIE XAML ====
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# ==== ELEMENTY UI ====
$accountBox  = $window.FindName("AccountBox")
$folderBox   = $window.FindName("FolderBox")
$browseBtn   = $window.FindName("BrowseButton")
$searchBtn   = $window.FindName("SearchButton")
$resultBox   = $window.FindName("ResultBox")
$saveBtn     = $window.FindName("SaveButton")
$closeBtn    = $window.FindName("CloseButton")
$ignoreCheck = $window.FindName("IgnoreCheck")

# ==== LOGIKA ====

$browseBtn.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $folderBox.Text = $dialog.SelectedPath
    }
})

$searchBtn.Add_Click({
    $resultBox.Clear()
    $account = $accountBox.Text.Trim()
    $folder  = $folderBox.Text.Trim()
    $ignore  = $ignoreCheck.IsChecked

    if (-not (Test-Path $folder)) {
        [System.Windows.MessageBox]::Show("Folder path is invalid.", "Error", 'OK', 'Error')
        return
    }
    if ([string]::IsNullOrWhiteSpace($account)) {
        [System.Windows.MessageBox]::Show("Account name is empty.", "Error", 'OK', 'Error')
        return
    }

    $results = @()

    Get-ChildItem -Path $folder -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        if ($ignore) {
            $_.Name -notmatch '\.log$|\.bak$' -and $_.FullName -notmatch '\\\.git\\'
        } else {
            $true
        }
    } | ForEach-Object {
        try {
            $lines = Get-Content $_.FullName -ErrorAction Stop
            foreach ($line in $lines) {
                if ($line -match '[:=]\s*["'']?' + [regex]::Escape($account) + '["'']?') {
                    $results += "{0,-30} {1}" -f $account, $_.FullName
                    break
                }
            }
        } catch {}
    }

    if ($results.Count -eq 0) {
        $resultBox.Text = "No matches found."
    } else {
        $resultBox.Text = ($results -join "`r`n")
    }
})

$saveBtn.Add_Click({
    $path = "$env:TEMP\szperacz_result_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $resultBox.Text | Out-File -FilePath $path -Encoding UTF8
    [System.Windows.MessageBox]::Show("Saved to:`n$path", "Saved")
})

$closeBtn.Add_Click({ $window.Close() })

# ==== START GUI ====
$window.ShowDialog() | Out-Null

#I KONIEC :)