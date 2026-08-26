`default_nettype none
//==============================================================================
// mux2to1_4bit - Multiplexor 2:1 de 4 bits
//------------------------------------------------------------------------------
// Cuatro mux2to1_1bit en paralelo compartiendo la misma senal de seleccion.
// No agrega logica nueva: es puro cableado de bloques ya hechos con compuertas.
//
//   s = 0  ->  y = a
//   s = 1  ->  y = b
//==============================================================================
module mux2to1_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       s,
    output wire [3:0] y
);

    mux2to1_1bit u_bit0 (.a(a[0]), .b(b[0]), .s(s), .y(y[0]));
    mux2to1_1bit u_bit1 (.a(a[1]), .b(b[1]), .s(s), .y(y[1]));
    mux2to1_1bit u_bit2 (.a(a[2]), .b(b[2]), .s(s), .y(y[2]));
    mux2to1_1bit u_bit3 (.a(a[3]), .b(b[3]), .s(s), .y(y[3]));

endmodule
`default_nettype wire
