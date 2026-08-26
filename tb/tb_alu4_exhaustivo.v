`timescale 1ns/1ps
`default_nettype none
//==============================================================================
// tb_alu4_exhaustivo - Verificacion exhaustiva de la ALU combinacional
//------------------------------------------------------------------------------
// Recorre LAS 2048 combinaciones posibles (16 valores de A x 16 de B x 8 ops)
// y compara la salida del circuito de compuertas contra un modelo de referencia
// escrito en Verilog de alto nivel.
//
// IMPORTANTE: el modelo de referencia SI usa +, -, << y >>. Eso esta permitido
// porque el testbench NO se sintetiza: no es parte del circuito, es solo el
// "profesor" que corrige. La restriccion del enunciado aplica al diseno
// (carpeta src/), no al banco de pruebas.
//
// Esta es la prueba que demuestra que la implementacion con compuertas es
// correcta. Conviene mostrar su salida en el informe.
//==============================================================================
module tb_alu4_exhaustivo;

    reg  [3:0] a;
    reg  [3:0] b;
    reg  [2:0] op;

    wire [3:0] r;
    wire       cout;

    integer errores;
    integer casos;
    integer ia, ib, iop;

    reg [3:0] esperado;

    alu4 dut (
        .a    (a),
        .b    (b),
        .op   (op),
        .r    (r),
        .cout (cout)
    );

    // --- Modelo de referencia (alto nivel, NO sintetizable a proposito) ---
    function [3:0] modelo;
        input [3:0] fa;
        input [3:0] fb;
        input [2:0] fop;
        begin
            case (fop)
                3'b000: modelo = 4'b0000;          // Reinicio
                3'b001: modelo = fa + fb;          // Suma
                3'b010: modelo = fa - fb;          // Resta
                3'b011: modelo = fb - fa;          // Resta inversa
                3'b100: modelo = fa << fb[1:0];    // Shift left
                3'b101: modelo = fa >> fb[1:0];    // Shift right
                3'b110: modelo = fa << fb[1:0];    // no usado -> shift left
                3'b111: modelo = fa >> fb[1:0];    // no usado -> shift right
            endcase
        end
    endfunction

    initial begin
        $dumpfile("alu4_exhaustivo.vcd");
        $dumpvars(0, tb_alu4_exhaustivo);

        errores = 0;
        casos   = 0;

        $display("");
        $display("=========================================================");
        $display(" Verificacion exhaustiva de alu4 (2048 casos)");
        $display("=========================================================");

        for (iop = 0; iop < 8; iop = iop + 1) begin
            for (ia = 0; ia < 16; ia = ia + 1) begin
                for (ib = 0; ib < 16; ib = ib + 1) begin
                    a  = ia[3:0];
                    b  = ib[3:0];
                    op = iop[2:0];
                    #1;

                    esperado = modelo(a, b, op);
                    casos    = casos + 1;

                    if (r !== esperado) begin
                        errores = errores + 1;
                        $display("  FALLA op=%b a=%b(%0d) b=%b(%0d) -> r=%b esperado=%b",
                                 op, a, $signed(a), b, $signed(b), r, esperado);
                    end
                end
            end
        end

        $display("");
        $display("  casos probados : %0d", casos);
        $display("  errores        : %0d", errores);
        if (errores == 0)
            $display("  RESULTADO      : TODO CORRECTO");
        else
            $display("  RESULTADO      : HAY FALLAS");
        $display("=========================================================");
        $display("");

        $finish;
    end

endmodule
`default_nettype wire
