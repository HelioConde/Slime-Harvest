param([string]$WebUI = 'C:\IA-PixelArt\stable-diffusion-webui-amdgpu', [string]$Project = 'C:\FarmSlime')
$ErrorActionPreference = 'Stop'
Write-Output '=== GPU e VRAM do driver (WMI AdapterRAM pode truncar acima de 4 GB) ==='
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Video\*\0000' -ErrorAction SilentlyContinue | ForEach-Object {
    [pscustomobject]@{GPU=$_.DriverDesc;VRAMBytes=$_.'HardwareInformation.qwMemorySize'}
} | Format-Table
Get-CimInstance Win32_OperatingSystem | Select-Object FreePhysicalMemory,TotalVisibleMemorySize | Format-List
Get-CimInstance Win32_Process | Where-Object {$_.Name -match 'python|godot'} | Select-Object ProcessId,Name,CommandLine | Format-List
Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUProcessMemory -ErrorAction SilentlyContinue | Where-Object {$_.DedicatedUsage -gt 0} | Select-Object Name,DedicatedUsage,SharedUsage | Format-Table
Get-ChildItem (Join-Path $WebUI 'models') -Recurse -File | Where-Object Extension -in '.safetensors','.ckpt' | Select-Object FullName,Length | Format-Table
Get-ChildItem (Join-Path $WebUI 'extensions') | Select-Object Name
& (Join-Path $WebUI 'venv\Scripts\python.exe') -c 'import torch_directml as d; print([(i,d.device_name(i)) for i in range(d.device_count())])'
try { Invoke-RestMethod 'http://127.0.0.1:7860/sdapi/v1/cmd-flags' -TimeoutSec 3 | Select-Object use_directml,device_id,api,lowvram,no_half,no_half_vae } catch { Write-Output $_.Exception.Message }
git -C $Project remote -v
git -C $Project status --short
