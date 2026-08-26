# Proyecto 1 – Calculadora de 4 bits (Verilog + FPGA iCE40 HX1K)

Arquitectura de Computadores – 2026-2

## Integrantes
- Nombre 1
- Nombre 2
- Nombre 3

## Estructura del repositorio

```
src/                Módulos Verilog de la lógica combinacional y del registro
  full_adder.v       Sumador completo de 1 bit (compuertas)
  adder4.v           Sumador/restador de 4 bits, complemento a 2 (compuertas)
  mux2to1_1bit.v      Multiplexor 2:1 de 1 bit (compuertas)
  shift_left4.v       Barrel shifter izquierdo 0–3 posiciones (compuertas)
  shift_right4.v      Barrel shifter derecho 0–3 posiciones (compuertas)
  decoder3to8.v        Decodificador one-hot del selector de operación (compuertas)
  result_select.v      Selector final del resultado según la operación (compuertas)
  op2_select.v          Mux que elige entre op2 externo y resultado anterior
  alu4.v                 Integra todas las unidades combinacionales
  calculator_top.v        ALU + registro de 4 bits (único bloque secuencial)
  fpga_top.v               (a completar) Top level para la Go Board: botones, LEDs,
                           displays de 7 segmentos y máquina de estados de control
tb/
  tb_calculator_top.v  Testbench de ejemplo (editar con los valores dados en clase)
constraints/
  go_board.pcf         Plantilla de constraints de pines (VERIFICAR contra el .pcf
                       oficial de la Nandland Go Board antes de sintetizar)
docs/
  informe.md           Plantilla del informe a entregar en PDF
```

## Cómo correr la simulación (Icarus Verilog + GTKWave)

```bash
# Compilar
iverilog -o sim tb/tb_calculator_top.v src/*.v

# Simular (genera calculator_tb.vcd)
vvp sim

# Ver las señales
gtkwave calculator_tb.vcd
```

El testbench entregado (`tb/tb_calculator_top.v`) es una **plantilla de ejemplo**
que ya fue verificada (suma, resta, resta inversa, shift left, shift right).
**El día de la evaluación deben reemplazar los valores de `op1`, `op2_ext`,
`sel_op2_prev` y `op_sel` por los que indique el profesor/ayudante**, volver a
correr la simulación y mostrar el resultado en GTKWave.

## Cómo sintetizar y cargar en la FPGA (Nandland Go Board / iCE40 HX1K)

Con el flujo open-source (Yosys + nextpnr-ice40 + IceStorm):

```bash
yosys -p "synth_ice40 -top fpga_top -json calc.json" src/*.v
nextpnr-ice40 --hx1k --package vq100 --json calc.json --pcf constraints/go_board.pcf --asc calc.asc
icepack calc.asc calc.bin
iceprog calc.bin
```

(También pueden usar el IDE Lattice iCEcube2 / Diamond si lo prefieren; el
flujo lógico es el mismo: síntesis → place & route → bitstream → programar).

## Restricciones de diseño respetadas

- Toda la lógica **combinacional** (sumas, restas, shifts, selección de
  operación) está descrita **exclusivamente con compuertas primitivas**
  (`and`, `or`, `not`, `xor`), sin usar `+ - < > <= >= << >> ?: if case`.
- El **único** bloque `always` de todo el diseño de la ALU corresponde al
  flip-flop del registro de resultado (`calculator_top.v`), que es lógica
  **secuencial**, no combinacional, y por lo tanto no está alcanzado por
  la restricción. Incluso ese `always` no usa `if`: la decisión de
  "mantener valor / cargar nuevo resultado" también se resuelve con un
  mux hecho de compuertas.
