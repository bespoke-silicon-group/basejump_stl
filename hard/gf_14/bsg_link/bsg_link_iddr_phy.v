
module bsg_link_iddr_phy

 #(parameter width_p = "inv")

  (input                  clk_i
  ,output                 clk_o
  ,input  [width_p-1:0]   data_i
  ,output [2*width_p-1:0] data_r_o
  );

  logic [2*width_p-1:0] data_rr;
  logic [width_p-1:0] data_n_r, data_p_r;
  logic [width_p-1:0] data_i_buf;

  SC7P5T_CKBUFX2_SSC14R BSG_IDDR_CKBUF_DONT_TOUCH (.CLK(clk_i),.Z(clk_o));
  assign data_r_o = data_rr;

  always_ff @(posedge clk_i) 
    // First buffer posedge data into data_p_r
    data_p_r <= data_i_buf;
  
  always_ff @(negedge clk_i)
    // Then buffer negedge data into data_n_r
    data_n_r <= data_i_buf;
    
  always_ff @(posedge clk_i) 
    // Finally output to the data_rr flop
    // data_p_r occurs logically earlier in time than data_n_r
    data_rr <= {data_n_r, data_p_r};

  for (genvar i = 0; i < width_p; i++)
  begin: data
    SC7P5T_BUFX2_SSC14R BSG_IDDR_BUF_DONT_TOUCH
    (.A(data_i[i]),.Z(data_i_buf[i]));
  end

endmodule
