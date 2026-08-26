`default_nettype none
//==============================================================================
// decoder3to8 - Decodificador one-hot del selector de operacion
//------------------------------------------------------------------------------
// Convierte el codigo de operacion de 3 bits en 8 senales mutuamente
// excluyentes (one-hot): exactamente una vale 1 a la vez.
// Construido EXCLUSIVAMENTE con compuertas.
//
//   sel  | w activa | operacion
//   000  |  w[0]    | Reinicio       R = 0000
//   001  |  w[1]    | Suma           R = A + B
//   010  |  w[2]    | Resta          R = A - B
//   011  |  w[3]    | Resta inversa  R = B - A
//   100  |  w[4]    | Shift left     R = A << B[1:0]
//   101  |  w[5]    | Shift right    R = A >> B[1:0]
//   110  |  w[6]    | (no usado -> se trata como shift left)
//   111  |  w[7]    | (no usado -> se trata como shift right)
//
// Cada salida es un minterm de 3 variables:
//   w[k] = producto de sel[2],sel[1],sel[0] negados segun la posicion de k.
//
// Tener las senales en one-hot es lo que despues permite que result_select
// sea una simple estructura AND-OR, y que el Reinicio salga GRATIS (ver
// result_select.v).
//==============================================================================
module decoder3to8 (
    input  wire [2:0] sel,
    output wire [7:0] w
);

    wire n2, n1, n0;    // complementos de cada bit del selector

    not u_n2 (n2, sel[2]);
    not u_n1 (n1, sel[1]);
    not u_n0 (n0, sel[0]);

    and u_w0 (w[0], n2,     n1,     n0    );   // 000
    and u_w1 (w[1], n2,     n1,     sel[0]);   // 001
    and u_w2 (w[2], n2,     sel[1], n0    );   // 010
    and u_w3 (w[3], n2,     sel[1], sel[0]);   // 011
    and u_w4 (w[4], sel[2], n1,     n0    );   // 100
    and u_w5 (w[5], sel[2], n1,     sel[0]);   // 101
    and u_w6 (w[6], sel[2], sel[1], n0    );   // 110
    and u_w7 (w[7], sel[2], sel[1], sel[0]);   // 111

endmodule
`default_nettype wire
