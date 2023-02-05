
//
// Paul Gao 03/2019
//
// This is an output DDR PHY
//
// Output clock is center-aligned to output data
// Theoretically clk_r_o is always centered to data_r_o, because negedge of clk_i
// has 90-degree phase delay to posedge of clk_i.
// Need output delay constraint(s) to ensure clock and data delay are same
//
//

module bsg_link_oddr_phy

 #(parameter width_p = "inv")

  (// reset, data and ready signals synchronous to clk_i
   // no valid signal required (assume valid_i is constant 1)
   input                      reset_i
  ,input                      clk_i
  ,input                      clk90_i
  ,input [1:0][width_p-1:0]   data_i
  ,output                     ready_o
   // output clock and data
  ,output logic [width_p-1:0] data_r_o
  ,output logic               clk_r_o
  );

  // ODDR PHY is always ready for incoming data
  assign ready_o = 1'b1;
  
  logic [1:0][width_p-1:0] data_r;  
  bsg_dff #(.width_p(width_p*2)) dff_oddr
  (.clk_i (clk_i)
  ,.data_i(data_i)
  ,.data_o(data_r));
  
  for (genvar i = 0; i < width_p; i++)
  begin
    ODDRE1 
   #(.IS_C_INVERTED (1'b0)
    ,.IS_D1_INVERTED(1'b0)
    ,.IS_D2_INVERTED(1'b0)
    ,.SIM_DEVICE    ("ULTRASCALE_PLUS")
    ,.SRVAL         (1'b0)
    ) ODDRE1_inst 
    (.Q             (data_r_o[i])
    ,.C             (clk_i)
    ,.D1            (data_r[0][i])
    ,.D2            (data_r[1][i])
    ,.SR            (reset_i)
    );
  end
  
    ODDRE1 
   #(.IS_C_INVERTED (1'b0)
    ,.IS_D1_INVERTED(1'b0)
    ,.IS_D2_INVERTED(1'b0)
    ,.SIM_DEVICE    ("ULTRASCALE_PLUS")
    ,.SRVAL         (1'b0)
    ) ODDRE1_clk 
    (.Q             (clk_r_o)
    ,.C             (clk90_i)
    ,.D1            (1'b1)
    ,.D2            (1'b0)
    ,.SR            (reset_i)
    );

endmodule
