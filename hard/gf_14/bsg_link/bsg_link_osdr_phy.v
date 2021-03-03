
module bsg_link_osdr_phy

 #(parameter width_p = "inv")

  (input                clk_i
  ,input                reset_i
  ,input  [width_p-1:0] data_i
  ,output               clk_o
  ,output [width_p-1:0] data_o
  );

  wire clk_r_p, clk_r_n, clk_o_buf;
  wire [width_p-1:0] data_o_buf;

  SC7P5T_CKXOR2X1_SSC14R BSG_OSDR_CKXOR2_DONT_TOUCH
  (.Z(clk_o_buf),.CLK(clk_r_p),.EN(clk_r_n));
  SC7P5T_CKBUFX2_SSC14R BSG_OSDR_CKBUF_DONT_TOUCH
  (.CLK(clk_o_buf),.Z(clk_o));

  SC7P5T_DFFQX1_SSC14R BSG_OSDR_DFFPOS_DONT_TOUCH
  (.D(~(clk_r_p|reset_i)),.CLK(clk_i),.Q(clk_r_p));
  SC7P5T_DFFNQX1_SSC14R BSG_OSDR_DFFNEG_DONT_TOUCH
  (.D(~(clk_r_n|reset_i)),.CLK(clk_i),.Q(clk_r_n));

  for (genvar i = 0; i < width_p; i++)
  begin: data
    SC7P5T_DFFQX1_SSC14R BSG_OSDR_DFFQ
    (.D(data_i[i]),.CLK(clk_i),.Q(data_o_buf[i]));
    SC7P5T_BUFX2_SSC14R BSG_OSDR_BUF_DONT_TOUCH
    (.A(data_o_buf[i]),.Z(data_o[i]));
  end

endmodule