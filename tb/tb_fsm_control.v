`timescale 1ns/1ps
`default_nettype none
//==============================================================================
// tb_fsm_control - Testbench de la interfaz de botones + calculadora
//------------------------------------------------------------------------------
// Simula la secuencia completa que se va a hacer con los botones en la placa,
// pero SIN el antirrebote (que a 25 MHz tardaria 250.000 ciclos por boton y
// haria la simulacion eterna). Aca se inyectan directamente los pulsos que
// normalmente produce debounce + edge_detect.
//
// Sirve para verificar la logica de control antes de cargar el diseno en la
// FPGA, que es mucho mas lento de depurar.
//==============================================================================
module tb_fsm_control;

    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg p_up   = 1'b0;
    reg p_down = 1'b0;
    reg p_ok   = 1'b0;
    reg p_prev = 1'b0;

    wire [2:0] op_sel;
    wire [3:0] op1;
    wire [3:0] op2_ext;
    wire       sel_op2_prev;
    wire       ejecutar;
    wire [1:0] estado;

    wire [3:0] resultado;
    wire [3:0] alu_out;
    wire       cout;

    fsm_control u_fsm (
        .clk          (clk),
        .p_up         (p_up),
        .p_down       (p_down),
        .p_ok         (p_ok),
        .p_prev       (p_prev),
        .op_sel       (op_sel),
        .op1          (op1),
        .op2_ext      (op2_ext),
        .sel_op2_prev (sel_op2_prev),
        .ejecutar     (ejecutar),
        .estado       (estado)
    );

    calculator_top u_calc (
        .clk          (clk),
        .rst          (1'b0),
        .ejecutar     (ejecutar),
        .op1          (op1),
        .op2_ext      (op2_ext),
        .sel_op2_prev (sel_op2_prev),
        .op_sel       (op_sel),
        .resultado    (resultado),
        .alu_out      (alu_out),
        .cout         (cout)
    );

    // --- Tareas para simular apretones de boton (un pulso de un ciclo) ---
    //
    // Nota: 'ejecutar' sale registrado desde la FSM, asi que el registro de
    // resultado se carga UN CICLO DESPUES del pulso de p_ok. Por eso apretar_ok
    // espera dos ciclos extra antes de devolver el control: sin esa espera se
    // leeria el valor viejo del registro.
    task apretar_up;   begin @(negedge clk); p_up   = 1; @(negedge clk); p_up   = 0; end endtask
    task apretar_down; begin @(negedge clk); p_down = 1; @(negedge clk); p_down = 0; end endtask
    task apretar_prev; begin @(negedge clk); p_prev = 1; @(negedge clk); p_prev = 0; end endtask

    task apretar_ok;
        begin
            @(negedge clk); p_ok = 1;
            @(negedge clk); p_ok = 0;
            @(negedge clk);              // aqui se carga el registro
            @(negedge clk);              // margen
        end
    endtask

    task repetir_up;
        input integer n;
        integer k;
        begin for (k = 0; k < n; k = k + 1) apretar_up; end
    endtask

    task repetir_down;
        input integer n;
        integer k;
        begin for (k = 0; k < n; k = k + 1) apretar_down; end
    endtask

    task mostrar;
        input [255:0] etiqueta;
        begin
            $display("  %-32s estado=%0d op=%b op1=%b op2=%b prev=%b R=%b (%0d)",
                     etiqueta, estado, op_sel, op1, op2_ext, sel_op2_prev,
                     resultado, $signed(resultado));
        end
    endtask

    integer errores = 0;

    task verificar;
        input [255:0] etiqueta;
        input [3:0]   esperado;
        begin
            if (resultado !== esperado) begin
                errores = errores + 1;
                $display("  FALLA en %0s: R=%b esperado=%b", etiqueta, resultado, esperado);
            end
        end
    endtask

    initial begin
        $dumpfile("fsm_control_tb.vcd");
        $dumpvars(0, tb_fsm_control);

        #20;

        $display("");
        $display("=================================================================================");
        $display(" SECUENCIA 1:  5 + 3   (con los botones)");
        $display("=================================================================================");
        mostrar("inicio");

        repetir_up(1);   mostrar("op -> 001 (suma)");     // S_OP: sube la operacion a 001
        apretar_ok;      mostrar("confirma operacion");

        repetir_up(5);   mostrar("op1 -> 0101 (5)");      // S_OP1
        apretar_ok;      mostrar("confirma op1");

        repetir_up(3);   mostrar("op2 -> 0011 (3)");      // S_OP2
        apretar_ok;      mostrar("EJECUTA");
        // 5 + 3 = 8, que en 4 bits con signo es 1000 = -8 (overflow truncado)
        verificar("5+3", 4'b1000);

        apretar_ok;      mostrar("vuelve al inicio");

        $display("");
        $display("=================================================================================");
        $display(" SECUENCIA 2:  1 + (resultado anterior)   -> usa el boton 'prev'");
        $display("=================================================================================");

        apretar_ok;      mostrar("confirma operacion");   // sigue en suma (001)

        repetir_down(4); mostrar("op1 -> 0001 (1)");      // de 0101 baja 4 -> 0001
        apretar_ok;      mostrar("confirma op1");

        apretar_prev;    mostrar("usa resultado anterior");
        apretar_ok;      mostrar("EJECUTA");
        // 1 + (-8) = -7 = 1001
        verificar("1+(-8)", 4'b1001);

        apretar_ok;

        $display("");
        $display("=================================================================================");
        $display(" SECUENCIA 3:  Reinicio (operacion 000)");
        $display("=================================================================================");

        repetir_down(1); mostrar("op -> 000 (reinicio)"); // de 001 baja 1 -> 000
        apretar_ok;
        apretar_ok;
        apretar_ok;      mostrar("EJECUTA reinicio");
        verificar("reinicio", 4'b0000);

        $display("");
        $display("=================================================================================");
        if (errores == 0)
            $display("  RESULTADO: TODO CORRECTO");
        else
            $display("  RESULTADO: %0d FALLAS", errores);
        $display("=================================================================================");
        $display("");

        #20;
        $finish;
    end

endmodule
`default_nettype wire
