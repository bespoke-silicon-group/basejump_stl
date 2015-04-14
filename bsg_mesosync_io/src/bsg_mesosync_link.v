// bsg_mesosync_channel is the designed IO in bsg group that devides
// the chip's clock to a slower clock for IO based on the configuration 
// it receives. For each input data line it can choose between the clock
// edge and which cycle in the divided clock to take the sameple, based on
// the bit_cfg_i configuration. 
//
// It has four phases to be calibrated. After reset, it would send out a 
// known pattern so the other side (master) can bit-allign its input. Next 
// it would send all possible transitions of data using two counters to make 
// sure the output channel is reliable.
//
// To find out the proper values for bit configuration, it has 2 logic
// analzers which would sample input singal on both positive and negative
// edges of the clock. Master chooses two lines at a time and sends known
// patterns to them and read the logic analyzer's data to find out the delays
// of each line and find the proper line configurations. Finally, a loopback
// mode is enabled and it sends out the input data to its output. 
//
// There is no handshake protocl on the pins side, but from channel to chip 
// there is valid handshake to tell the FIFO which data is valid to be
// sampled. On the chip to channel connection, it has ready protocol, to let 
// the chip know when it can send data. 
//
// Most important feature of this IO is least latency.

//`ifndef DEFINITIONS_V
//`include "definitions.v"
//`endif

module bsg_mesosync_link
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

                    // Signals with their acknowledge
                    , input  [width_lp-1:0]          pins_i
                    , output logic [width_lp-1:0]    pins_o
                    
                    // connection to chip, 2 bits are used for handshake
                    , input  [width_lp-3:0]          chip_data_i
                    , input                          chip_v_i
                    , output logic                   chip_ready_o

                    , output                         chip_v_o
                    , output [width_lp-3:0]          chip_data_o
                    , input                          chip_yumi_i
     
                    );

// internal singals
clk_divider_s                clk_divider;
bit_cfg_s [width_lp-1:0]     bit_cfg;
mode_cfg_s                   mode_cfg;
logic [$clog2(width_lp)-1:0] la_intput_bit_selector;
logic [$clog2(width_lp)-1:0] la_output_bit_selector;
logic [$clog2(width_lp)-1:0] v_output_bit_selector;
logic                        en_loop_back,fifo_en;
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
             , .la_input_bit_selector_o(la_intput_bit_selector)
             , .la_output_bit_selector_o(la_output_bit_selector)
             , .v_output_bit_selector_o(v_output_bit_selector)
             , .fifo_en_o(fifo_en)
             , .loop_back_o(en_loop_back)
             , .channel_reset_o(channel_reset)
             );
 
// Mesosynchronous channel
bsg_mesosync_link_barebones
           #(  .width_p(width_lp)
             , .LA_els_p(LA_els_p)
             ) mesosync_channel
            (  .clk(clk)
             , .reset(channel_reset)
             
             // Configuration inputs
             , .clk_divider_i(clk_divider)
             , .bit_cfg_i(bit_cfg)
             , .mode_cfg_i(mode_cfg)
             , .la_input_bit_selector_i(la_intput_bit_selector)
             , .la_output_bit_selector_i(la_output_bit_selector)
             , .v_output_bit_selector_i(v_output_bit_selector)

        
             // Sinals with their acknowledge
             , .pins_i(pins_i)

             , .chip_o(to_loopback)
             , .valid_o(valid)
             
             , .chip_i(from_loopback)
             , .ready_o(ready)

             , .pins_o(to_IO)

             );

// loop back module with enable and ready inputs, and credit protocol
// on both directions
bsg_credit_resolver_w_loopback #( .width_p(width_lp-2)
                                , .els_p(loopback_els_p)
                                , .credit_initial_p(credit_initial_p)
                                , .credit_max_val_p(credit_max_val_p)
                                ) loopback
    ( .clk_i(clk)
    , .reset_i(reset)
    , .enable_i(fifo_en & ~channel_reset)
    , .loopback_en_i(en_loop_back)
    , .line_ready_i(ready)

    // Connection to mesosync_link
    , .pins_data_i(to_loopback[width_lp-1:2])
    , .pins_v_i(valid & to_loopback[0])
    , .pins_credit_o(from_loopback[1])

    , .pins_v_o(from_loopback[0])
    , .pins_data_o(from_loopback[width_lp-1:2])
    , .pins_credit_i(valid & to_loopback[1])
    
    // connection to chip
    , .chip_data_i(chip_data_i)
    , .chip_v_i(chip_v_i)
    , .chip_ready_o(chip_ready_o)

    , .chip_v_o(chip_v_o)
    , .chip_data_o(chip_data_o)
    , .chip_yumi_i(chip_yumi_i)
  
    );


// mesosync channel uses the channel reset from config_tag
// hence during reset output of module must be made zero on 
// this top module
always_comb
  if (reset) begin
    pins_o = 0;
  end else begin 
    pins_o = to_IO;
  end

endmodule
