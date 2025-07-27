Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

# GUI: zapytanie o nazwę konta
$accountName = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Enter your application account name:",
    "Account name input",
    "app_account"
)

if ([string]::IsNullOrWhiteSpace($accountName)) {
    [System.Windows.Forms.MessageBox]::Show("No account name provided. Exiting.", "Aborted")
    exit
}

# GUI: wybór folderu startowego
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Select the folder to start the search:"
$folderBrowser.RootFolder = "MyComputer"

if ($folderBrowser.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    [System.Windows.Forms.MessageBox]::Show("No folder selected. Exiting.", "Aborted")
    exit
}
$startPath = $folderBrowser.SelectedPath

# Wyszukiwanie
$results = @()
Get-ChildItem -Path $startPath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -notmatch '\.log$|\.bak$' -and
        $_.FullName -notmatch '\\\.git\\'
    } |
    ForEach-Object {
        try {
            $lines = Get-Content $_.FullName -ErrorAction Stop
            foreach ($line in $lines) {
                if ($line -match '[:=]\s*["'']?' + [regex]::Escape($accountName) + '["'']?') {
                    $results += "{0,-30} {1}" -f $accountName, $_.FullName
                    break
                }
            }
        } catch {
            # ignorujemy błędy
        }
    }

# GUI z TextBoxem
$form = New-Object System.Windows.Forms.Form
$form.Text = "Search Results"
$form.Width = 800
$form.Height = 600

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Multiline = $true
$textBox.Dock = "Fill"
$textBox.ScrollBars = "Vertical"
$textBox.ReadOnly = $false
$textBox.Font = 'Consolas,10'

if ($results.Count -eq 0) {
    $textBox.Text = "No matches found."
} else {
    $textBox.Text = ($results -join "`r`n")
}

$form.Controls.Add($textBox)
$form.Add_Shown({ $textBox.Select(); $textBox.Focus() })
$form.ShowDialog() | Out-Null
