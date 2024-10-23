
`include "bsg_defines.sv"

module bsg_link_isdr_phy

 #(parameter `BSG_INV_PARAM(width_p ))

  (input                clk_i
  ,output               clk_o
  ,input  [width_p-1:0] data_i
  ,output [width_p-1:0] data_o
  ,input                token_i
  ,output               token_o
  );

  wire [width_p-1:0] data_i_buf;

  CKBD4BWP7T40P140 BSG_ISDR_CKBUF_BSG_DONT_TOUCH (.I(clk_i),.Z(clk_o));
  CKBD4BWP7T40P140 BSG_ISDR_TKNBUF_BSG_DONT_TOUCH (.I(token_i),.Z(token_o));

  for (genvar i = 0; i < width_p; i++)
  begin: data
    CKBD4BWP7T40P140 BSG_ISDR_BUF_BSG_DONT_TOUCH
    (.I(data_i[i]),.Z(data_i_buf[i]));
    DFQD1BWP7T40P140 BSG_ISDR_DFFQ
    (.D(data_i_buf[i]),.CP(clk_o),.Q(data_o[i]));
  end

endmodule
`BSG_ABSTRACT_MODULE(bsg_link_isdr_phy)
