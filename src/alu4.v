`default_nettype none
//==============================================================================
// alu4 - Integra toda la logica combinacional de la calculadora
//------------------------------------------------------------------------------
// EXCLUSIVAMENTE compuertas (directas o a traves de los submodulos, que a su
// vez son solo compuertas). No aparece ni un +, -, <<, >>, ?:, if o case.
//
//                                +--------------+
//     a ---+------------------->|              |
//          |                    |   adder4     |--- sum ---+
//     b ---|--+---------------->| (sum/resta)  |           |
//          |  |     sub ------->|              |           |
//          |  |                 +--------------+           |
//          |  |                                            v
//          +--|---------------->[ shift_left4  ]--- shl -->[ result ]--- r
//          |  |                                            ^  select
//          +--|---------------->[ shift_right4 ]--- shr ---+     ^
//             |                                                  |
//    op ----->[ decoder3to8 ]--- w[7:0] one-hot -----------------+
//
// SELECCION DE OPERANDOS DEL SUMADOR
//   El mismo sumador cubre las tres operaciones aritmeticas cambiando lo que
//   entra por sus puertos:
//
//     op    operacion       x    y    sub
//     001   A + B           A    B     0
//     010   A - B           A    B     1
//     011   B - A           B    A     1      <- se intercambian los operandos
//
//   O sea: 'swap' vale 1 solo en resta inversa (w[3]), y 'sub' vale 1 en las
//   dos restas (w[2] o w[3]).
//
//   El Reinicio (op 000) no necesita nada aca: lo resuelve result_select
//   al no seleccionar ninguna via (ver ese archivo).
//==============================================================================
module alu4 (
    input  wire [3:0] a,        // primer operando  (op1)
    input  wire [3:0] b,        // segundo operando (op2 externo o resultado previo)
    input  wire [2:0] op,       // selector de operacion
    output wire [3:0] r,        // resultado (4 bits, con overflow truncado)
    output wire       cout      // acarreo de salida del sumador (informativo)
);

    // ------------------------------------------------------------------
    // 1) Decodificacion del selector a one-hot
    // ------------------------------------------------------------------
    wire [7:0] w;

    decoder3to8 u_dec (.sel(op), .w(w));

    // ------------------------------------------------------------------
    // 2) Senales de control del sumador
    // ------------------------------------------------------------------
    wire swap;   // 1 en resta inversa: intercambia los operandos
    wire sub;    // 1 en ambas restas: activa el complemento a dos

    buf u_swap (swap, w[3]);
    or  u_sub  (sub,  w[2], w[3]);

    // ------------------------------------------------------------------
    // 3) Preparacion de operandos e instancia del sumador/restador
    // ------------------------------------------------------------------
    wire [3:0] x_op, y_op, sum;

    mux2to1_4bit u_x (.a(a), .b(b), .s(swap), .y(x_op));  // swap=1 -> x = B
    mux2to1_4bit u_y (.a(b), .b(a), .s(swap), .y(y_op));  // swap=1 -> y = A

    adder4 u_add (
        .x    (x_op),
        .y    (y_op),
        .sub  (sub),
        .sum  (sum),
        .cout (cout)
    );

    // ------------------------------------------------------------------
    // 4) Desplazadores. El monto viene de los 2 bits bajos del segundo
    //    operando, tal como pide el enunciado (R = A despl. B[1:0]).
    // ------------------------------------------------------------------
    wire [3:0] shl, shr;

    shift_left4  u_shl (.din(a), .amount(b[1:0]), .dout(shl));
    shift_right4 u_shr (.din(a), .amount(b[1:0]), .dout(shr));

    // ------------------------------------------------------------------
    // 5) Seleccion final
    // ------------------------------------------------------------------
    result_select u_sel (
        .w   (w),
        .sum (sum),
        .shl (shl),
        .shr (shr),
        .r   (r)
    );

endmodule
`default_nettype wire
