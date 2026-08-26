`default_nettype none
//==============================================================================
// op2_select - Selector del segundo operando
//------------------------------------------------------------------------------
// El enunciado pide un selector de 1 bit que elija el segundo operando entre:
//   - un operando externo op2 de 4 bits            (sel_prev = 0)
//   - el resultado de la operacion anterior        (sel_prev = 1)
//
// Es simplemente un mux 2:1 de 4 bits, o sea compuertas.
//
// OJO con el lazo: prev_result viene del registro de resultado, y la salida de
// este mux alimenta la ALU cuya salida vuelve a ese registro. El lazo NO es
// combinacional porque el registro lo corta: la realimentacion pasa siempre
// por un flip-flop.
//==============================================================================
module op2_select (
    input  wire [3:0] op2_ext,
    input  wire [3:0] prev_result,
    input  wire       sel_prev,
    output wire [3:0] b
);

    mux2to1_4bit u_mux (
        .a (op2_ext),
        .b (prev_result),
        .s (sel_prev),
        .y (b)
    );

endmodule
`default_nettype wire
