param([Parameter(Mandatory=$true)][string]$Export, [string]$Godot = 'C:\godot\Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $Export 'project.godot'))) { throw 'Use um projeto de prévia exportado pelo pipeline.' }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'tests\godot_import_test.gd') -Destination (Join-Path $Export 'pipeline_import_test.gd')
& $Godot --headless --path $Export --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Falha na importação.' }
$result = & $Godot --headless --path $Export --script res://pipeline_import_test.gd 2>&1
$result | Write-Output
if ($LASTEXITCODE -ne 0 -or -not ($result -match 'PIXEL_PIPELINE_IMPORT_OK')) { throw 'Falha no teste do recurso Godot.' }
