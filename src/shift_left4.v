`default_nettype none
//==============================================================================
// shift_left4 - Barrel shifter a la izquierda, 0 a 3 posiciones
//------------------------------------------------------------------------------
// Rellena con ceros por la derecha. Construido EXCLUSIVAMENTE con muxes de
// compuertas: no se usa el operador '<<'.
//
// ESTRUCTURA (barrel shifter de 2 etapas):
//   Un desplazamiento de 0..3 se descompone en binario:  amount = 2*a1 + a0
//   Etapa 1: desplaza 1 posicion si amount[0] = 1
//   Etapa 2: desplaza 2 posiciones si amount[1] = 1
//   Encadenadas dan 0, 1, 2 o 3 posiciones.
//
//   amount | etapa1 | etapa2 | total
//     00   |   no   |   no   |   0
//     01   |   si   |   no   |   1
//     10   |   no   |   si   |   2
//     11   |   si   |   si   |   3
//
// El "desplazamiento" en si no cuesta compuertas: es solo re-cablear los bits.
// Lo unico que cuesta compuertas es el mux que decide si se aplica o no.
//==============================================================================
module shift_left4 (
    input  wire [3:0] din,
    input  wire [1:0] amount,
    output wire [3:0] dout
);

    // --- Etapa 1: << 1  (entra un 0 por la derecha) ---
    wire [3:0] shifted1;
    wire [3:0] stage1;

    assign shifted1 = {din[2], din[1], din[0], 1'b0};

    mux2to1_4bit u_stage1 (
        .a (din),          // amount[0] = 0 -> pasa sin desplazar
        .b (shifted1),     // amount[0] = 1 -> desplaza 1
        .s (amount[0]),
        .y (stage1)
    );

    // --- Etapa 2: << 2  (entran dos 0 por la derecha) ---
    wire [3:0] shifted2;

    assign shifted2 = {stage1[1], stage1[0], 2'b00};

    mux2to1_4bit u_stage2 (
        .a (stage1),       // amount[1] = 0 -> pasa sin desplazar
        .b (shifted2),     // amount[1] = 1 -> desplaza 2 mas
        .s (amount[1]),
        .y (dout)
    );

endmodule
`default_nettype wire
