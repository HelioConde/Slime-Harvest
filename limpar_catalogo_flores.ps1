# Slimekeepers: Lost Valley - atualiza apenas ObjectCatalog.tscn.
# Preserva World.tscn, HouseBuilder.tscn, arquivos excluidos e todos os saves.
# Execucao padrao: apenas verifica (sem gravar).
# Para aplicar: powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\limpar_catalogo_flores.ps1 -Apply
param([switch]$Apply)
$ErrorActionPreference = 'Stop'

$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
    throw 'Abra o terminal na pasta do repositorio Git antes de executar.'
}
$repoRoot = $repoRoot.Trim()
Set-Location -LiteralPath $repoRoot
$catalogRelative = 'scenes/objects/ObjectCatalog.tscn'
$catalogPath = Join-Path $repoRoot 'scenes\objects\ObjectCatalog.tscn'
if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
    throw 'ObjectCatalog.tscn nao foi encontrado. Nada alterado.'
}

# Usar exatamente as cenas de flores excluidas e JA colocadas no stage pelo usuario.
$deleted = @(& git diff --cached --name-only --diff-filter=D -- scenes/objects/flowers)
if ($LASTEXITCODE -ne 0 -or $deleted.Count -ne 22) {
    throw "Esperava exatamente 22 flores excluidas no stage; encontrei $($deleted.Count). Nada alterado."
}
$original = [System.IO.File]::ReadAllText($catalogPath)
$updated = $original
$resourceIds = @()
foreach ($relative in $deleted) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($relative)
    if ($name -notmatch '^flower_(warm|cool)_\d\d$') {
        throw "Cena inesperada: $name. Nada alterado."
    }
    $escapedName = [regex]::Escape($name)
    $pattern = '(?m)^\[ext_resource\b[^\r\n]*path="res://scenes/objects/flowers/' + $escapedName + '\.tscn"[^\r\n]*id="(?<id>[^"]+)"\]\r?\n'
    $found = @([regex]::Matches($updated, $pattern))
    if ($found.Count -ne 1) {
        throw "Esperava 1 referencia externa para $name; encontrei $($found.Count). Nada alterado."
    }
    $resourceIds += $found[0].Groups['id'].Value
    $updated = [regex]::Replace($updated, $pattern, '')
}

foreach ($id in $resourceIds) {
    $escapedId = [regex]::Escape($id)
    # No catalogo atual, cada objeto removido tem apenas posicao como propriedade.
    $pattern = '(?m)^\[node\b[^\r\n]*instance=ExtResource\("' + $escapedId + '"\)\]\r?\nposition = Vector2\([^\r\n]*\)\r?\n(?:\r?\n)?'
    $found = @([regex]::Matches($updated, $pattern))
    if ($found.Count -ne 1) {
        throw "Esperava 1 instancia para $id; encontrei $($found.Count). Nada alterado."
    }
    $updated = [regex]::Replace($updated, $pattern, '')
}
foreach ($id in $resourceIds) {
    if ($updated.Contains('ExtResource("' + $id + '")')) {
        throw "Referencia pendente para $id. Nada alterado."
    }
}
if ($updated -eq $original) { throw 'Nenhuma modificacao necessaria.' }

Write-Host "Pronto para remover $($deleted.Count) referencias e $($resourceIds.Count) instancias do catalogo." -ForegroundColor Cyan
Write-Host 'As 6 flores principais, World.tscn e HouseBuilder.tscn ficam intactos.'
if (-not $Apply) {
    Write-Host 'SIMULACAO: nenhuma alteracao gravada. Use -Apply para aplicar.' -ForegroundColor Yellow
    exit 0
}

$backupPath = $catalogPath + '.bak-before-flower-cleanup'
if (Test-Path -LiteralPath $backupPath) {
    throw "Ja existe um backup: $backupPath. Renomeie-o antes de repetir para nao sobrescrever."
}
[System.IO.File]::Copy($catalogPath, $backupPath)
[System.IO.File]::WriteAllText($catalogPath, $updated, [System.Text.UTF8Encoding]::new($false))
Write-Host "Catalogo corrigido. Backup: $backupPath" -ForegroundColor Green
Write-Host 'Verifique antes de commitar: git diff -- scenes/objects/ObjectCatalog.tscn'
