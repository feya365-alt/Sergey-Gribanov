param(
    [string]$SessionId = "1539e5e6-8a3d-441b-bf97-8842dcfaa6ac"
)

$projectDir = "C:\Users\Honor\.claude\projects\c--Users-Honor-Documents----------------"
$transcriptPath = Join-Path $projectDir "$SessionId.jsonl"
$repoDir = "c:\Users\Honor\Documents\Сергей Грибанов"
$outFile = Join-Path $repoDir "переписка-с-claude.md"

if (-not (Test-Path $transcriptPath)) {
    Write-Output "Transcript not found: $transcriptPath"
    exit 1
}

$lines = Get-Content -Path $transcriptPath -Encoding UTF8
$output = New-Object System.Collections.Generic.List[string]
$output.Add("ПЕРЕПИСКА С CLAUDE")
$output.Add("Сессия: $SessionId")
$output.Add("Обновлено: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$output.Add("")

foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try {
        $obj = $line | ConvertFrom-Json -ErrorAction Stop
    } catch {
        continue
    }

    $role = $obj.message.role
    if (-not $role) { continue }

    $content = $obj.message.content
    $textParts = New-Object System.Collections.Generic.List[string]

    if ($content -is [string]) {
        $textParts.Add($content)
    } elseif ($content) {
        foreach ($block in $content) {
            if ($block.type -eq "text" -and $block.text) {
                $textParts.Add($block.text)
            }
        }
    }

    if ($textParts.Count -eq 0) { continue }

    $label = if ($role -eq "user") { "ПОЛЬЗОВАТЕЛЬ" } else { "CLAUDE" }
    $output.Add("=== $label ===")
    foreach ($t in $textParts) {
        $output.Add($t)
    }
    $output.Add("")
}

Set-Content -Path $outFile -Value ($output -join "`r`n") -Encoding UTF8

Set-Location $repoDir
git add -- "переписка-с-claude.md"
$status = git status --porcelain -- "переписка-с-claude.md"
if ($status) {
    git commit -m "chore: автосохранение переписки" | Out-Null
    git push | Out-Null
    Write-Output "Сохранено и запушено."
} else {
    Write-Output "Без изменений."
}
