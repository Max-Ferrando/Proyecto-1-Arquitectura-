`default_nettype none
//==============================================================================
// adder4 - Sumador / restador de 4 bits en complemento a dos
//------------------------------------------------------------------------------
// Cuatro full_adder encadenados (ripple carry). Construido EXCLUSIVAMENTE con
// compuertas: no se usa el operador '+' en ninguna parte.
//
//   sub = 0  ->  sum = x + y
//   sub = 1  ->  sum = x - y
//
// COMO FUNCIONA LA RESTA (esto va en el informe):
//   En complemento a dos,  -y = (NOT y) + 1.
//   Entonces  x - y = x + (NOT y) + 1.
//   El "+1" NO cuesta un sumador extra: se inyecta por el carry-in de la
//   primera etapa. Y el "NOT y" se obtiene con un XOR usado como inversor
//   controlado:
//
//        y_eff = y XOR sub      sub=0 -> y_eff = y      (no invierte)
//                               sub=1 -> y_eff = NOT y  (invierte)
//        cin   = sub
//
//   Por eso el MISMO circuito hace suma y resta, que es la idea central del
//   diseno: un solo sumador reutilizado para op 001, 010 y 011.
//
// El resultado se trunca a 4 bits (el enunciado pide conservar solo los cuatro
// bits menos significativos si hay overflow); 'cout' se saca por si se quiere
// mostrar o analizar, pero no forma parte del resultado.
//==============================================================================
module adder4 (
    input  wire [3:0] x,
    input  wire [3:0] y,
    input  wire       sub,
    output wire [3:0] sum,
    output wire       cout
);

    wire [3:0] y_eff;      // y, opcionalmente invertido
    wire       c1, c2, c3; // acarreos internos

    // --- Inversor controlado: XOR con 'sub' ---
    xor u_y0 (y_eff[0], y[0], sub);
    xor u_y1 (y_eff[1], y[1], sub);
    xor u_y2 (y_eff[2], y[2], sub);
    xor u_y3 (y_eff[3], y[3], sub);

    // --- Cadena ripple carry. El carry-in inicial es 'sub' (el +1). ---
    full_adder u_fa0 (.a(x[0]), .b(y_eff[0]), .cin(sub), .s(sum[0]), .cout(c1));
    full_adder u_fa1 (.a(x[1]), .b(y_eff[1]), .cin(c1),  .s(sum[1]), .cout(c2));
    full_adder u_fa2 (.a(x[2]), .b(y_eff[2]), .cin(c2),  .s(sum[2]), .cout(c3));
    full_adder u_fa3 (.a(x[3]), .b(y_eff[3]), .cin(c3),  .s(sum[3]), .cout(cout));

endmodule
`default_nettype wire
