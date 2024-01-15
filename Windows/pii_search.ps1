param(
    [Parameter(Mandatory=$false)]
    [String[]]$Path,

    [Parameter(Mandatory=$false)]
    [switch]$Silent
)

$ErrorActionPreference = "SilentlyContinue"

$patterns = 
    '\d{3}[)]?[-| |.]\d{3}[-| |.]\d{4}', 
    '\d{3}[-| |.]\d{2}[-| |.]\d{4}'

Get-ChildItem -Recurse -Force -Path $Path | ?{ findstr.exe /mprc:. $_.FullName } | foreach {
    if ($pii = Select-String -Path $_.FullName -Pattern $patterns) {
        "PII found in $($_.FullName)"
	
        if (!$Silent) {
            $pii
        }
    }
}