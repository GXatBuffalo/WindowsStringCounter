# =======================
# CONFIGURATION SECTION
# =======================

# Output file name
$outputFile = "results.txt"

# The string to search for (case-insensitive)
$searchPattern = "ontimechange"

# =======================
# MAIN SCRIPT
# =======================

# Start fresh
"--- Pattern matches for '$searchPattern': ---" | Set-Content -Path $outputFile -Encoding UTF8

$currentDir = (Get-Location).ProviderPath.TrimEnd('\')
$files = Get-ChildItem -Path "." -Include *.json, *.dll, *.xml -Recurse -File

# Dictionary to track folder totals
$foundSubfolders = @{}

foreach ($file in $files) {
    try {
        # Read content based on extension
	if ($file.Extension -ieq ".json" -or $file.Extension -ieq ".xml") {
	    $text = [System.IO.File]::ReadAllText($file.FullName)
	}
	elseif ($file.Extension -ieq ".dll") {
            $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
            $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
            $text = ($ascii -split "`0|[^ -~]") -join "`n"
        }
        else {
            continue
        }

        # Count matches
        $count = ([regex]::Matches($text, [regex]::Escape($searchPattern), "IgnoreCase")).Count

        if ($count -ge 1) {
            # Get relative path
            $relativePath = $file.FullName.Replace("$currentDir\", "")

            # Determine immediate subfolder (first path component)
            $parts = $relativePath -split "[\\/]"
            $firstFolder = if ($parts.Length -gt 1) { "$($parts[0])\" } else { ".\" }

            # Track total per folder
            if (-not $foundSubfolders.ContainsKey($firstFolder)) {
                $foundSubfolders[$firstFolder] = 0
            }
            $foundSubfolders[$firstFolder] += $count

            # Write file-level result
            $line = "$relativePath - $count occurrences"
            Add-Content -Path $outputFile -Value $line
        }
    }
    catch {
        $errorLine = "Error processing $($file.FullName): $_"
        Add-Content -Path $outputFile -Value $errorLine
    }
}

# Write summary
if ($foundSubfolders.Count -gt 0) {
    Add-Content -Path $outputFile -Value ""
    Add-Content -Path $outputFile -Value "--- Per mod counts: ---"

    $foundSubfolders.GetEnumerator() |
        Sort-Object -Property Value -Descending |
        ForEach-Object {
            $summaryLine = "$($_.Key): $($_.Value) occurrences"
            Add-Content -Path $outputFile -Value $summaryLine
        }
}

Write-Output "`nDone. Results and summary saved to $outputFile"

