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

# Write initial header
"Searching for occurrences of '$searchPattern': " | Out-File -FilePath $outputFile -Encoding UTF8

# Get current directory path
$currentDir = (Get-Location).ProviderPath.TrimEnd('\')

# Recursively get all .json and .dll files
$files = Get-ChildItem -Path "." -Include *.json, *.dll -Recurse -File

foreach ($file in $files) {
    try {
        # Read file content based on extension
        if ($file.Extension -ieq ".json") {
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

        # Count occurrences (case-insensitive)
        $count = ([regex]::Matches($text, [regex]::Escape($searchPattern), "IgnoreCase")).Count

        if ($count -ge 1) {
            # Compute relative path
            $relativePath = $file.FullName.Replace("$currentDir\", "")
            "$relativePath - $count occurrences" | Out-File -FilePath $outputFile -Append -Encoding UTF8
        }
    }
    catch {
        "Error processing $($file.FullName): $_" | Out-File -FilePath $outputFile -Append -Encoding UTF8
    }
}

Write-Output "`nDone. Filtered results saved to $outputFile"
