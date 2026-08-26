# Proyecto 1 – Calculadora de 4 bits (Verilog + FPGA iCE40 HX1K)

Arquitectura de Computadores – 2026-2

## Integrantes
- Lucas Fernandez
- Maximiliano Ferrando
- Renato Rivadeneira
- Matias Ureta

---

## Qué hace

Calculadora de 4 bits en complemento a dos (rango −8 a +7) implementada sobre
una **Nandland Go Board** (Lattice iCE40 HX1K, package VQ100). Toda la lógica
combinacional está descrita **exclusivamente con compuertas**.

| Código | Operación | Resultado |
|---|---|---|
| `000` | Reinicio | `R = 0000` |
| `001` | Suma | `R = A + B` |
| `010` | Resta | `R = A − B` |
| `011` | Resta inversa | `R = B − A` |
| `100` | Shift left | `R = A << B[1:0]` |
| `101` | Shift right | `R = A >> B[1:0]` |

Si hay overflow se conservan sólo los cuatro bits menos significativos.

---

## Estructura del repositorio

```
src/                     Diseño
  -- Lógica combinacional de la calculadora: SOLO COMPUERTAS --
  mux2to1_1bit.v          Multiplexor 2:1 de 1 bit (bloque base)
  mux2to1_4bit.v          Multiplexor 2:1 de 4 bits
  full_adder.v            Sumador completo de 1 bit
  adder4.v                Sumador/restador de 4 bits, complemento a 2
  shift_left4.v           Barrel shifter izquierdo 0–3 posiciones
  shift_right4.v          Barrel shifter derecho 0–3 posiciones
  decoder3to8.v           Decodificador one-hot del selector de operación
  result_select.v         Selector final del resultado
  op2_select.v            Mux entre op2 externo y resultado anterior
  alu4.v                  Integra toda la lógica combinacional
  calculator_top.v        ALU + registro de 4 bits
  seg7_decoder.v          Hexadecimal → 7 segmentos (suma de mintérminos)
  abs4.v                  Separa signo y magnitud (reusa adder4)
  updown4.v               Incrementa/decrementa (reusa adder4)

  -- Interfaz con la placa: lógica secuencial --
  debounce.v              Antirrebote de los pulsadores
  edge_detect.v           Un pulso por apretón
  fsm_control.v           Máquina de estados de la interfaz
  fpga_top.v              Top level de la Go Board

tb/
  tb_calculator_top.v     Testbench principal — EDITAR EL DÍA DE LA EVALUACIÓN
  tb_alu4_exhaustivo.v    Verificación de las 2048 combinaciones posibles
  tb_fsm_control.v        Simulación de la secuencia de botones

constraints/
  go_board.pcf            Pinout oficial de Nandland (iCE40 HX1K / VQ100)

docs/
  informe.md              Plantilla del informe a entregar en PDF

tools/
  check_operadores.py     Verifica que no haya operadores prohibidos en src/

build.ps1                 Script de compilación
```

---

## Requisitos

**OSS CAD Suite** (Yosys + Icarus Verilog + nextpnr + IceStorm + GTKWave):
<https://github.com/YosysHQ/oss-cad-suite-build/releases>

Descargar el `.tgz` de Windows, extraerlo, y **cargar su entorno en cada
terminal nueva** (no conviene ponerlo en el PATH global: sus DLLs y su Python
pueden opacar los del sistema):

```powershell
. C:\Users\<usuario>\oss-cad-suite\environment.ps1
```

`build.ps1` ya hace esto solo. Si la ruta de instalación es distinta, hay que
editar la variable `$OSS` al principio del script.

---

## Cómo correr la simulación

Con el script:

```powershell
.\build.ps1 sim      # simula la calculadora y abre GTKWave
.\build.ps1 alu      # verificación exhaustiva de la ALU (2048 casos)
.\build.ps1 fsm      # simula la secuencia de botones
```

O a mano (ojo: en PowerShell hay que expandir `src\*.v`, porque no lo hace solo
al llamar programas externos):

```powershell
$SRC = Get-ChildItem src\*.v | ForEach-Object { 'src/' + $_.Name }
iverilog -g2012 -o sim tb/tb_calculator_top.v @SRC
vvp sim
gtkwave calculator_tb.vcd
```

### El día de la evaluación

El profesor va a dictar una operación y unos valores. Se editan **los cuatro
parámetros del bloque `EDITAR AQUI`** al principio de `tb/tb_calculator_top.v`:

```verilog
localparam [3:0] OP1          = 4'b0101;   // primer operando
localparam [3:0] OP2_EXT      = 4'b0011;   // segundo operando
localparam       SEL_OP2_PREV = 1'b0;      // 1 = usar el resultado anterior
localparam [2:0] OP_SEL       = 3'b001;    // operación
```

y se vuelve a correr `.\build.ps1 sim`.

---

## Cómo sintetizar y cargar en la FPGA

```powershell
.\build.ps1 synth    # genera calc.bin
.\build.ps1 prog     # lo carga en la placa
```

A mano:

```powershell
$SRC = (Get-ChildItem src\*.v | ForEach-Object { 'src/' + $_.Name }) -join ' '
yosys -q -p "read_verilog $SRC; synth_ice40 -top fpga_top -json calc.json"
nextpnr-ice40 --hx1k --package vq100 --json calc.json --pcf constraints/go_board.pcf --asc calc.asc
icepack calc.asc calc.bin
iceprog calc.bin
```

> **Cuidado:** no conectar la salida de `nextpnr-ice40` a un pipe que la corte
> (por ejemplo `| Select-Object -First 20`). Eso mata el proceso a medio
> escribir, deja el `.asc` truncado, y después `icepack` falla con un error
> engañoso (`Unknown nosleep setting`).

### Resultados de síntesis obtenidos

| Métrica | Valor |
|---|---|
| Celdas lógicas | 204 / 1280 (15 %) |
| Pines de E/S | 23 / 72 (31 %) |
| Frecuencia máxima | 168,5 MHz (la placa corre a 25 MHz) |
| Bitstream | 32.220 bytes |

---

## Driver de la placa en Windows (hacer una sola vez)

La Go Board se conecta por un chip FTDI FT2232H. Windows **no le instala driver
solo**: aparece en el Administrador de dispositivos como `Dual RS232-HS` con
error (código 28), y `iceprog` falla con `unable to open ftdi device`.

Para arreglarlo:

1. Descargar **Zadig** desde <https://zadig.akeo.ie>.
2. Abrirlo como administrador y marcar **Options → List All Devices**.
3. Seleccionar **`Dual RS232-HS (Interface 0)`** — *Interface 0*, no la 1 ni el
   dispositivo compuesto. El canal A es el que programa la FPGA.
4. Elegir driver **WinUSB** e instalar.
5. Desconectar y volver a conectar la placa.

Para verificar que quedó bien:

```powershell
Get-PnpDevice -PresentOnly | Where-Object InstanceId -like '*VID_0403*'
```

Cuando el estado diga `OK` en vez de `Error`, probar la comunicación:

```powershell
iceprog -t
```

Si responde con el ID de la memoria flash, la placa está lista para programar.

---

## Uso en la placa

| Botón | Función |
|---|---|
| Superior izquierdo | Incrementar el valor |
| Inferior izquierdo | Disminuir el valor |
| Superior derecho | Confirmar / ejecutar |
| Inferior derecho | Usar el resultado anterior como segundo operando |

Secuencia: se ingresa la **operación** (su código aparece en los LED) → se
ingresa **op1** → se ingresa **op2** (o se elige el resultado anterior) → se
**ejecuta** y aparece el resultado → al confirmar de nuevo se vuelve al inicio.

El display izquierdo muestra el **signo**; el derecho, el **valor en
hexadecimal**.

### Dos cosas a ajustar al probar por primera vez

Ambas están al principio de `src/fpga_top.v`, bien marcadas:

1. **Asignación de los botones.** No está documentado cuál switch físico es
   cuál. Cargar el diseño, apretar cada botón, ver qué hace, y si no calza
   intercambiar las cuatro líneas de `AJUSTE 1`.

2. **Polaridad de los displays.** Están configurados como ánodo común (se
   encienden en bajo). Si se ve el negativo del número, cambiar
   `SEG_ACTIVO_BAJO` a `1'b0` en `AJUSTE 2`.

---

## Restricciones de diseño

Toda la lógica **combinacional** de la calculadora (`alu4.v` y sus submódulos,
más `seg7_decoder.v`, `abs4.v` y `updown4.v`) usa **exclusivamente primitivas de
compuerta**: `and`, `or`, `not`, `xor`, `buf`. No aparece ningún operador de
alto nivel (`+ - < > <= >= << >> ?: if case`).

**Verificación:** la ALU se comparó contra un modelo de referencia de alto nivel
en las 2048 combinaciones posibles (16 × 16 × 8) — 0 errores.

Para comprobar que no se coló ningún operador prohibido al editar el código:

```powershell
py tools/check_operadores.py src
```

Las únicas dos ocurrencias esperadas son los `<=` de los dos flip-flops
(`calculator_top.v` y `edge_detect.v`), que son asignaciones no bloqueantes.

### Lo que no es puramente combinacional

- **El registro de resultado** (`calculator_top.v`) es el único bloque
  secuencial de la calculadora. Su lógica de próximo estado sí es de
  compuertas: el «mantener / cargar» es un mux y el reset son compuertas AND.
  El `<=` que aparece ahí es la asignación no bloqueante de Verilog, no el
  operador de comparación.

- **`debounce.v` y `fsm_control.v`** son la interfaz con los pulsadores físicos
  de la placa, no el cálculo. Usan Verilog conductual.

> ⚠️ **Confirmar con el profesor o un ayudante** que esta separación entre la
> lógica combinacional de la calculadora (compuertas) y la lógica secuencial de
> interfaz (conductual) es aceptable, antes de la entrega.
