# ==============================================================================
#  build.ps1 - Script de compilacion del Proyecto 1
# ==============================================================================
#  Uso (desde PowerShell, parado en la raiz del repositorio):
#
#     .\build.ps1 sim        simula la calculadora y abre GTKWave
#     .\build.ps1 alu        corre la verificacion exhaustiva de la ALU
#     .\build.ps1 fsm        simula la interfaz de botones
#     .\build.ps1 synth      sintetiza y genera el bitstream calc.bin
#     .\build.ps1 prog       carga el bitstream en la FPGA
#     .\build.ps1 clean      borra los archivos generados
#
#  Si PowerShell no deja ejecutar el script, correr una sola vez:
#     Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
# ==============================================================================

param(
    [ValidateSet('sim','alu','fsm','synth','prog','clean')]
    [string]$target = 'sim'
)

$ErrorActionPreference = 'Stop'

# --- Ubicacion de OSS CAD Suite -----------------------------------------------
$OSS = 'C:\Users\mpavi\oss-cad-suite'

if (-not (Test-Path "$OSS\environment.ps1")) {
    Write-Host "No se encontro OSS CAD Suite en $OSS" -ForegroundColor Red
    Write-Host "Editar la variable `$OSS al principio de este script." -ForegroundColor Red
    exit 1
}

. "$OSS\environment.ps1" | Out-Null
Set-Location $PSScriptRoot

# --- Lista de fuentes ---------------------------------------------------------
# PowerShell no expande 'src/*.v' al llamar programas externos (a diferencia de
# bash), asi que hay que armar la lista a mano.
$SRC = Get-ChildItem src\*.v | ForEach-Object { 'src/' + $_.Name }

function Fallar($msg) {
    Write-Host ""
    Write-Host $msg -ForegroundColor Red
    exit 1
}

switch ($target) {

    'sim' {
        Write-Host "==> Compilando testbench de la calculadora..." -ForegroundColor Cyan
        iverilog -g2012 -o sim tb/tb_calculator_top.v @SRC
        if ($LASTEXITCODE -ne 0) { Fallar "Fallo la compilacion." }

        Write-Host "==> Simulando..." -ForegroundColor Cyan
        vvp sim
        if ($LASTEXITCODE -ne 0) { Fallar "Fallo la simulacion." }

        Write-Host "==> Abriendo GTKWave..." -ForegroundColor Cyan
        Start-Process gtkwave -ArgumentList 'calculator_tb.vcd'
    }

    'alu' {
        Write-Host "==> Verificacion exhaustiva de la ALU (2048 casos)..." -ForegroundColor Cyan
        iverilog -g2012 -o sim_alu tb/tb_alu4_exhaustivo.v @SRC
        if ($LASTEXITCODE -ne 0) { Fallar "Fallo la compilacion." }
        vvp sim_alu
    }

    'fsm' {
        Write-Host "==> Simulando la interfaz de botones..." -ForegroundColor Cyan
        iverilog -g2012 -o sim_fsm tb/tb_fsm_control.v @SRC
        if ($LASTEXITCODE -ne 0) { Fallar "Fallo la compilacion." }
        vvp sim_fsm
    }

    'synth' {
        Write-Host "==> Sintesis con Yosys..." -ForegroundColor Cyan
        $lista = $SRC -join ' '
        yosys -q -p "read_verilog $lista; synth_ice40 -top fpga_top -json calc.json"
        if ($LASTEXITCODE -ne 0) { Fallar "Fallo la sintesis." }

        Write-Host "==> Place and route con nextpnr..." -ForegroundColor Cyan
        # OJO: NO conectar la salida de nextpnr a un pipe con Select-Object -First,
        # porque mata el proceso a medio escribir y deja el .asc truncado.
        nextpnr-ice40 --hx1k --package vq100 --json calc.json `
                      --pcf constraints/go_board.pcf --asc calc.asc
        if ($LASTEXITCODE -ne 0) { Fallar "Fallo el place and route." }

        Write-Host "==> Generando bitstream..." -ForegroundColor Cyan
        icepack calc.asc calc.bin
        if ($LASTEXITCODE -ne 0) { Fallar "Fallo icepack." }

        $tam = (Get-Item calc.bin).Length
        Write-Host ""
        Write-Host "Bitstream listo: calc.bin ($tam bytes)" -ForegroundColor Green
    }

    'prog' {
        if (-not (Test-Path calc.bin)) { Fallar "No existe calc.bin. Correr primero: .\build.ps1 synth" }

        Write-Host "==> Cargando en la FPGA..." -ForegroundColor Cyan
        iceprog calc.bin
        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "Si dice 'unable to open ftdi device', falta instalar el driver" -ForegroundColor Yellow
            Write-Host "WinUSB con Zadig en la Interface 0 de la placa. Ver el README." -ForegroundColor Yellow
            exit 1
        }
    }

    'clean' {
        Remove-Item sim,sim_alu,sim_fsm,calc.json,calc.asc,calc.bin,nextpnr.log `
                    -ErrorAction SilentlyContinue
        Remove-Item *.vcd -ErrorAction SilentlyContinue
        Write-Host "Limpio." -ForegroundColor Green
    }
}
