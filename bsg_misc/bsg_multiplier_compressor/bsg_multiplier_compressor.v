module bsg_multiplier_compressor #(
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
  if (width_p == 64) begin:WIDTH_64
    if(stride_p == 16) begin: STRIDE_16
      bsg_multiplier_compressor_64_16 wt(.*);
    end
    else if(stride_p == 32) begin: STRIDE_32
      bsg_multiplier_compressor_64_32 wt(.*);
    end
    else if(stride_p == 22) begin: STRIDE_22
      bsg_multiplier_compressor_64_22 wt(.*);
    end
    else if(stride_p == 64) begin: STRIDE_64
      bsg_multiplier_compressor_64_64 wt(.*);
    end
  end
  else if(width_p == 32) begin: WIDTH_32
    if(stride_p == 32) begin: STRIDE_32
      bsg_multiplier_compressor_32_32 wt(.*);
    end
    else if(stride_p == 16) begin: STRIDE_16
      bsg_multiplier_compressor_32_16 wt(.*);
    end
    else if(stride_p == 8) begin: STRIDE_8
      bsg_multiplier_compressor_32_8 wt(.*);
    end
  end
  else if(width_p == 8) begin: WIDTH_8
    if(stride_p == 8) begin: STRIDE_8
      bsg_multiplier_compressor_8_8 wt(.*);
    end
  end
endmodule
