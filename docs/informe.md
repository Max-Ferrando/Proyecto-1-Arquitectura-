# Informe – Proyecto 1: Calculadora de 4 bits

**Arquitectura de Computadores – Semestre 2026-2**
Universidad de los Andes – Facultad de Ingeniería y Ciencias Aplicadas
Profesor: Jorge Gómez Mir

**Integrantes:** Lucas Fernández, Maximiliano Ferrando, Renato Rivadeneira, Matías Ureta

---

> **Cómo usar esta plantilla**
> Este archivo es el esqueleto del informe que hay que entregar **en PDF**.
> Las secciones marcadas con 🔴 **FALTA** son las que el grupo tiene que
> completar a mano — principalmente los mapas de Karnaugh, que son el ítem
> más pesado de la rúbrica (1,5 de 6,0 puntos).
> Al terminar, exportar a PDF y dejarlo en `docs/informe.pdf`.

---

## Rúbrica y dónde se responde cada ítem

| Ítem | Puntaje | Sección de este informe |
|---|---|---|
| Diseño general y arquitectura de la calculadora | 0,5 | 1 y 2 |
| Tablas de verdad, mapas de Karnaugh y expresiones booleanas | 1,5 | 4 |
| Implementación de las operaciones mediante compuertas | 1,0 | 5 |
| Testbench, simulación y GTKWave | 1,0 | *(presencial)* — ver sección 6 |
| Funcionamiento completo en la FPGA | 2,0 | *(presencial)* — ver sección 7 |

---

## 1. Diseño general

La calculadora opera sobre números de 4 bits en **complemento a dos**
(rango −8 a +7). Recibe:

- `op1` — primer operando, 4 bits.
- `op_sel` — selector de operación, 3 bits.
- `sel_op2_prev` — selector de 1 bit del segundo operando: `0` toma el operando
  externo `op2_ext`, `1` toma el resultado de la operación anterior.
- `ejecutar` — señal que confirma la operación y carga el registro.

y entrega un resultado de 4 bits almacenado en un registro.

Si una operación produce *overflow*, se conservan solamente los cuatro bits
menos significativos, tal como pide el enunciado. Por ejemplo, `5 + 3 = 8`, que
no es representable en 4 bits con signo, queda como `1000` = −8.

### Decisión de diseño central: un solo sumador

En lugar de construir un circuito distinto por operación, el diseño usa **un
único sumador ripple-carry de 4 bits**, reutilizado en las tres operaciones
aritméticas cambiando únicamente lo que entra por sus puertos:

| Operación | Código | `x` | `y` | `sub` |
|---|---|---|---|---|
| Suma | `001` | A | B | 0 |
| Resta | `010` | A | B | 1 |
| Resta inversa | `011` | B | A | 1 |

Esto reduce el área del circuito y concentra el análisis booleano en un solo
bloque (el sumador completo de 1 bit), que después se replica cuatro veces.

🔴 **FALTA:** agregar un diagrama de bloques del sistema completo.

---

## 2. Arquitectura y jerarquía de módulos

```
fpga_top                    top level de la placa
├── debounce        x4      antirrebote de los pulsadores
├── edge_detect     x4      un pulso por apretón
├── fsm_control            máquina de estados de la interfaz
│   └── updown4     x3      incrementa/decrementa (reusa adder4)
├── calculator_top         CALCULADORA (lo que pide la sección 2 del enunciado)
│   ├── op2_select          mux op2 externo / resultado anterior
│   ├── alu4                lógica combinacional completa
│   │   ├── decoder3to8      selector de operación → one-hot
│   │   ├── mux2to1_4bit x2  selección de operandos del sumador
│   │   ├── adder4           sumador/restador (4x full_adder)
│   │   ├── shift_left4      barrel shifter izquierdo
│   │   ├── shift_right4     barrel shifter derecho
│   │   └── result_select    selección final del resultado
│   └── (registro de 4 bits — único bloque secuencial de la calculadora)
├── abs4                   separa signo y magnitud (reusa adder4)
└── seg7_decoder           hexadecimal → 7 segmentos
```

---

## 3. Codificación de las operaciones

| Código | Operación | Resultado |
|---|---|---|
| `000` | Reinicio | `R = 0000` |
| `001` | Suma | `R = A + B` |
| `010` | Resta | `R = A − B` |
| `011` | Resta inversa | `R = B − A` |
| `100` | Shift left | `R = A << B[1:0]` |
| `101` | Shift right | `R = A >> B[1:0]` |
| `110` | *(no usado)* | se comporta como shift left |
| `111` | *(no usado)* | se comporta como shift right |

Se mantiene la codificación propuesta en el enunciado.

---

## 4. Tablas de verdad, mapas de Karnaugh y expresiones booleanas

### 4.1 Sumador completo de 1 bit (`full_adder`)

| a | b | cin | s | cout |
|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 |
| 0 | 0 | 1 | 1 | 0 |
| 0 | 1 | 0 | 1 | 0 |
| 0 | 1 | 1 | 0 | 1 |
| 1 | 0 | 0 | 1 | 0 |
| 1 | 0 | 1 | 0 | 1 |
| 1 | 1 | 0 | 0 | 1 |
| 1 | 1 | 1 | 1 | 1 |

**Suma de mintérminos:**

- `s    = a'b'c + a'bc' + ab'c' + abc`
- `cout = a'bc + ab'c + abc' + abc`

**Expresiones minimizadas:**

- `s    = a ⊕ b ⊕ cin`
- `cout = ab + a·cin + b·cin`  → implementada como `ab + (a⊕b)·cin`

🔴 **FALTA:** dibujar los dos mapas de Karnaugh de 3 variables (uno para `s`,
otro para `cout`) mostrando las agrupaciones que llevan a las expresiones de
arriba. El de `s` no agrupa (es el patrón de tablero de ajedrez del XOR); el de
`cout` agrupa tres pares.

### 4.2 Resta por complemento a dos

En complemento a dos, `−y = (NOT y) + 1`, de donde:

```
x − y = x + (NOT y) + 1
```

El `NOT y` se obtiene con un XOR usado como **inversor controlado**
(`y ⊕ sub`), y el `+1` se inyecta gratis por el *carry-in* de la primera etapa
(`cin = sub`). Por eso el mismo circuito hace suma y resta.

🔴 **FALTA:** verificar a mano dos o tres casos numéricos (ej. `5 − 3` y
`3 − 5`) mostrando los acarreos etapa por etapa.

### 4.3 Decodificador del selector de operación (`decoder3to8`)

Cada salida es un mintérmino de las tres variables del selector:

```
w0 = s2'·s1'·s0'      w4 = s2·s1'·s0'
w1 = s2'·s1'·s0       w5 = s2·s1'·s0
w2 = s2'·s1·s0'       w6 = s2·s1·s0'
w3 = s2'·s1·s0        w7 = s2·s1·s0
```

No requiere minimización: por definición son mintérminos.

### 4.4 Selección final del resultado (`result_select`)

```
sel_sum = w1 + w2 + w3
sel_shl = w4 + w6
sel_shr = w5 + w7

r[i] = sum[i]·sel_sum + shl[i]·sel_shl + shr[i]·sel_shr
```

**Observación que conviene destacar:** la operación de **Reinicio no consume ni
una compuerta extra**. Cuando el selector vale `000` se activa `w0`, que no
participa en ninguna de las tres señales de selección; entonces las tres valen
0, todos los AND dan 0 y el OR final entrega `0000`. El reinicio es la
consecuencia natural de no seleccionar ninguna vía.

### 4.5 Decodificador de 7 segmentos (`seg7_decoder`)

La tabla de verdad completa (16 filas × 7 salidas) está en el encabezado de
`src/seg7_decoder.v`.

La implementación actual está en **forma canónica** (suma de todos los
mintérminos), que es exactamente el punto de partida de un mapa de Karnaugh.

🔴 **FALTA:** minimizar las 7 funciones (`a` … `g`) con mapas de Karnaugh de
4 variables. Es el bloque con más trabajo de K-maps del proyecto y donde está
la mayor parte de los 1,5 puntos. Una vez minimizadas, se pueden reemplazar
los `or` de `seg7_decoder.v` por las expresiones reducidas.

---

## 5. Implementación mediante compuertas

Toda la lógica combinacional de la calculadora (`src/alu4.v` y sus submódulos)
está descrita **exclusivamente** con primitivas de compuerta de Verilog:
`and`, `or`, `not`, `xor`, `buf`. No aparece ningún operador de alto nivel
(`+`, `-`, `<`, `>`, `<=`, `>=`, `<<`, `>>`, `?:`, `if`, `case`).

### Sobre el registro de resultado

El registro es lógica **secuencial**, no combinacional, por lo que no está
alcanzado por la restricción. Aun así se implementó lo más cerca posible del
espíritu del enunciado:

- la decisión «mantener el valor / cargar el nuevo resultado» se resuelve con un
  `mux2to1_4bit` hecho de compuertas, no con un `if`;
- el reset síncrono se aplica con compuertas `AND`, no con un `if`;
- el bloque `always` contiene únicamente la transferencia del flip-flop.

El operador `<=` que aparece ahí es la **asignación no bloqueante** de Verilog
(la forma estándar de describir un flip-flop), no el operador de comparación
«menor o igual».

### Sobre los módulos de interfaz

`debounce.v` y `fsm_control.v` son lógica secuencial de interfaz con la placa
(filtrado de rebotes de los pulsadores y secuenciamiento de la pantalla), no
forman parte del cálculo. Por eso usan Verilog conductual.

🔴 **CONFIRMAR CON EL PROFESOR O UN AYUDANTE** que esta separación es
aceptable, antes de la entrega.

---

## 6. Testbench, simulación y GTKWave

### Verificación exhaustiva

La ALU se verificó contra un modelo de referencia de alto nivel en **las 2048
combinaciones posibles** (16 valores de A × 16 de B × 8 operaciones):

```
  casos probados : 2048
  errores        : 0
  RESULTADO      : TODO CORRECTO
```

Se reproduce con:

```
.\build.ps1 alu
```

🔴 **FALTA:** pegar una captura de pantalla de GTKWave mostrando las señales.

### Durante la evaluación

El profesor indicará operación y valores. Se editan los cuatro parámetros del
bloque `EDITAR AQUI` al principio de `tb/tb_calculator_top.v`, se vuelve a
correr la simulación y se muestra el resultado en GTKWave.

---

## 7. Funcionamiento en la FPGA

### Resultados de síntesis

| Métrica | Valor |
|---|---|
| Dispositivo | Lattice iCE40 HX1K, package VQ100 |
| Celdas lógicas | 204 / 1280 (15 %) |
| Pines de E/S | 23 / 72 (31 %) |
| Frecuencia máxima | 168,5 MHz (la placa corre a 25 MHz) |
| Tamaño del bitstream | 32.220 bytes |

### Interfaz de botones

| Botón | Función |
|---|---|
| Superior izquierdo | Incrementar el valor |
| Inferior izquierdo | Disminuir el valor |
| Superior derecho | Confirmar / ejecutar |
| Inferior derecho | Usar el resultado anterior como segundo operando |

Secuencia de uso: se ingresa la operación (se muestra en los LED) → se ingresa
`op1` (se muestra en el display) → se ingresa `op2` o se elige el resultado
anterior → se ejecuta y se muestra el resultado → al confirmar de nuevo se
vuelve al inicio.

El display izquierdo muestra el **signo** y el derecho el **valor en
hexadecimal**.

🔴 **FALTA:** fotos o video de la placa funcionando.

---

## 8. Conclusiones

🔴 **FALTA:** escribir. Temas que vale la pena mencionar:

- Cómo la reutilización de un solo sumador simplificó el diseño.
- Qué se aprendió sobre el complemento a dos al implementarlo con compuertas.
- Dificultades encontradas (rebote de los pulsadores, polaridad de los
  displays, overflow de 4 bits).
