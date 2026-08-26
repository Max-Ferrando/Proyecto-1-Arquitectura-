`default_nettype none
//==============================================================================
// calculator_top - Calculadora completa: ALU + registro de resultado
//------------------------------------------------------------------------------
// Este es el modulo que exige el enunciado en la seccion 2:
//   - entrada op1 de 4 bits
//   - selector de operacion de 3 bits
//   - selector de 1 bit para el segundo operando (op2 externo / resultado previo)
//   - un registro de 4 bits que almacena el resultado
//   - una senal que confirma / ejecuta la operacion
//
// TODA la logica combinacional viene de submodulos hechos solo con compuertas.
//
// SOBRE EL UNICO 'always' DEL DISENO
//   El registro es logica SECUENCIAL, no combinacional, asi que no lo alcanza
//   la restriccion del enunciado (que habla de "la logica combinacional de la
//   calculadora"). Aun asi lo dejamos lo mas limpio posible:
//
//     - la decision "mantener el valor / cargar el nuevo resultado" se resuelve
//       con un mux2to1_4bit hecho de compuertas, NO con un if;
//     - el reset sincrono se aplica con compuertas AND, NO con un if;
//     - el always solo contiene la transferencia del flip-flop.
//
//   El operador '<=' que aparece abajo es la ASIGNACION NO BLOQUEANTE de
//   Verilog (la forma estandar y correcta de describir un flip-flop), no el
//   operador de comparacion "menor o igual" que prohibe el enunciado.
//==============================================================================
module calculator_top (
    input  wire       clk,          // reloj
    input  wire       rst,          // reset sincrono del registro (activo en alto)
    input  wire       ejecutar,     // habilita la carga del resultado
    input  wire [3:0] op1,          // primer operando
    input  wire [3:0] op2_ext,      // segundo operando externo
    input  wire       sel_op2_prev, // 0 = usa op2_ext ; 1 = usa el resultado anterior
    input  wire [2:0] op_sel,       // selector de operacion
    output wire [3:0] resultado,    // valor almacenado en el registro
    output wire [3:0] alu_out,      // salida combinacional de la ALU (antes del registro)
    output wire       cout          // acarreo del sumador (informativo)
);

    // ------------------------------------------------------------------
    // Segundo operando: externo o realimentado desde el registro
    // ------------------------------------------------------------------
    wire [3:0] b_operando;

    op2_select u_op2 (
        .op2_ext     (op2_ext),
        .prev_result (resultado),
        .sel_prev    (sel_op2_prev),
        .b           (b_operando)
    );

    // ------------------------------------------------------------------
    // Logica combinacional (todo compuertas)
    // ------------------------------------------------------------------
    alu4 u_alu (
        .a    (op1),
        .b    (b_operando),
        .op   (op_sel),
        .r    (alu_out),
        .cout (cout)
    );

    // ------------------------------------------------------------------
    // Registro de 4 bits
    // ------------------------------------------------------------------
    reg  [3:0] q_reg = 4'b0000;
    wire [3:0] d_cargado;   // resultado del mux mantener/cargar
    wire [3:0] d_next;      // despues de aplicar el reset
    wire       n_rst;

    // "mantener o cargar" resuelto con un mux de compuertas (no con un if)
    mux2to1_4bit u_hold (
        .a (q_reg),       // ejecutar = 0 -> se mantiene el valor actual
        .b (alu_out),     // ejecutar = 1 -> se carga el nuevo resultado
        .s (ejecutar),
        .y (d_cargado)
    );

    // reset sincrono aplicado con compuertas (no con un if)
    not u_nrst (n_rst, rst);
    and u_d0 (d_next[0], d_cargado[0], n_rst);
    and u_d1 (d_next[1], d_cargado[1], n_rst);
    and u_d2 (d_next[2], d_cargado[2], n_rst);
    and u_d3 (d_next[3], d_cargado[3], n_rst);

    // el unico bloque secuencial de todo el diseno
    always @(posedge clk) begin
        q_reg <= d_next;
    end

    assign resultado = q_reg;

endmodule
`default_nettype wire
