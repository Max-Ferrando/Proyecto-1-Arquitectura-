`default_nettype none
//==============================================================================
// edge_detect - Detector de flanco de subida
//------------------------------------------------------------------------------
// Convierte un boton mantenido apretado en UN SOLO pulso de un ciclo de reloj.
// Sin esto, dejar el dedo apoyado incrementaria el valor 25 millones de veces
// por segundo.
//
//   pulse = din AND (NOT din_registrado)
//
//         din  ____/-------------------\____
//     din_reg  ______/-------------------\__
//       pulse  ____/-\____________________  <- un solo ciclo
//
// La compuerta AND y el NOT son compuertas; el unico elemento secuencial es el
// flip-flop que guarda el valor anterior.
//==============================================================================
module edge_detect (
    input  wire clk,
    input  wire din,
    output wire pulse
);

    reg  din_reg = 1'b0;
    wire n_din_reg;

    always @(posedge clk) begin
        din_reg <= din;
    end

    not u_not (n_din_reg, din_reg);
    and u_and (pulse, din, n_din_reg);

endmodule
`default_nettype wire
