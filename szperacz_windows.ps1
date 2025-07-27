#szperacz_windows.ps1 - dla Windows
# Krzysztof Lipa-Izdebski, Lipiec 2025
# Szuka wartości konta w plikach tekstowych (ignoruje .git, *.log, *.bak)

# funkcja Request-UserInput
# Pobiera dane wejściowe od użytkownika: nazwę konta oraz ścieżkę startową
# Ustawia domyślną ścieżkę na bieżący katalog (.) jeśli nic nie podano
function Request-UserInput {
    $global:accountName = Read-Host "Enter your application account name"
    $global:startPath = Read-Host "Enter the path from which to start the search (default: .)"
    if ([string]::IsNullOrWhiteSpace($startPath)) {
        $global:startPath = "."
    }
}

# funkcja Show-TableHeader
# Wyświetla nagłówki kolumn danych wyjściowych w formacie dwukolumnowym
function Show-TableHeader {
    "{0,-30} {1}" -f "Account Name", "File Path"
    "{0,-30} {1}" -f "------------", "---------"
}

# funkcja Search-AccountInFile
# Sprawdza, czy wskazany plik zawiera wartość konta (jako wartość, nie jako klucz)
# Jeśli tak, wypisuje konto i ścieżkę do pliku w formacie tabeli
function Search-AccountInFile {
    param (
        [string]$file
    )
    $content = Get-Content -Path $file -ErrorAction SilentlyContinue
    foreach ($line in $content) {
        if ($line -match '[:=]\s*["'']?' + [regex]::Escape($accountName) + '["'']?') {
            "{0,-30} {1}" -f $accountName, $file
            break
        }
    }
}

# funkcja Start-Search
# Przeszukuje podaną ścieżkę rekurencyjnie z pominięciem katalogów .git oraz plików *.log i *.bak
# Dla każdego znalezionego pliku tekstowego wywołuje func_grep_account
function Start-Search {
    Get-ChildItem -Path $startPath -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -notmatch '\.log$|\.bak$' -and
            $_.FullName -notmatch '\\\.git\\'
        } |
        ForEach-Object {
            try {
                # Sprawdzamy, czy plik wygląda na tekstowy
                $firstLine = Get-Content -Path $_.FullName -TotalCount 1 -ErrorAction Stop
                Search-AccountInFile -file $_.FullName
            } catch {
                # Pomiń pliki binarne, niedostępne lub inne błędy
            }
        }
}

# Główne wywołania
Request-UserInput
Show-TableHeader
Start-Search
