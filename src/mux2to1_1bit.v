`default_nettype none
//==============================================================================
// mux2to1_1bit - Multiplexor 2:1 de 1 bit
//------------------------------------------------------------------------------
// Bloque base de todo el diseno. Construido EXCLUSIVAMENTE con compuertas.
//
//   s = 0  ->  y = a
//   s = 1  ->  y = b
//
// Tabla de verdad:
//   s  a  b | y
//   0  0  x | 0
//   0  1  x | 1
//   1  x  0 | 0
//   1  x  1 | 1
//
// Expresion booleana:   y = (a AND NOT s) OR (b AND s)
//==============================================================================
module mux2to1_1bit (
    input  wire a,
    input  wire b,
    input  wire s,
    output wire y
);

    wire ns;        // NOT s
    wire a_sel;     // a AND NOT s
    wire b_sel;     // b AND s

    not u_ns    (ns,    s);
    and u_a_sel (a_sel, a, ns);
    and u_b_sel (b_sel, b, s);
    or  u_y     (y,     a_sel, b_sel);

endmodule
`default_nettype wire
