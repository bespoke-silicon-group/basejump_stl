// This module receives configuration data in serial using config tag
// protocol and outputs the configuration for mesosynchronous channel. 
// IT includes four config nodes which each of them are in charge of
// some part of the configuration. In addition, it generates the reset
// for the channel, by detecting change of reset signal from 01 to 10.

//`ifndef DEFINITIONS_V
//`include "definitions.v"
//`endif

module bsg_mesosync_config_tag_extractor
                  #(  parameter ch1_width_p = 5
                    , parameter ch2_width_p = 5
                    , parameter cfg_tag_base_id_p = 10
                    
                    , parameter width_lp = ch1_width_p + ch2_width_p
                   )
                   (  input                           clk
                    , input                           reset
                    
                    , input  config_s                 config_i

                    // Configuration output
                    , output clk_divider_s            clk_divider_o
                    , output bit_cfg_s [width_lp-1:0] bit_cfg_o
                    , output mode_cfg_s               mode_cfg_o
                    , output [$clog2(width_lp)-1:0]   la_input_bit_selector_o
                    , output [$clog2(width_lp)-1:0]   la_output_bit_selector_o
                    , output [$clog2(width_lp)-1:0]   v_output_bit_selector_o
                    , output logic                    fifo_en_o
                    , output logic                    loop_back_o
                    , output logic                    channel_reset_o
                    );
    
// internal signals
logic [1:0] cfg_reset, cfg_reset_r;

// Calcuating data width of each configuration node
parameter divider_node_data_width_p     = $bits(clk_divider_o) + 2;
parameter ch1_bit_cfg_node_data_width_p = $bits(bit_cfg_o[ch1_width_p-1:0]);
parameter ch2_bit_cfg_node_data_width_p = $bits(bit_cfg_o[width_lp-1:ch1_width_p]);
parameter cfg_node_data_width_p         = $bits(mode_cfg_o) + 3*$clog2(width_lp)+2;

//------------------------------------------------
//--------------- CFGTAG NODES -------------------
//------------------------------------------------

// Relay nodes before config nodes, one at the input terminal
// and one for each channel configuration
config_s [2:0] relay_out;
    
relay_node relay0(.config_i(config_i),
                  .config_o(relay_out[0]));

relay_node relay1(.config_i(relay_out[0]),
                  .config_o(relay_out[1]));

relay_node relay2(.config_i(relay_out[0]),
                  .config_o(relay_out[2]));


config_node#(.id_p(cfg_tag_base_id_p)     
            ,.data_bits_p(divider_node_data_width_p)
            ,.default_p('d0) 
            ) divider_node

            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_out[1])
            ,.data_o({cfg_reset,clk_divider_o})
            );

config_node#(.id_p(cfg_tag_base_id_p+1)     
            ,.data_bits_p(cfg_node_data_width_p)
            ,.default_p('d0) 
            ) cfg_node

            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_out[1])
            ,.data_o({fifo_en_o,loop_back_o,mode_cfg_o,
                      la_input_bit_selector_o,la_output_bit_selector_o,
                      v_output_bit_selector_o})
            );


config_node#(.id_p(cfg_tag_base_id_p+2)     
            ,.data_bits_p(ch1_bit_cfg_node_data_width_p)
            ,.default_p('d0) 
            ) ch1_bit_cfg_node

            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_out[2])
            ,.data_o(bit_cfg_o[ch1_width_p-1:0])
            );


config_node#(.id_p(cfg_tag_base_id_p+3)     
            ,.data_bits_p(ch2_bit_cfg_node_data_width_p)
            ,.default_p('d0) 
            ) ch2_bit_cfg_node

            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_out[2])
            ,.data_o(bit_cfg_o[width_lp-1:ch1_width_p])
            );

//------------------------------------------------
//--------------- RESET LOGIC --------------------
//------------------------------------------------

always_ff @(posedge clk)
  cfg_reset_r <= cfg_reset;

// reset is kept high until it is reset by the cfg node
// by changing reset value from 2'b01 to 2'b10, then
// it would remain low (unless another value is recieved)
always_ff @(posedge clk)
  if ((cfg_reset == 2'b10) & 
            ((cfg_reset_r == 2'b01)|(channel_reset_o == 1'b0)))
    channel_reset_o <= 1'b0;
  else
    channel_reset_o <= 1'b1;

endmodule
