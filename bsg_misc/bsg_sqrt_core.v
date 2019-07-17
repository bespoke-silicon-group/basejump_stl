// -------------------------------------------------------
// -- bsg_sqrt_core.v
// sqlin16@fudan.edu.cn 07/10/2019
// -------------------------------------------------------
// This module performs square root for integer. 
// Latency: width_p + 3 (cycles)

// Input must be normalized to this format before put into this module like:
// op_i: [XX].YYYYYYYY, where [XX] means the integer part of the input and cannot equal to zero.
// Output format is [1].XXXX.
// -------------------------------------------------------

module bsg_sqrt_core #(
  parameter integer width_p = "inv"
  ,parameter bit debug_p = 0
)(
  input clk_i
  ,input reset_i

  ,input [width_p+1:0] op_i // [XX].YYYYYYYYYYYY
  ,input v_i
  ,output ready_o

  ,output [width_p:0] sqrt_o // [1].YYYYYY
  ,output v_o
  ,input yumi_i
);

typedef enum {eIdle, eCal, eCor, eDone} state_e;

state_e state_r;

reg [width_p:0] sfr_r;

always_ff @(posedge clk_i) begin
  if(reset_i) begin
    sfr_r[width_p-1:0] <= '0;
    sfr_r[width_p] <= 1'b1;
  end
  else if(state_r == eIdle && v_i) begin
    sfr_r[width_p-1:0] <= '0;
    sfr_r[width_p] <= 1'b1;
  end
  else if(state_r == eCal) begin
    if(sfr_r[0]) begin
      sfr_r[width_p-1:0] <= '0;
      sfr_r[width_p] <= 1'b1;
    end
    else 
      sfr_r <= (sfr_r >> 1);
  end
end

always_ff @(posedge clk_i) begin
  if(reset_i)
    state_r <= eIdle;
  else unique case(state_r)
    eIdle: if (v_i) state_r <= eCal;
    eCal: if(sfr_r[0]) state_r <= eCor;
    eCor: state_r <= eDone;
    eDone: if(yumi_i) state_r <= eIdle;
  endcase
end

reg [width_p+3:0] ops_r;
reg [width_p:0] sqrt_r;

wire selected_quotient = sfr_r[width_p] | sfr_r[width_p-1] | (~ops_r[width_p+3]); 

wire [width_p+3:0] csa_res;
wire [width_p+3:0] csa_car;
// csa op
wire [width_p+3:0] sqrt_to_subtract = {2'b0, sqrt_r, 1'b0} ^ {(width_p+4){selected_quotient}};
wire [width_p+3:0] sfr_to_subtract = {3'b0, sfr_r};

bsg_adder_carry_save #(
  .width_p(width_p+4)
) aggregator (
  .opA_i(ops_r)
  ,.opB_i(sqrt_to_subtract)
  ,.opC_i(~sfr_to_subtract)

  ,.res_o(csa_res)
  ,.car_o(csa_car)
);

wire [width_p+3:0] p_cpa_out = csa_res + {csa_car[width_p+2:0], 1'b1} + selected_quotient;

// p_cpa_out
logic [width_p:0] d_cpa_opA;
logic [width_p:0] d_cpa_opB;
logic d_cpa_opcode;
always_comb begin
  if(state_r == eCor) begin
    d_cpa_opA = sqrt_r;
    d_cpa_opB = {(width_p+1){ops_r[width_p+3]}};
    d_cpa_opcode = 1'b0;
  end
  else begin
    d_cpa_opcode = (~selected_quotient);
    d_cpa_opA = sqrt_r;
    d_cpa_opB = sfr_r ^ {(width_p+1){~selected_quotient}};
  end

end
wire [width_p:0] d_cpa_out = d_cpa_opA + d_cpa_opB + d_cpa_opcode;

always_ff @(posedge clk_i) begin
  if(reset_i) begin
    ops_r <= '0;
    sqrt_r <= '0;
  end
  else unique case(state_r)
    eIdle: if(v_i) begin
      ops_r <= {2'b0, op_i};
      sqrt_r <= '0; 
    end
    eCal: begin
      ops_r <= p_cpa_out << 1;
      sqrt_r <= d_cpa_out;
    end
    eCor: begin
      sqrt_r <= d_cpa_out;
    end
  endcase
end

assign ready_o = state_r == eIdle;
assign v_o = state_r == eDone;
assign sqrt_o = sqrt_r;

if(debug_p) begin
  always_ff @(posedge clk_i) begin
    $display("============BSG SQRT CORE=============");
    $display("state_r:%s", state_r.name());
    $display("sfr_r:%b",sfr_r);
    $display("ops_r:%b",ops_r);
    $display("sqrt_r:%b",sqrt_r);
    $display("selected_quotient:%b",selected_quotient);
  end
end

endmodule
