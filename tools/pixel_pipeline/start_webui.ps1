param([string]$WebUI = 'C:\IA-PixelArt\stable-diffusion-webui-amdgpu', [int]$DeviceId = 0)
$ErrorActionPreference = 'Stop'
try {
    $null = Invoke-RestMethod 'http://127.0.0.1:7860/sdapi/v1/options' -TimeoutSec 3
    Write-Output 'API já disponível. Instância preservada.'
    exit 0
} catch { }
if (Get-NetTCPConnection -LocalPort 7860 -State Listen -ErrorAction SilentlyContinue) {
    throw 'Porta 7860 ocupada. Não iniciar segunda instância. Habilite --api no servidor existente.'
}
$python = Join-Path $WebUI 'venv\Scripts\python.exe'
if (-not (Test-Path $python)) { throw 'Ambiente existente do WebUI não encontrado.' }
New-Item -ItemType Directory -Force (Join-Path $PSScriptRoot 'data') | Out-Null
$p = Start-Process -FilePath $python -WorkingDirectory $WebUI -ArgumentList @('-u','launch.py','--skip-prepare-environment','--use-directml','--device-id',"$DeviceId",'--lowvram','--no-half','--no-half-vae','--opt-split-attention-v1','--api') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PSScriptRoot 'data\webui.stdout.log') -RedirectStandardError (Join-Path $PSScriptRoot 'data\webui.stderr.log') -PassThru
Write-Output "WebUI iniciando, PID $($p.Id). Logs em data. Nenhuma dependência instalada."
