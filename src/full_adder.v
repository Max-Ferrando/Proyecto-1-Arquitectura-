`default_nettype none
//==============================================================================
// full_adder - Sumador completo de 1 bit
//------------------------------------------------------------------------------
// Construido EXCLUSIVAMENTE con compuertas.
//
// Tabla de verdad:
//   a  b  cin | s  cout
//   0  0   0  | 0   0
//   0  0   1  | 1   0
//   0  1   0  | 1   0
//   0  1   1  | 0   1
//   1  0   0  | 1   0
//   1  0   1  | 0   1
//   1  1   0  | 0   1
//   1  1   1  | 1   1
//
// Expresiones booleanas (minimizadas):
//   s    = a XOR b XOR cin
//   cout = (a AND b) OR ((a XOR b) AND cin)
//
// Nota para el informe: la forma de cout de arriba es la version factorizada.
// La suma de mintérminos equivalente es
//   cout = a'bc + ab'c + abc' + abc
// y el mapa de Karnaugh la reduce a  ab + ac + bc.
//==============================================================================
module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire s,
    output wire cout
);

    wire a_xor_b;    // a XOR b       (suma parcial)
    wire and_ab;     // a AND b       (carry generado)
    wire and_pc;     // (a XOR b) AND cin  (carry propagado)

    xor u_s1   (a_xor_b, a, b);
    xor u_s2   (s,       a_xor_b, cin);

    and u_c1   (and_ab,  a, b);
    and u_c2   (and_pc,  a_xor_b, cin);
    or  u_cout (cout,    and_ab, and_pc);

endmodule
`default_nettype wire
