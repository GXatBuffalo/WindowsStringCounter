# Get all files in subdirectories (excluding the current directory)
$files = Get-ChildItem -File -Recurse | Where-Object { $_.DirectoryName -ne (Get-Location).Path }
$rootPath = Get-Location

# Output file for results
$outputFile = "modresults.txt"

# Clear previous results if file exists
if (Test-Path $outputFile) { Remove-Item $outputFile }

# Track immediate subfolders where matches are found
$foundSubfolders = @{}

foreach ($file in $files) {
    try {
        $content = ""
        
        # Read text files normally
        if ($file.Extension -match '\.(txt|log|config|cs|xml|json|html|js|css|ps1|psm1)$') {
            try {
                $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
            }
            catch {
                Add-Content -Path $outputFile -Value "Could not read JSON file: $($file.FullName)"
                $content = ""
            }
        }
        else {
            # Read binary files safely
            $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
            
            # Try different text encodings
            $utf8 = [System.Text.Encoding]::UTF8.GetString($bytes)
            $utf16 = [System.Text.Encoding]::Unicode.GetString($bytes)
            $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
            
            # Convert binary to hex for deep scanning
            $hexString = ([BitConverter]::ToString($bytes)) -replace "-", ""
            
            # Combine potential representations
            $content = "$utf8 `n $utf16 `n $ascii `n $hexString"
        }

        # Search for occurrences of 'ontimechange' in different formats
        $matches = ([regex]::Matches($content, "ontimechange", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
        
        if ($matches -gt 0) {
            $relativePath = $file.FullName.Replace($rootPath.Path + "\", "")
            $result = "Found in: $relativePath - Occurrences: $matches"
            Add-Content -Path $outputFile -Value $result
            
            # Extract immediate subfolder name
            $relativeFolder = Split-Path -Path $relativePath -Parent
            if ($relativeFolder -and $relativeFolder -ne "") {
                $subfolder = $relativeFolder -split "\\" | Select-Object -First 1
                if ($subfolder) {
                    if (-not $foundSubfolders.ContainsKey($subfolder)) {
                        $foundSubfolders[$subfolder] = 0
                    }
                    $foundSubfolders[$subfolder] += $matches
                }
            }
        }
    }
    catch {
        $relativePath = $file.FullName.Replace($rootPath.Path + "\", "")
        $warningMsg = "Could not read file: $relativePath"
        Add-Content -Path $outputFile -Value $warningMsg
    }
}

# Print subfolders where matches were found with their total occurrences after all files have been checked
if ($foundSubfolders.Count -gt 0) {
    Add-Content -Path $outputFile -Value "`nSubfolders with matches:"
    foreach ($subfolder in $foundSubfolders.Keys) {
        $subfolderResult = "Match found in subfolder: $subfolder - Total Occurrences: $($foundSubfolders[$subfolder])"
        Add-Content -Path $outputFile -Value $subfolderResult
    }
}
