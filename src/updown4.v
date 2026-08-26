`default_nettype none
//==============================================================================
// updown4 - Incrementa o decrementa un valor de 4 bits
//------------------------------------------------------------------------------
// Sirve para que los botones de la placa suban y bajen el valor que se esta
// ingresando (operacion, op1 u op2).
//
// NO agrega logica nueva: REUTILIZA el mismo adder4 de la calculadora.
//
//   dec = 0  ->  dout = din + 1     (adder4 con y = 0001, sub = 0)
//   dec = 1  ->  dout = din - 1     (adder4 con y = 0001, sub = 1)
//
// Al ser de 4 bits el valor da la vuelta solo: 1111 + 1 = 0000 y 0000 - 1 = 1111.
// Eso es justo lo que uno quiere en una interfaz de botones.
//==============================================================================
module updown4 (
    input  wire [3:0] din,
    input  wire       dec,     // 0 = incrementar, 1 = decrementar
    output wire [3:0] dout
);

    adder4 u_add (
        .x    (din),
        .y    (4'b0001),
        .sub  (dec),
        .sum  (dout),
        .cout ()            // no interesa el acarreo: se quiere que de la vuelta
    );

endmodule
`default_nettype wire
