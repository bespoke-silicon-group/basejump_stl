
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
// Waveform of all signals when going out of reset:
/******************************************************************************************

          +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+
clk_i         |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
              +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+
          +--------+
reset_i            |
                   +----------------------------------------------------------------------+
          +----------------+
reset_i_r                  |
                           +--------------------------------------------------------------+
                               +-------+       +-------+       +-------+       +-------+
clk_r                          |       |       |       |       |       |       |       |
          +--------------------+       +-------+       +-------+       +-------+       +---
                           +-------+       +-------+       +-------+       +-------+
odd_r                      |       |       |       |       |       |       |       |
          +----------------+       +-------+       +-------+       +-------+       +-------
          +----------------+       +-------+       +-------+       +-------+       +-------
ready_o                    |       |       |       |       |       |       |       |
                           +-------+       +-------+       +-------+       +-------+
          +--------+-----------------------------------------------------------------------
data_i    |        | d1d0  |       | d1d0  |       | d1d0  |       | d1d0  |       | d1d0
          +--------------------------------------------------------------------------------
          +--------------------------------------------------------------------------------
data_i_r  |                |     d1d0      |     d1d0      |     d1d0      |     d1d0
          +----------------+---------------------------------------------------------------
                                       +-------+       +-------+       +-------+       +---
clk_o                                  |       |       |       |       |       |       |
          +----------------------------+       +-------+       +-------+       +-------+
          +--------------------------------+---------------+---------------+---------------
data_o    |                        |  d0   |  d1   |  d0   |  d1   |  d0   |  d1   |  d0
          +------------------------+-------+-------+-------+-------+-------+-------+-------

******************************************************************************************/
//
// Schematic and more information: (Google Doc) 
// https://docs.google.com/document/d/1lmkOxvlAvxrk_MM5W8xv3ho2DS26xbOMTCqUIyS6di8/edit?ts=5cf76063#heading=h.o6ptt6mn49us
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
  
  assign ready_o = 1'b1;
  //logic [width_p-1:0] data_r_lo;
  //logic clk_r_lo;
  
  logic [1:0][width_p-1:0] data_li;  
  bsg_dff #(.width_p(width_p*2)) dff_oddr
  (.clk_i (clk_i)
  ,.data_i(data_i)
  ,.data_o(data_li));
  
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
    ,.D1            (data_li[0][i])
    ,.D2            (data_li[1][i])
    ,.SR            (reset_i)
    );
/*    
    ODELAYE3 
   #(.CASCADE         ("NONE")
    ,.DELAY_FORMAT    ("COUNT")
    ,.DELAY_TYPE      ("FIXED")
    //,.DELAY_VALUE     (144)
    ,.DELAY_VALUE     (64)
    ,.IS_CLK_INVERTED (1'b0)
    ,.IS_RST_INVERTED (1'b0)
    ,.REFCLK_FREQUENCY(300.0)
    ,.SIM_DEVICE      ("ULTRASCALE_PLUS")
    ,.UPDATE_MODE     ("ASYNC")
    )
    ODELAYE3_inst 
    (.CASC_OUT        ()
    ,.CNTVALUEOUT     ()
    ,.DATAOUT         (data_r_o[i])
    ,.CASC_IN         (1'b0)
    ,.CASC_RETURN     (1'b0)
    ,.CE              (1'b0)
    ,.CLK             (1'b0)
    ,.CNTVALUEIN      ('0)
    ,.EN_VTC          (1'b0)
    ,.INC             (1'b0)
    ,.LOAD            (1'b0)
    ,.ODATAIN         (data_r_lo[i])
    ,.RST             (1'b0)
    );
*/
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
/*    
    ODELAYE3 
   #(.CASCADE         ("NONE")
    ,.DELAY_FORMAT    ("COUNT")
    ,.DELAY_TYPE      ("FIXED")
    //,.DELAY_VALUE     (144)
    ,.DELAY_VALUE     (8)
    ,.IS_CLK_INVERTED (1'b0)
    ,.IS_RST_INVERTED (1'b0)
    ,.REFCLK_FREQUENCY(300.0)
    ,.SIM_DEVICE      ("ULTRASCALE_PLUS")
    ,.UPDATE_MODE     ("ASYNC")
    )
    ODELAYE3_clk 
    (.CASC_OUT        ()
    ,.CNTVALUEOUT     ()
    ,.DATAOUT         (clk_r_o)
    ,.CASC_IN         (1'b0)
    ,.CASC_RETURN     (1'b0)
    ,.CE              (1'b0)
    ,.CLK             (1'b0)
    ,.CNTVALUEIN      ('0)
    ,.EN_VTC          (1'b0)
    ,.INC             (1'b0)
    ,.LOAD            (1'b0)
    ,.ODATAIN         (clk_r_lo)
    ,.RST             (1'b0)
    );
*/  
endmodule
