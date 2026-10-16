# Execute dentro de C:\FarmSlime, depois de atualizar o repositorio.
$ErrorActionPreference = "Stop"
$repo = "C:\FarmSlime"
if (!(Test-Path (Join-Path $repo "project.godot"))) { throw "Projeto Godot nao encontrado em C:\FarmSlime" }
Set-Location $repo
Write-Host "Verifique alteracoes locais antes de prosseguir:"
git status --short
$answer = Read-Host "Copiar o wallpaper para este projeto? (S/N)"
if ($answer -notin @("s", "S")) { exit 0 }
$origin = Join-Path $PSScriptRoot "assets\ui\main_menu\vale_encantado.png"
$target = Join-Path $repo "assets\ui\main_menu\vale_encantado.png"
New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
Copy-Item -LiteralPath $origin -Destination $target -Force
Write-Host "Wallpaper instalado no Godot. Para enviar ao GitHub:"
Write-Host "git add assets/ui/main_menu/vale_encantado.png"
Write-Host "git commit -m 'assets(menu): add original valley wallpaper'"
Write-Host "git push origin main"
