`default_nettype none
//==============================================================================
// shift_right4 - Barrel shifter a la derecha, 0 a 3 posiciones
//------------------------------------------------------------------------------
// Rellena con ceros por la izquierda (desplazamiento LOGICO, no aritmetico,
// tal como pide el enunciado). Construido EXCLUSIVAMENTE con muxes de
// compuertas: no se usa el operador '>>'.
//
// Misma estructura de 2 etapas que shift_left4, pero re-cableando en el
// sentido contrario.
//==============================================================================
module shift_right4 (
    input  wire [3:0] din,
    input  wire [1:0] amount,
    output wire [3:0] dout
);

    // --- Etapa 1: >> 1  (entra un 0 por la izquierda) ---
    wire [3:0] shifted1;
    wire [3:0] stage1;

    assign shifted1 = {1'b0, din[3], din[2], din[1]};

    mux2to1_4bit u_stage1 (
        .a (din),
        .b (shifted1),
        .s (amount[0]),
        .y (stage1)
    );

    // --- Etapa 2: >> 2  (entran dos 0 por la izquierda) ---
    wire [3:0] shifted2;

    assign shifted2 = {2'b00, stage1[3], stage1[2]};

    mux2to1_4bit u_stage2 (
        .a (stage1),
        .b (shifted2),
        .s (amount[1]),
        .y (dout)
    );

endmodule
`default_nettype wire
