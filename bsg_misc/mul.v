// -------------------------------------------------------
// -- mul.v
// -------------------------------------------------------
// This is wrapper for Synopsys * operator in pipeline form.
// Remember to apply retiming on this module when synthesizing. 
// -------------------------------------------------------


module mul #(
  parameter integer width_p = "inv"
  ,parameter integer stage_p = "inv"
)(

  input clk_i
  ,input reset_i

  ,input [width_p-1:0] opA_i
  ,input [width_p-1:0] opB_i

  ,output [2*width_p-1:0] res_o
);
  wire [2*width_p-1:0] data_li = opA_i * opB_i;
  reg [stage_p-2:0][2*width_p-1:0] delay_r;
  for(genvar i = 0; i < stage_p-1; ++i) begin: dff_chain
    if(i == 0) begin: first_sage
      always_ff @(posedge clk_i) begin // update for delay_r
        if(reset_i) begin
          delay_r[0] <= '0;
        end
        else
          delay_r[0] <= data_li;
      end
    end //first_sage
    else begin: other_stage
      always_ff @(posedge clk_i) begin // update for delay_r
        if(reset_i) begin
          delay_r[i] <= '0;
        end
        else
          delay_r[i] <= delay_r[i-1];
      end
    end: other_stage
  end: dff_chain
  assign res_o = delay_r[stage_p-2];
endmodule
