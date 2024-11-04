
module bsg_link_osdr_phy

 #(parameter `BSG_INV_PARAM(width_p    )
  ,parameter strength_p = 0)

  (input                clk_i
  ,input                reset_i
  ,input  [width_p-1:0] data_i
  ,output               clk_o
  ,output [width_p-1:0] data_o
  ,input                token_i
  ,output               token_o
  );

`define BSG_LINK_OSDR_PHY_CKBUF_INST_MACRO(strength,name,in,out)          \
  begin: s``strength``                                                    \
    SC7P5T_CKBUFX``strength``_SSC14R ``name`` (.CLK(``in``),.Z(``out``)); \
  end

`define BSG_LINK_OSDR_PHY_CKBUF_STRENGTH_MACRO(strength,name,in,out) \
  if (strength_p >= ``strength``)                                    \
    `BSG_LINK_OSDR_PHY_CKBUF_INST_MACRO(strength,name,in,out)

`define BSG_LINK_OSDR_PHY_CKBUF_MACRO(name,in,out)             \
  `BSG_LINK_OSDR_PHY_CKBUF_STRENGTH_MACRO(16,name,in,out) else \
  `BSG_LINK_OSDR_PHY_CKBUF_STRENGTH_MACRO(14,name,in,out) else \
  `BSG_LINK_OSDR_PHY_CKBUF_STRENGTH_MACRO(12,name,in,out) else \
  `BSG_LINK_OSDR_PHY_CKBUF_STRENGTH_MACRO(10,name,in,out) else \
  `BSG_LINK_OSDR_PHY_CKBUF_STRENGTH_MACRO(8,name,in,out)  else \
  `BSG_LINK_OSDR_PHY_CKBUF_STRENGTH_MACRO(6,name,in,out)  else \
  `BSG_LINK_OSDR_PHY_CKBUF_INST_MACRO(4,name,in,out)

  wire clk_r_p, clk_r_n, clk_o_buf;
  wire [width_p-1:0] data_o_buf;

  SC7P5T_CKXOR2X2_SSC14R BSG_OSDR_CKXOR2_BSG_DONT_TOUCH
  (.Z(clk_o_buf),.CLK(clk_r_p),.EN(clk_r_n));
  `BSG_LINK_OSDR_PHY_CKBUF_MACRO(BSG_OSDR_CKBUF_BSG_DONT_TOUCH, clk_o_buf, clk_o)
  if (1) begin: token
  `BSG_LINK_OSDR_PHY_CKBUF_MACRO(BSG_OSDR_TKNBUF_BSG_DONT_TOUCH, token_i, token_o)
  end

  SC7P5T_DFFQX2_SSC14R BSG_OSDR_DFFPOS_BSG_DONT_TOUCH
  (.D(~(clk_r_p|reset_i)),.CLK(clk_i),.Q(clk_r_p));
  SC7P5T_DFFNQX2_SSC14R BSG_OSDR_DFFNEG_BSG_DONT_TOUCH
  (.D(~(clk_r_n|reset_i)),.CLK(clk_i),.Q(clk_r_n));

  for (genvar i = 0; i < width_p; i++)
  begin: data
    SC7P5T_DFFQX1_SSC14R BSG_OSDR_DFFQ
    (.D(data_i[i]),.CLK(clk_i),.Q(data_o_buf[i]));
    `BSG_LINK_OSDR_PHY_CKBUF_MACRO(BSG_OSDR_BUF_BSG_DONT_TOUCH, data_o_buf[i], data_o[i])
  end

endmodule
`BSG_ABSTRACT_MODULE(bsg_link_osdr_phy)
