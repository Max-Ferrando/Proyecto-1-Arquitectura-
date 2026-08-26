`default_nettype none
//==============================================================================
// fpga_top - Top level para la Nandland Go Board (Lattice iCE40 HX1K, VQ100)
//------------------------------------------------------------------------------
// Conecta la calculadora con el hardware real de la placa: 4 pulsadores,
// 4 LEDs y los dos displays de 7 segmentos.
//
// Los nombres de los puertos DEBEN coincidir exactamente con los del archivo
// constraints/go_board.pcf (son los nombres oficiales de Nandland).
//
//   i_Clk        reloj de 25 MHz de la placa (pin 15)
//   i_Switch_1-4 pulsadores
//   o_LED_1-4    LEDs
//   o_Segment1_* display izquierdo  -> SIGNO
//   o_Segment2_* display derecho    -> VALOR EN HEXADECIMAL
//
//------------------------------------------------------------------------------
// CADENA DE PROCESAMIENTO DE CADA BOTON
//
//   pin fisico -> debounce (filtra rebotes) -> edge_detect (1 pulso) -> FSM
//
//------------------------------------------------------------------------------
// QUE SE MUESTRA EN CADA ESTADO
//
//   estado          LEDs 1-3     display
//   S_OP  (00)      codigo op    op1
//   S_OP1 (01)      codigo op    op1
//   S_OP2 (10)      codigo op    segundo operando (externo o resultado previo)
//   S_RES (11)      codigo op    resultado
//
//   El LED 4 se enciende cuando esta activo "usar el resultado anterior".
//==============================================================================
module fpga_top (
    input  wire i_Clk,

    input  wire i_Switch_1,
    input  wire i_Switch_2,
    input  wire i_Switch_3,
    input  wire i_Switch_4,

    output wire o_LED_1,
    output wire o_LED_2,
    output wire o_LED_3,
    output wire o_LED_4,

    output wire o_Segment1_A,
    output wire o_Segment1_B,
    output wire o_Segment1_C,
    output wire o_Segment1_D,
    output wire o_Segment1_E,
    output wire o_Segment1_F,
    output wire o_Segment1_G,

    output wire o_Segment2_A,
    output wire o_Segment2_B,
    output wire o_Segment2_C,
    output wire o_Segment2_D,
    output wire o_Segment2_E,
    output wire o_Segment2_F,
    output wire o_Segment2_G
);

    //==========================================================================
    // AJUSTE 1: ASIGNACION DE LOS BOTONES
    //--------------------------------------------------------------------------
    // El enunciado pide:
    //   superior izquierdo -> incrementar
    //   inferior izquierdo -> disminuir
    //   superior derecho   -> confirmar / ingresar
    //   inferior derecho   -> usar el resultado anterior como segundo operando
    //
    // >>> HAY QUE VERIFICAR FISICAMENTE cual switch es cual en la placa. <<<
    // Cargar el diseno, apretar cada boton y ver que hace. Si no calza, se
    // intercambian las cuatro lineas de aqui abajo y listo. NO hay que tocar
    // nada mas del diseno.
    //==========================================================================
    wire raw_up, raw_down, raw_ok, raw_prev;

    assign raw_up   = i_Switch_1;
    assign raw_down = i_Switch_2;
    assign raw_ok   = i_Switch_3;
    assign raw_prev = i_Switch_4;

    //==========================================================================
    // AJUSTE 2: POLARIDAD DE LOS DISPLAYS
    //--------------------------------------------------------------------------
    // Los displays de la Go Board son de ANODO COMUN: el segmento se enciende
    // cuando el pin se pone en BAJO. Por eso invertimos la salida.
    //
    // >>> SI AL PROBAR SE VE EL NEGATIVO DEL NUMERO (todo encendido menos los
    //     segmentos correctos), cambiar este valor a 1'b0. <<<
    //==========================================================================
    localparam SEG_ACTIVO_BAJO = 1'b1;

    wire inv_seg;
    assign inv_seg = SEG_ACTIVO_BAJO;

    //==========================================================================
    // Acondicionamiento de los botones
    //==========================================================================
    wire db_up, db_down, db_ok, db_prev;

    debounce u_db_up   (.clk(i_Clk), .din(raw_up),   .dout(db_up));
    debounce u_db_down (.clk(i_Clk), .din(raw_down), .dout(db_down));
    debounce u_db_ok   (.clk(i_Clk), .din(raw_ok),   .dout(db_ok));
    debounce u_db_prev (.clk(i_Clk), .din(raw_prev), .dout(db_prev));

    wire p_up, p_down, p_ok, p_prev;

    edge_detect u_ed_up   (.clk(i_Clk), .din(db_up),   .pulse(p_up));
    edge_detect u_ed_down (.clk(i_Clk), .din(db_down), .pulse(p_down));
    edge_detect u_ed_ok   (.clk(i_Clk), .din(db_ok),   .pulse(p_ok));
    edge_detect u_ed_prev (.clk(i_Clk), .din(db_prev), .pulse(p_prev));

    //==========================================================================
    // Maquina de estados de la interfaz
    //==========================================================================
    wire [2:0] op_sel;
    wire [3:0] op1;
    wire [3:0] op2_ext;
    wire       sel_op2_prev;
    wire       ejecutar;
    wire [1:0] estado;

    fsm_control u_fsm (
        .clk          (i_Clk),
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

    //==========================================================================
    // La calculadora (ALU de compuertas + registro)
    //==========================================================================
    wire [3:0] resultado;
    wire [3:0] alu_out;
    wire       cout;

    calculator_top u_calc (
        .clk          (i_Clk),
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

    //==========================================================================
    // Que valor mostrar en el display, segun el estado (todo con muxes)
    //==========================================================================
    wire [3:0] b_efectivo;   // el segundo operando que realmente se va a usar
    wire [3:0] disp_alto;
    wire [3:0] disp_valor;

    mux2to1_4bit u_bef (
        .a (op2_ext),
        .b (resultado),
        .s (sel_op2_prev),
        .y (b_efectivo)
    );

    // estado[1] = 1  ->  S_OP2 o S_RES
    mux2to1_4bit u_dh (
        .a (b_efectivo),   // estado 10 = S_OP2
        .b (resultado),    // estado 11 = S_RES
        .s (estado[0]),
        .y (disp_alto)
    );

    mux2to1_4bit u_dv (
        .a (op1),          // estados 00 y 01 -> se muestra op1
        .b (disp_alto),
        .s (estado[1]),
        .y (disp_valor)
    );

    //==========================================================================
    // Separacion en signo y magnitud
    //==========================================================================
    wire       es_negativo;
    wire [3:0] magnitud;

    abs4 u_abs (
        .din (disp_valor),
        .neg (es_negativo),
        .mag (magnitud)
    );

    //==========================================================================
    // Display 1 (izquierdo): SIGNO
    //   solo se enciende el segmento G, que dibuja el guion del menos
    //==========================================================================
    wire [6:0] seg1;

    assign seg1[5:0] = 6'b000000;   // a,b,c,d,e,f apagados
    buf u_signo (seg1[6], es_negativo);

    //==========================================================================
    // Display 2 (derecho): VALOR EN HEXADECIMAL
    //==========================================================================
    wire [6:0] seg2;

    seg7_decoder u_seg (
        .valor  (magnitud),
        .enable (1'b1),
        .seg    (seg2)
    );

    //==========================================================================
    // Salidas fisicas, con la inversion de polaridad aplicada
    //==========================================================================
    xor u_o1a (o_Segment1_A, seg1[0], inv_seg);
    xor u_o1b (o_Segment1_B, seg1[1], inv_seg);
    xor u_o1c (o_Segment1_C, seg1[2], inv_seg);
    xor u_o1d (o_Segment1_D, seg1[3], inv_seg);
    xor u_o1e (o_Segment1_E, seg1[4], inv_seg);
    xor u_o1f (o_Segment1_F, seg1[5], inv_seg);
    xor u_o1g (o_Segment1_G, seg1[6], inv_seg);

    xor u_o2a (o_Segment2_A, seg2[0], inv_seg);
    xor u_o2b (o_Segment2_B, seg2[1], inv_seg);
    xor u_o2c (o_Segment2_C, seg2[2], inv_seg);
    xor u_o2d (o_Segment2_D, seg2[3], inv_seg);
    xor u_o2e (o_Segment2_E, seg2[4], inv_seg);
    xor u_o2f (o_Segment2_F, seg2[5], inv_seg);
    xor u_o2g (o_Segment2_G, seg2[6], inv_seg);

    //==========================================================================
    // LEDs: codigo de la operacion + indicador de "usar resultado anterior"
    //==========================================================================
    buf u_led1 (o_LED_1, op_sel[0]);
    buf u_led2 (o_LED_2, op_sel[1]);
    buf u_led3 (o_LED_3, op_sel[2]);
    buf u_led4 (o_LED_4, sel_op2_prev);

endmodule
`default_nettype wire
