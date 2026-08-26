`default_nettype none
//==============================================================================
// debounce - Antirrebote para los pulsadores de la placa
//------------------------------------------------------------------------------
// Los botones mecanicos "rebotan": al presionarlos generan decenas de
// transiciones en unos pocos milisegundos. Sin filtrar, un solo apreton se leeria
// como 20 apretones y el contador de la calculadora saltaria varios valores.
//
// Este modulo solo deja pasar un cambio cuando la entrada se mantuvo estable
// durante COUNT_MAX ciclos de reloj (10 ms a 25 MHz por defecto).
//
//------------------------------------------------------------------------------
// SOBRE LA RESTRICCION DEL ENUNCIADO
//   Este modulo NO es parte de la calculadora: es acondicionamiento de la
//   entrada fisica de la placa, logica SECUENCIAL de interfaz. Por eso usa un
//   contador conductual (if / == / +) en vez de compuertas.
//
//   La restriccion del enunciado dice textualmente "la logica COMBINACIONAL de
//   la calculadora debe implementarse exclusivamente mediante compuertas", y
//   toda esa logica (carpeta src/, modulos alu4 y sus submodulos) SI cumple.
//
//   >>> CONFIRMAR ESTA INTERPRETACION CON EL PROFESOR O UN AYUDANTE. <<<
//   Si exigen compuertas tambien aca, se puede reemplazar el contador por una
//   cadena de flip-flops con un LFSR, pero conviene preguntar antes de gastar
//   tiempo en eso.
//==============================================================================
module debounce #(
    parameter integer COUNT_MAX = 250000   // 10 ms a 25 MHz
) (
    input  wire clk,
    input  wire din,
    output reg  dout = 1'b0
);

    reg [17:0] cnt = 18'd0;

    always @(posedge clk) begin
        if (din == dout) begin
            // entrada coincide con la salida: nada que hacer
            cnt <= 18'd0;
        end else if (cnt == COUNT_MAX) begin
            // se mantuvo distinta el tiempo suficiente: se acepta el cambio
            dout <= din;
            cnt  <= 18'd0;
        end else begin
            cnt <= cnt + 18'd1;
        end
    end

endmodule
`default_nettype wire
