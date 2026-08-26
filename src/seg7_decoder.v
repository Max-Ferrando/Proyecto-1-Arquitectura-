`default_nettype none
//==============================================================================
// seg7_decoder - Decodificador hexadecimal a display de 7 segmentos
//------------------------------------------------------------------------------
// Construido EXCLUSIVAMENTE con compuertas, en SUMA DE MINTERMINOS:
//   1) un decodificador 4->16 genera los 16 minterminos m[0..15]
//   2) cada segmento es un OR de los minterminos donde ese segmento se enciende
//
// Salida activa en ALTO (1 = segmento encendido). La adaptacion a la polaridad
// real de la placa se hace en fpga_top.v.
//
//        aaa          seg[0] = a    seg[3] = d    seg[6] = g
//       f   b         seg[1] = b    seg[4] = e
//       f   b         seg[2] = c    seg[5] = f
//        ggg
//       e   c
//       e   c
//        ddd
//
// TABLA DE VERDAD COMPLETA (1 = segmento encendido)
//
//   valor | d3 d2 d1 d0 | a b c d e f g
//   ------+-------------+---------------
//     0   |  0  0  0  0 | 1 1 1 1 1 1 0
//     1   |  0  0  0  1 | 0 1 1 0 0 0 0
//     2   |  0  0  1  0 | 1 1 0 1 1 0 1
//     3   |  0  0  1  1 | 1 1 1 1 0 0 1
//     4   |  0  1  0  0 | 0 1 1 0 0 1 1
//     5   |  0  1  0  1 | 1 0 1 1 0 1 1
//     6   |  0  1  1  0 | 1 0 1 1 1 1 1
//     7   |  0  1  1  1 | 1 1 1 0 0 0 0
//     8   |  1  0  0  0 | 1 1 1 1 1 1 1
//     9   |  1  0  0  1 | 1 1 1 1 0 1 1
//     A   |  1  0  1  0 | 1 1 1 0 1 1 1
//     b   |  1  0  1  1 | 0 0 1 1 1 1 1
//     C   |  1  1  0  0 | 1 0 0 1 1 1 0
//     d   |  1  1  0  1 | 0 1 1 1 1 0 1
//     E   |  1  1  1  0 | 1 0 0 1 1 1 1
//     F   |  1  1  1  1 | 1 0 0 0 1 1 1
//
// NOTA PARA EL INFORME
//   Lo que sigue es la forma CANONICA (suma de todos los minterminos), que es
//   exactamente el punto de partida de un mapa de Karnaugh. Funciona y es
//   100% compuertas, pero NO esta minimizada. Minimizar estas 7 funciones con
//   K-maps es parte del trabajo que pide la rubrica (item de 1,5 puntos);
//   una vez minimizadas se pueden reemplazar los OR de abajo por las
//   expresiones reducidas y el circuito queda mas chico.
//==============================================================================
module seg7_decoder (
    input  wire [3:0] valor,
    input  wire       enable,   // 0 = display apagado
    output wire [6:0] seg       // {g,f,e,d,c,b,a} activo en alto
);

    // ------------------------------------------------------------------
    // Decodificador 4 -> 16 (los 16 minterminos)
    // ------------------------------------------------------------------
    wire n3, n2, n1, n0;

    not u_n3 (n3, valor[3]);
    not u_n2 (n2, valor[2]);
    not u_n1 (n1, valor[1]);
    not u_n0 (n0, valor[0]);

    wire [15:0] m;

    and u_m00 (m[0],  n3,       n2,       n1,       n0      );
    and u_m01 (m[1],  n3,       n2,       n1,       valor[0]);
    and u_m02 (m[2],  n3,       n2,       valor[1], n0      );
    and u_m03 (m[3],  n3,       n2,       valor[1], valor[0]);
    and u_m04 (m[4],  n3,       valor[2], n1,       n0      );
    and u_m05 (m[5],  n3,       valor[2], n1,       valor[0]);
    and u_m06 (m[6],  n3,       valor[2], valor[1], n0      );
    and u_m07 (m[7],  n3,       valor[2], valor[1], valor[0]);
    and u_m08 (m[8],  valor[3], n2,       n1,       n0      );
    and u_m09 (m[9],  valor[3], n2,       n1,       valor[0]);
    and u_m10 (m[10], valor[3], n2,       valor[1], n0      );
    and u_m11 (m[11], valor[3], n2,       valor[1], valor[0]);
    and u_m12 (m[12], valor[3], valor[2], n1,       n0      );
    and u_m13 (m[13], valor[3], valor[2], n1,       valor[0]);
    and u_m14 (m[14], valor[3], valor[2], valor[1], n0      );
    and u_m15 (m[15], valor[3], valor[2], valor[1], valor[0]);

    // ------------------------------------------------------------------
    // Suma de minterminos por segmento
    // ------------------------------------------------------------------
    wire [6:0] s;

    // a = sum m(0,2,3,5,6,7,8,9,10,12,14,15)
    or u_a (s[0], m[0], m[2], m[3], m[5], m[6], m[7], m[8], m[9], m[10], m[12], m[14], m[15]);

    // b = sum m(0,1,2,3,4,7,8,9,10,13)
    or u_b (s[1], m[0], m[1], m[2], m[3], m[4], m[7], m[8], m[9], m[10], m[13]);

    // c = sum m(0,1,3,4,5,6,7,8,9,10,11,13)
    or u_c (s[2], m[0], m[1], m[3], m[4], m[5], m[6], m[7], m[8], m[9], m[10], m[11], m[13]);

    // d = sum m(0,2,3,5,6,8,9,11,12,13,14)
    or u_d (s[3], m[0], m[2], m[3], m[5], m[6], m[8], m[9], m[11], m[12], m[13], m[14]);

    // e = sum m(0,2,6,8,10,11,12,13,14,15)
    or u_e (s[4], m[0], m[2], m[6], m[8], m[10], m[11], m[12], m[13], m[14], m[15]);

    // f = sum m(0,4,5,6,8,9,10,11,12,14,15)
    or u_f (s[5], m[0], m[4], m[5], m[6], m[8], m[9], m[10], m[11], m[12], m[14], m[15]);

    // g = sum m(2,3,4,5,6,8,9,10,11,13,14,15)
    or u_g (s[6], m[2], m[3], m[4], m[5], m[6], m[8], m[9], m[10], m[11], m[13], m[14], m[15]);

    // ------------------------------------------------------------------
    // Apagado global del display
    // ------------------------------------------------------------------
    and u_e0 (seg[0], s[0], enable);
    and u_e1 (seg[1], s[1], enable);
    and u_e2 (seg[2], s[2], enable);
    and u_e3 (seg[3], s[3], enable);
    and u_e4 (seg[4], s[4], enable);
    and u_e5 (seg[5], s[5], enable);
    and u_e6 (seg[6], s[6], enable);

endmodule
`default_nettype wire
