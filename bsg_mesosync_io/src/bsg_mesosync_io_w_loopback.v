// This the mesosynchronous IO module with the loopback included 
// and ca perform all steps of calibration for mesosynchronous IO. 
// Used to verify the mesosynchronous IO.

//`ifndef DEFINITIONS_V
//`include "definitions.v"
//`endif

module bsg_mesosync_io_w_loopback
                  #(  parameter ch1_width_p       = -1
                    , parameter ch2_width_p       = -1
                    , parameter LA_els_p          = -1
                    , parameter cfg_tag_base_id_p = -1
                    , parameter loopback_els_p    = -1
                    , parameter credit_initial_p  = -1
                    , parameter credit_max_val_p  = -1
                    
                    , parameter width_lp = ch1_width_p + ch2_width_p
                   )
                   (  input                          clk
                    , input                          reset
                    
                    , input  config_s                config_i

                    // Sinals with their acknowledge
                    , input  [width_lp-1:0]          IO_i
                    , output logic [width_lp-1:0]    IO_o
                    );

// internal singals
clk_divider_s                clk_divider;
bit_cfg_s [width_lp-1:0]     bit_cfg;
mode_cfg_s                   mode_cfg;
logic [$clog2(width_lp)-1:0] input_bit_selector_ch1;
logic [$clog2(width_lp)-1:0] output_bit_selector_ch1;
logic [$clog2(width_lp)-1:0] input_bit_selector_ch2;
logic [$clog2(width_lp)-1:0] output_bit_selector_ch2;
logic                        en_loop_back;
logic                        channel_reset;
logic                        ready, valid;
logic [width_lp-1:0]         to_IO;
logic [width_lp-1:0]         to_loopback;
logic [width_lp-1:0]         from_loopback;
 
// Config tag extractor that extracts channel configurations from 
// congif tag serial input
bsg_mesosync_config_tag_extractor
           #(  .ch1_width_p(ch1_width_p)
             , .ch2_width_p(ch2_width_p)
             , .cfg_tag_base_id_p(cfg_tag_base_id_p)
            ) cnfg_tag_extractor
            (  .clk(clk)
             , .reset(reset)
             
             , .config_i(config_i)

             // Configuration output
             , .clk_divider_o(clk_divider)
             , .bit_cfg_o(bit_cfg)
             , .mode_cfg_o(mode_cfg)
             , .input_bit_selector_ch1_o(input_bit_selector_ch1)
             , .output_bit_selector_ch1_o(output_bit_selector_ch1)
             , .input_bit_selector_ch2_o(input_bit_selector_ch2)
             , .output_bit_selector_ch2_o(output_bit_selector_ch2)
             , .loop_back_o(en_loop_back)
             , .channel_reset_o(channel_reset)
             );
 
// Mesosynchronous channel
bsg_mesosync_channel 
           #(  .width_p(width_lp)
             , .LA_els_p(LA_els_p)
             ) mesosync_channel
            (  .clk(clk)
             , .reset(channel_reset)
             
             // Configuration inputs
             , .clk_divider_i(clk_divider)
             , .bit_cfg_i(bit_cfg)
             , .mode_cfg_i(mode_cfg)
             , .input_bit_selector_ch1_i(input_bit_selector_ch1)
             , .output_bit_selector_ch1_i(output_bit_selector_ch1)
             , .input_bit_selector_ch2_i(input_bit_selector_ch2)
             , .output_bit_selector_ch2_i(output_bit_selector_ch2)

        
             // Sinals with their acknowledge
             , .IO_i(IO_i)

             , .chip_o(to_loopback)
             , .valid_o(valid)
             
             , .chip_i(from_loopback)
             , .ready_o(ready)

             , .IO_o(to_IO)

             );

// loop back module with enable and ready inputs, and credit protocol
// on both directions
bsg_loopback_credit_protocol #( .width_p(width_lp-2)
                              , .els_p(loopback_els_p)
                              , .credit_initial_p(credit_initial_p)
                              , .credit_max_val_p(credit_max_val_p)
                              ) loopback
    ( .clk_i(clk)
    , .reset_i(reset)
    , .enable_i(en_loop_back)
    , .ready_i(ready)

    , .data_i(to_loopback[width_lp-1:2])
    , .v_i(valid & to_loopback[0])
    , .credit_o(from_loopback[1])

    , .v_o(from_loopback[0])
    , .data_o(from_loopback[width_lp-1:2])
    , .credit_i(valid & to_loopback[1])

    );


// mesosync channel uses the channel reset from config_tag
// hence during reset output of module must be made zero on 
// this top module
always_comb
  if (reset) begin
    IO_o = 0;
  end else begin 
    IO_o = to_IO;
  end

 endmodule
