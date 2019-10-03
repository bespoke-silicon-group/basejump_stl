module bsg_adder_wallace_tree_3_2 #(
  parameter integer width_p = "inv"
  ,parameter integer stride_p = "inv"
  ,localparam integer out_width_p = (width_p + stride_p + 4) > 2*width_p ? 2*width_p : (width_p + stride_p + 4)
  ,localparam integer booth_step_lp = stride_p / 2
)(
  input [1:0][width_p+3:0] base_i
  ,input [booth_step_lp-1:0][width_p+2:0] psum_i
  ,input [booth_step_lp-1:0] sign_modification_i
  ,output [out_width_p-1:0] outA_o
  ,output [out_width_p-1:0] outB_o
);
  if(width_p == 32) begin
    if(stride_p == 32) begin
      bsg_multiplier_compressor_32_32 wt(.*);
    end
  end
  else if(width_p == 8) begin
    if(stride_p == 8) begin
      bsg_multiplier_compressor_8_8 wt(.*);
    end
  end
endmodule
