`default_nettype none
//==============================================================================
// result_select - Selector final del resultado segun la operacion
//------------------------------------------------------------------------------
// Recibe las tres salidas candidatas (sumador, shift izq, shift der) y las
// senales one-hot del decoder, y entrega el resultado final.
// Construido EXCLUSIVAMENTE con compuertas.
//
// ESTRUCTURA AND-OR (mux de N vias en one-hot):
//   Cada bit de salida es:
//       r[i] = (sum[i] AND sel_sum) OR (shl[i] AND sel_shl) OR (shr[i] AND sel_shr)
//
//   donde:
//       sel_sum = w[1] OR w[2] OR w[3]      suma, resta, resta inversa
//       sel_shl = w[4] OR w[6]              shift left
//       sel_shr = w[5] OR w[7]              shift right
//
// EL REINICIO SALE GRATIS (esto conviene destacarlo en el informe):
//   Cuando sel = 000 esta activa w[0], que NO participa en ninguna de las tres
//   senales de arriba. Entonces sel_sum = sel_shl = sel_shr = 0, todas las
//   compuertas AND dan 0, y el OR final entrega 0000. Es decir, la operacion
//   de Reinicio no necesita NI UNA compuerta extra: es la consecuencia natural
//   de no seleccionar ninguna via.
//==============================================================================
module result_select (
    input  wire [7:0] w,      // one-hot desde decoder3to8
    input  wire [3:0] sum,    // salida del sumador/restador
    input  wire [3:0] shl,    // salida del shift izquierdo
    input  wire [3:0] shr,    // salida del shift derecho
    output wire [3:0] r
);

    wire sel_sum, sel_shl, sel_shr;

    or u_sel_sum (sel_sum, w[1], w[2], w[3]);
    or u_sel_shl (sel_shl, w[4], w[6]);
    or u_sel_shr (sel_shr, w[5], w[7]);

    // Productos de cada candidato con su seleccion
    wire [3:0] g_sum, g_shl, g_shr;

    and u_gs0 (g_sum[0], sum[0], sel_sum);
    and u_gs1 (g_sum[1], sum[1], sel_sum);
    and u_gs2 (g_sum[2], sum[2], sel_sum);
    and u_gs3 (g_sum[3], sum[3], sel_sum);

    and u_gl0 (g_shl[0], shl[0], sel_shl);
    and u_gl1 (g_shl[1], shl[1], sel_shl);
    and u_gl2 (g_shl[2], shl[2], sel_shl);
    and u_gl3 (g_shl[3], shl[3], sel_shl);

    and u_gr0 (g_shr[0], shr[0], sel_shr);
    and u_gr1 (g_shr[1], shr[1], sel_shr);
    and u_gr2 (g_shr[2], shr[2], sel_shr);
    and u_gr3 (g_shr[3], shr[3], sel_shr);

    // Suma logica de las tres vias
    or u_r0 (r[0], g_sum[0], g_shl[0], g_shr[0]);
    or u_r1 (r[1], g_sum[1], g_shl[1], g_shr[1]);
    or u_r2 (r[2], g_sum[2], g_shl[2], g_shr[2]);
    or u_r3 (r[3], g_sum[3], g_shl[3], g_shr[3]);

endmodule
`default_nettype wire
