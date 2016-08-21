// This is the toplevel module for the clock generator. The clock generator
// internally contains a config node, a ring oscillator, and a clock
// downsampler as well as a external clock pass through. To select between
// the ring oscillator, the downsampled ring oscillator and the external
// pass-through clock use the 2-bit select_i signal. Below is the config
// node data packet payload for this module.
//
// Config Node Data Packet
// High Bits
//      n-bit - downsampler - downsample value
//      7-bit - clock generator control - controls speed of the clock generator
//      {
//        1-bit - ADG16 ctrl  - control speed of ADG16 stage of CG
//        1-bit - ADG8 ctrl   - control speed of ADG8 stage of CG
//        2-bit - CDT ctrl    - control speed of CDT stage of CG
//        2-bit - FDT Ctrl    - control speed of FDT stage of CG
//        1-bit - Power Off   - if 1, power off CG
//      }
// Low Bits
// 
`include "config_defs.v"

module bsg_clk_gen
 #(parameter downsample_width_p = "inv"
  ,          cnode_id_p         = "inv"
  ,          cnode_data_bits_lp = 7 + downsample_width_p
  ,          cnode_default_lp   = {cnode_data_bits_lp {1'b0}}
  )
  (input  config_s          config_i
  ,input                    async_rst_i
  ,input                    reset_i
  ,input                    ext_clk_i
  ,input  [1:0]             select_i
  ,output logic             clk_o
  );

  logic                             osc_clk_out;                // oscillator output clock
  logic                             ds_clk_out;                 // downsampled output clock
  logic [cnode_data_bits_lp-1:0]    cnode_data_n, cnode_data_r; // config node data out
  logic                             cnode_been_rst;             // indicates if the config node has been reset

  // Config Node Instance
  //
  config_node #(.id_p(cnode_id_p), .data_bits_p(cnode_data_bits_lp), .default_p(cnode_default_lp)) cnode_inst
    (.clk(osc_clk_out)
    ,.reset(reset_i)
    ,.config_i(config_i)
    ,.data_o(cnode_data_n)
    );

  // Clock Generator (CG) Instance
  //
  bsg_clk_gen_osc clk_gen_osc_inst
    (.clk(osc_clk_out)
    ,.rst(async_rst_i)
    ,.adg_ctrl(cnode_data_r[6:5])
    ,.cdt(cnode_data_r[4:3])
    ,.fdt(cnode_data_r[2:1])
    ,.pwr_off(cnode_data_r[0])
    );

  // Clock Downsampler
  //
  bsg_counter_clock_downsample #(.width_p(downsample_width_p)) clk_gen_ds_inst
    (.clk_i(osc_clk_out)
    ,.reset_i(reset_i)
    ,.val_i(cnode_data_r[cnode_data_bits_lp-1:7])
    ,.clk_r_o(ds_clk_out)
    );

  // Edge balanced mux for selecting the clocks
  //
  bsg_edge_balanced_mux4 mux_inst
    (.A(osc_clk_out)
    ,.B(ds_clk_out)
    ,.C(ext_clk_i)
    ,.D(ext_clk_i)
    ,.S(select_i)
    ,.Y(clk_o)
    );
  
  // This logic is to add a register between the data coming from config node
  // into the ring oscillator. We need to disable the data link between these
  // two modules until config node has been reset. To keep track of this, we
  // use a register to keep track if config node has been reset.
  //
  always_ff @(posedge osc_clk_out or posedge async_rst_i)
    begin
      if (async_rst_i)
        cnode_been_rst <= 1'b0;
      else if (reset_i)
        cnode_been_rst <= 1'b1;
    end

  always_ff @(negedge osc_clk_out or posedge async_rst_i)
    begin
      if (async_rst_i)
        cnode_data_r <= cnode_default_lp;
      else if (cnode_been_rst)
        cnode_data_r <= cnode_data_n;
    end

endmodule

