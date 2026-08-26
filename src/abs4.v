`default_nettype none
//==============================================================================
// abs4 - Separa un numero en complemento a dos en signo y magnitud
//------------------------------------------------------------------------------
// El enunciado pide que el PRIMER display muestre el signo y el SEGUNDO el
// valor en hexadecimal. Para eso hay que separar el numero:
//
//   din = 0101 (+5)  ->  neg = 0, mag = 0101 -> se muestra " 5"
//   din = 1101 (-3)  ->  neg = 1, mag = 0011 -> se muestra "-3"
//
// El signo es directamente el bit mas significativo (bit de signo del
// complemento a dos). La magnitud de un negativo es su negacion:
//
//   -din = 0 - din
//
// que se calcula REUTILIZANDO otra vez el adder4 (x = 0000, y = din, sub = 1).
//
// Caso borde: din = 1000 (-8) no tiene positivo representable en 4 bits;
// su negacion vuelve a dar 1000, asi que el display muestra "-8". Es el
// comportamiento correcto para el rango -8..+7.
//==============================================================================
module abs4 (
    input  wire [3:0] din,
    output wire       neg,    // 1 si el numero es negativo
    output wire [3:0] mag     // magnitud (valor absoluto)
);

    wire [3:0] negado;

    // el signo es el bit 3
    buf u_neg (neg, din[3]);

    // negado = 0 - din
    adder4 u_negar (
        .x    (4'b0000),
        .y    (din),
        .sub  (1'b1),
        .sum  (negado),
        .cout ()
    );

    // si es negativo se muestra la negacion, si no el valor tal cual
    mux2to1_4bit u_sel (
        .a (din),
        .b (negado),
        .s (din[3]),
        .y (mag)
    );

endmodule
`default_nettype wire
