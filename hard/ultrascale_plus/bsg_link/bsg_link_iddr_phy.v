
//
// Paul Gao 03/2019
//
// Input DDR PHY 
//
// The output data is a 2x wide data bus synchronized to the posedge of clk_i
// The MSBs of the output data is the negedge registered data while the LSBs of the 
// output data is the posedge registered data
// * Posedge (LSB) data received earlier in time than MSB data
//
// Note that input clock edges must be center-aligned to input data signals
// Need input delay constraint(s) to ensure clock and data delay are same
//
//

module bsg_link_iddr_phy

 #(parameter width_p = "inv")

  (input                  clk_i
  ,input  [width_p-1:0]   data_i
  ,output [2*width_p-1:0] data_r_o
  );
  
  logic [width_p-1:0] data_li;

  for (genvar i = 0; i < width_p; i++)
  begin
    IDELAYE3 
   #(.CASCADE         ("NONE")
    ,.DELAY_FORMAT    ("COUNT")
    ,.DELAY_SRC       ("IDATAIN")
    ,.DELAY_TYPE      ("FIXED")
    // DELAY_VALUE should be configured based on FPGA's input clock tree delay
    // Delay time for each count (tap) can be found in Xilinx Doc
    // "FPGA Data Sheet: DC and AC Switching Characteristics" (Search IDELAY_RESOLUTION)
    ,.DELAY_VALUE     (192)
    ,.IS_CLK_INVERTED (1'b0)
    ,.IS_RST_INVERTED (1'b0)
    ,.REFCLK_FREQUENCY(500.0)
    ,.SIM_DEVICE      ("ULTRASCALE_PLUS")
    ,.UPDATE_MODE     ("ASYNC")
    ) IDELAYE3_inst 
    (.CASC_OUT        ()
    ,.CNTVALUEOUT     ()
    ,.DATAOUT         (data_li[i])
    ,.CASC_IN         (1'b0)
    ,.CASC_RETURN     (1'b0)
    ,.CE              (1'b0)
    ,.CLK             (1'b0)
    ,.CNTVALUEIN      ('0)
    ,.DATAIN          (1'b0)
    ,.EN_VTC          (1'b0)
    ,.IDATAIN         (data_i[i])
    ,.INC             (1'b0)
    ,.LOAD            (1'b0)
    ,.RST             (1'b0)
    );
  
    IDDRE1 
   #(.DDR_CLK_EDGE  ("SAME_EDGE_PIPELINED")
    ,.IS_CB_INVERTED(1'b1)
    ,.IS_C_INVERTED (1'b0)
    ) IDDRE1_inst 
    (.Q1            (data_r_o[i])
    ,.Q2            (data_r_o[i+width_p])
    ,.C             (clk_i)
    ,.CB            (clk_i)
    ,.D             (data_li[i])
    ,.R             (1'b0)
    );
  end

endmodule
