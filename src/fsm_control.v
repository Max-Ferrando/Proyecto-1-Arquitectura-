`default_nettype none
//==============================================================================
// fsm_control - Maquina de estados de la interfaz de botones
//------------------------------------------------------------------------------
// Implementa la secuencia que describe la seccion 5 del enunciado:
//
//   1. Se ingresa la OPERACION. Su codigo se muestra en los LED.
//   2. Se ingresa el PRIMER operando. Se muestra en el display.
//   3. Se ingresa el SEGUNDO operando (o se elige el resultado anterior).
//   4. Se ejecuta la operacion y se muestra el RESULTADO.
//   5. Al confirmar de nuevo se vuelve al paso 1.
//
// DIAGRAMA DE ESTADOS
//
//            p_ok            p_ok            p_ok            p_ok
//   S_OP --------> S_OP1 --------> S_OP2 --------> S_RES --------+
//     ^                                             |            |
//     +---------------------------------------------+------------+
//
//   En cada estado, p_up / p_down incrementan o decrementan el valor que se
//   esta editando en ese momento (reutilizando updown4, que a su vez reutiliza
//   el adder4 de la calculadora).
//
//   En S_OP2, p_prev marca que el segundo operando sea el resultado anterior.
//
//   Al pasar de S_OP2 a S_RES se emite un pulso 'ejecutar' de un ciclo, que es
//   lo que hace que calculator_top cargue el resultado en su registro.
//
//------------------------------------------------------------------------------
// SOBRE LA RESTRICCION DEL ENUNCIADO
//   Igual que debounce.v: esto es logica SECUENCIAL de control de la interfaz,
//   no la logica combinacional de la calculadora. El calculo en si (alu4) es
//   100% compuertas. Ver la nota en debounce.v y CONFIRMAR con el profesor.
//==============================================================================
module fsm_control (
    input  wire       clk,
    input  wire       p_up,      // pulso: incrementar
    input  wire       p_down,    // pulso: decrementar
    input  wire       p_ok,      // pulso: confirmar / ejecutar
    input  wire       p_prev,    // pulso: usar el resultado anterior como op2

    output reg  [2:0] op_sel       = 3'b000,
    output reg  [3:0] op1          = 4'b0000,
    output reg  [3:0] op2_ext      = 4'b0000,
    output reg        sel_op2_prev = 1'b0,
    output reg        ejecutar     = 1'b0,
    output reg  [1:0] estado       = 2'd0
);

    localparam [1:0] S_OP  = 2'd0;   // ingresando la operacion
    localparam [1:0] S_OP1 = 2'd1;   // ingresando el primer operando
    localparam [1:0] S_OP2 = 2'd2;   // ingresando el segundo operando
    localparam [1:0] S_RES = 2'd3;   // mostrando el resultado

    // ------------------------------------------------------------------
    // Incremento / decremento del valor que se esta editando.
    // Son tres instancias del MISMO sumador de la calculadora.
    // ------------------------------------------------------------------
    wire [3:0] op_extendido;
    wire [3:0] op_nxt, op1_nxt, op2_nxt;

    assign op_extendido = {1'b0, op_sel};

    updown4 u_up_op  (.din(op_extendido), .dec(p_down), .dout(op_nxt));
    updown4 u_up_op1 (.din(op1),          .dec(p_down), .dout(op1_nxt));
    updown4 u_up_op2 (.din(op2_ext),      .dec(p_down), .dout(op2_nxt));

    wire mover;
    or u_mover (mover, p_up, p_down);

    // ------------------------------------------------------------------
    // Transiciones
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        ejecutar <= 1'b0;      // por defecto: pulso de un solo ciclo

        case (estado)

            S_OP: begin
                if (mover) op_sel <= op_nxt[2:0];   // da la vuelta 0..7 solo
                if (p_ok)  estado <= S_OP1;
            end

            S_OP1: begin
                if (mover) op1    <= op1_nxt;
                if (p_ok)  estado <= S_OP2;
            end

            S_OP2: begin
                if (p_prev) sel_op2_prev <= 1'b1;
                if (mover) begin
                    op2_ext      <= op2_nxt;
                    sel_op2_prev <= 1'b0;   // al editar a mano se deja de usar el previo
                end
                if (p_ok) begin
                    ejecutar <= 1'b1;       // <- aqui se carga el registro
                    estado   <= S_RES;
                end
            end

            S_RES: begin
                if (p_ok) begin
                    estado       <= S_OP;
                    sel_op2_prev <= 1'b0;
                end
            end

        endcase
    end

endmodule
`default_nettype wire
