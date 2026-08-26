`timescale 1ns/1ps
`default_nettype none
//==============================================================================
// tb_calculator_top - Testbench de la calculadora completa (ALU + registro)
//------------------------------------------------------------------------------
//  *** ESTE ES EL ARCHIVO QUE HAY QUE EDITAR EL DIA DE LA EVALUACION ***
//
// El profesor va a dictar una operacion y unos valores. Se cambian los cuatro
// parametros del bloque "EDITAR AQUI", se vuelve a correr la simulacion y se
// muestra el resultado en GTKWave.
//
//   iverilog -g2012 -o sim tb/tb_calculator_top.v src/*.v
//   vvp sim
//   gtkwave calculator_tb.vcd
//==============================================================================
module tb_calculator_top;

    //==========================================================================
    //                            EDITAR AQUI
    //==========================================================================
    localparam [3:0] OP1          = 4'b0101;   //  primer operando   =  5
    localparam [3:0] OP2_EXT      = 4'b0011;   //  segundo operando  =  3
    localparam       SEL_OP2_PREV = 1'b0;      //  0 = usa OP2_EXT
                                               //  1 = usa el resultado anterior
    localparam [2:0] OP_SEL       = 3'b001;    //  operacion:
                                               //    000 Reinicio      R = 0
                                               //    001 Suma          R = A + B
                                               //    010 Resta         R = A - B
                                               //    011 Resta inversa R = B - A
                                               //    100 Shift left    R = A << B[1:0]
                                               //    101 Shift right   R = A >> B[1:0]
    //==========================================================================

    reg        clk = 1'b0;
    reg        rst = 1'b1;
    reg        ejecutar = 1'b0;
    reg  [3:0] op1 = 4'b0000;
    reg  [3:0] op2_ext = 4'b0000;
    reg        sel_op2_prev = 1'b0;
    reg  [2:0] op_sel = 3'b000;

    wire [3:0] resultado;
    wire [3:0] alu_out;
    wire       cout;

    calculator_top dut (
        .clk          (clk),
        .rst          (rst),
        .ejecutar     (ejecutar),
        .op1          (op1),
        .op2_ext      (op2_ext),
        .sel_op2_prev (sel_op2_prev),
        .op_sel       (op_sel),
        .resultado    (resultado),
        .alu_out      (alu_out),
        .cout         (cout)
    );

    // reloj de 100 MHz (periodo 10 ns) -- solo para la simulacion
    always #5 clk = ~clk;

    // Nombre legible de la operacion, para los mensajes
    function [127:0] nombre_op;
        input [2:0] o;
        begin
            case (o)
                3'b000: nombre_op = "Reinicio     ";
                3'b001: nombre_op = "Suma         ";
                3'b010: nombre_op = "Resta        ";
                3'b011: nombre_op = "Resta inversa";
                3'b100: nombre_op = "Shift left   ";
                3'b101: nombre_op = "Shift right  ";
                default: nombre_op = "(no usada)   ";
            endcase
        end
    endfunction

    // Aplica una operacion y muestra el resultado
    reg [3:0]  b_usado;
    reg [47:0] origen_b;

    task ejecutar_op;
        input [3:0] i_op1;
        input [3:0] i_op2;
        input       i_prev;
        input [2:0] i_sel;
        begin
            // que valor va a entrar realmente como segundo operando
            b_usado  = i_op2;
            origen_b = "      ";
            if (i_prev) begin
                b_usado  = resultado;
                origen_b = "<-prev";
            end

            @(negedge clk);
            op1          = i_op1;
            op2_ext      = i_op2;
            sel_op2_prev = i_prev;
            op_sel       = i_sel;
            ejecutar     = 1'b1;
            @(negedge clk);          // flanco de subida entremedio: carga el registro
            ejecutar     = 1'b0;
            @(negedge clk);

            $display("  %s | op1=%b (%3d) | op2=%b (%3d) %s | R=%b (%3d)",
                     nombre_op(i_sel),
                     i_op1,   $signed(i_op1),
                     b_usado, $signed(b_usado),
                     origen_b,
                     resultado, $signed(resultado));
        end
    endtask

    initial begin
        $dumpfile("calculator_tb.vcd");
        $dumpvars(0, tb_calculator_top);

        // reset inicial del registro
        @(negedge clk);
        rst = 1'b1;
        @(negedge clk);
        rst = 1'b0;

        $display("");
        $display("=================================================================================");
        $display(" CASO PEDIDO (bloque EDITAR AQUI)");
        $display("=================================================================================");
        ejecutar_op(OP1, OP2_EXT, SEL_OP2_PREV, OP_SEL);

        $display("");
        $display("=================================================================================");
        $display(" DEMOSTRACION DE LAS 6 OPERACIONES");
        $display("=================================================================================");
        ejecutar_op(4'b0101, 4'b0011, 1'b0, 3'b001);   //  5 + 3  =  8  (overflow a -8)
        ejecutar_op(4'b0101, 4'b0011, 1'b0, 3'b010);   //  5 - 3  =  2
        ejecutar_op(4'b0101, 4'b0011, 1'b0, 3'b011);   //  3 - 5  = -2
        ejecutar_op(4'b0011, 4'b0010, 1'b0, 3'b100);   //  3 << 2 = 12 -> -4 en compl. a 2
        ejecutar_op(4'b1100, 4'b0010, 1'b0, 3'b101);   // 1100 >> 2 = 0011 = 3
        ejecutar_op(4'b0000, 4'b0000, 1'b0, 3'b000);   //  Reinicio -> 0

        $display("");
        $display("=================================================================================");
        $display(" ENCADENAMIENTO: usar el resultado anterior como segundo operando");
        $display("=================================================================================");
        ejecutar_op(4'b0010, 4'b0001, 1'b0, 3'b001);   //  2 + 1 = 3   (queda 3 guardado)
        ejecutar_op(4'b0001, 4'b0000, 1'b1, 3'b001);   //  1 + 3 = 4   (usa el 3 anterior)
        ejecutar_op(4'b0001, 4'b0000, 1'b1, 3'b001);   //  1 + 4 = 5   (usa el 4 anterior)

        $display("");
        #20;
        $finish;
    end

endmodule
`default_nettype wire
