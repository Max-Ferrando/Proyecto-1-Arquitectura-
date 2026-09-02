`timescale 1ns/1ps
module tb_fpga;
    reg clk=0, s1=0, s2=0, s3=0, s4=0;
    wire l1,l2,l3,l4;
    wire a1,b1,c1,d1,e1,f1,g1, a2,b2,c2,d2,e2,f2,g2;
    fpga_top u(.i_Clk(clk),.i_Switch_1(s1),.i_Switch_2(s2),.i_Switch_3(s3),.i_Switch_4(s4),
        .o_LED_1(l1),.o_LED_2(l2),.o_LED_3(l3),.o_LED_4(l4),
        .o_Segment1_A(a1),.o_Segment1_B(b1),.o_Segment1_C(c1),.o_Segment1_D(d1),
        .o_Segment1_E(e1),.o_Segment1_F(f1),.o_Segment1_G(g1),
        .o_Segment2_A(a2),.o_Segment2_B(b2),.o_Segment2_C(c2),.o_Segment2_D(d2),
        .o_Segment2_E(e2),.o_Segment2_F(f2),.o_Segment2_G(g2));
    always #20 clk = ~clk;   // 25 MHz

    task press(input integer which);
      begin
        case(which)
          1: s1=1; 2: s2=1; 3: s3=1; 4: s4=1;
        endcase
        #12_000_000;   // 12 ms mantenido
        s1=0; s2=0; s3=0; s4=0;
        #12_000_000;   // 12 ms suelto
      end
    endtask

    integer k;
    initial begin
        #100_000;
        // 1) elegir operacion 001 (suma): un incremento, luego confirmar
        press(1);
        $display("estado=%b op_sel=%b LEDs=%b%b%b", u.state, u.op_sel_reg, l3,l2,l1);
        press(3);
        // 2) op1 = 3 -> tres incrementos
        for (k=0;k<3;k=k+1) press(1);
        $display("estado=%b op1=%b (%0d)", u.state, u.op1_reg, u.op1_reg);
        press(3);
        // 3) op2 = 5 -> cinco incrementos
        for (k=0;k<5;k=k+1) press(1);
        $display("estado=%b op2=%b (%0d) sel_prev=%b", u.state, u.op2_reg, u.op2_reg, u.sel_prev_reg);
        press(3);   // ejecutar
        $display(">>> RESULTADO 3+5 = %b (%0d)  estado=%b signo(seg g disp1)=%b",
                 u.result, u.result, u.state, g1);
        // 4) volver al inicio
        press(3);
        $display("vuelta al inicio: estado=%b sel_prev=%b", u.state, u.sel_prev_reg);
        // 5) resta inversa (011) usando resultado anterior: op1=9, R = 8-9 = -1
        press(1); press(1); press(1);   // op_sel = 011
        $display("op_sel=%b", u.op_sel_reg);
        press(3);
        for (k=0;k<9;k=k+1) press(1);   // op1 = 9
        $display("op1=%0d", u.op1_reg);
        press(3);
        press(4);                        // usar resultado anterior como op2
        $display("sel_prev=%b LED4=%b op2_usado=%b", u.sel_prev_reg, l4, u.op2_shown);
        press(3);
        $display(">>> RESULTADO 8-9 = %b (%0d con signo)  signo=%b",
                 u.result, $signed(u.result), g1);
        $finish;
    end
endmodule