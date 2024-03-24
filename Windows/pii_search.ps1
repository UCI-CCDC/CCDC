param(
    [Parameter(Mandatory=$false)]
    [String[]]$Path = "C:\",

    [Parameter(Mandatory=$false)]
    [switch]$Silent
)

$ErrorActionPreference = "SilentlyContinue"

$patterns = 
    '\b\d{3}[)]?[-| |.]\d{3}[-| |.]\d{4}\b', 
    '\b\d{3}[-| |.]\d{2}[-| |.]\d{4}\b',
    '\b\d+\s+[\w\s]+\s+(?:road|street|avenue|boulevard|court)\b'
$fileExtensions = "\.docx|\.doc|\.odt|\.xlsx|\.xls|\.ods|\.pptx|\.ppt|\.odp|\.pdf|\.mdb|\.accdb|\.sqlite3?|\.eml|\.msg|\.txt|\.csv|\.html?|\.xml|\.json"

Get-ChildItem -Recurse -Force -Path $Path | ?{$_.Extension -match $fileExtensions} | foreach {
    if ($pii = Select-String -Path $_.FullName -Pattern $patterns) {
        "PII found in $($_.FullName)"
	
        if (!$Silent) {
            $pii | select -ExpandProperty Matches | Sort-Object Value -Unique | select Value -ExpandProperty Value
        }
        Write-Output ""
    }
}
