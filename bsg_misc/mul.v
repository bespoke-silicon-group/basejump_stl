// This module is used for PPA comparison
module mul #(
  parameter integer reg_num_p = 3
)(
  input clk_i
  ,input reset_i
  ,input [31:0] a_i
  ,input [31:0] b_i 
  ,output [63:0] o
);
  if(reg_num_p > 0) begin
    reg [reg_num_p-1:0][31:0] sfr_a_r;
    reg [reg_num_p-1:0][31:0] sfr_b_r;
    for(genvar i = 0; i < reg_num_p; ++i) begin
      wire [31:0] sfr_a_n;
      wire [31:0] sfr_b_n;
      if(i == 0) begin
        assign sfr_a_n = a_i;
        assign sfr_b_n = b_i;
      end
      else begin
        assign sfr_a_n = sfr_a_r[i-1];
        assign sfr_b_n = sfr_b_r[i-1];
      end
      always_ff @(posedge clk_i) begin
        if(reset_i) begin
          sfr_a_r[i] <= '0;
          sfr_b_r[i] <= '0;
        end
        else begin
          sfr_a_r[i] <= sfr_a_n;
          sfr_b_r[i] <= sfr_b_n;
        end
      end
    end
    assign o = sfr_a_r[reg_num_p-1] * sfr_b_r[reg_num_p-1];
  end 
  else begin
    assign o = a_i * b_i;
  end
endmodule
