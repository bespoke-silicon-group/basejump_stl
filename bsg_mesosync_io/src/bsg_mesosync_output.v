// bsg_mesosync_link devides the chip's clock to a slower clock for IO 
// based on the configuration it receives. 
//
// bsg_mesosync_output module has three phases to be calibrated. After reset, 
// it would send out a known pattern so the other side (master) can bit-allign 
// its input. Next it would send all possible transitions of data using two 
// counters to make sure the output channel is reliable.
//
// To find out the proper values for bit configuration, it sends outputs of 
// the logic analzer received from the bsg_mesosync_input module. 
//
// On the pins side there is no handshake protocol and on the other side, 
// to rest of bsg_mesosync_link, it has ready-only protocol, which declares
// when it has sent a data. 
//
// It also provides the loopback mode, received from config_tag, since the 
// loopback module must be placed very close to it.
//

//`ifndef DEFINITIONS_V
//`include "definitions.v"
//`endif

`include "bsg_defines.v"

module bsg_mesosync_output
                  #( parameter width_p           = "inv"
                   , parameter cfg_tag_base_id_p = "inv"
                   )
                   ( input                      clk
                   , input                      reset
                   , input  config_s            config_i
                    
                   // Sinals with their acknowledge
                   , input  [width_p-1:0]       data_i
                   , output logic               ready_o

                   , output logic [width_p-1:0] pins_o
                   
                   // Logic analyzer signals for mesosync_input module
                   , input                      LA_data_i
                   , input                      LA_valid_i
                   , output                     ready_to_LA_o
                   
                   // loopback mode signal for loopback module
                   , output logic               loopback_en_o
                   , output logic               channel_reset_o
                   );

//------------------------------------------------
//------------ CONFIG TAG NODEs ------------------
//------------------------------------------------

// Configuratons
logic [1:0]                          cfg_reset, cfg_reset_r;
logic                                input_enable; // not used
mode_cfg_s                           mode_cfg;
logic [maxDivisionWidth_p-1:0]       output_clk_divider;
logic [`BSG_SAFE_CLOG2(width_p)-1:0] la_output_bit_selector;
logic [`BSG_SAFE_CLOG2(width_p)-1:0] v_output_bit_selector;

// Calcuating data width of each configuration node

// For $clog2, width_lp is a number 
localparam width_lp = width_p + 0;

// reset (2 bits), clock divider for output digital clock, 
// logic analyzer data and valid line selector
localparam output_node_data_width_p = 2 + maxDivisionWidth_p 
                                        + 2*(`BSG_SAFE_CLOG2(width_lp));
// mode_cfg, input_enable and loopback_en
localparam common_node_data_width_p = $bits(mode_cfg) + 1 + 1;

// relay nodes
config_s relay_out;

relay_node input_relay_1(.config_i(config_i),
                         .config_o(relay_out));

// Config nodes 
config_node#(.id_p(cfg_tag_base_id_p)     
            ,.data_bits_p(common_node_data_width_p)
            ,.default_p('d0) 
            ) common_node

            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_out)
            ,.data_o({mode_cfg,input_enable,loopback_en_o})
            );

config_node#(.id_p(cfg_tag_base_id_p+2)     
            ,.data_bits_p(output_node_data_width_p)
            ,.default_p('d0) 
            ) output_node

            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_out)
            ,.data_o({cfg_reset,output_clk_divider,la_output_bit_selector,
                      v_output_bit_selector})
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

//------------------------------------------------
//--------- RELAY FIFO FOR LA DATA ---------------
//------------------------------------------------

// Using a bsg_relay_fifo to abosrb any latency on the line
logic LA_valid, ready_to_LA, LA_data;

bsg_relay_fifo #(.width_p(1)) LA_relay
    (.clk_i(clk)
    ,.reset_i(channel_reset_o)

    ,.ready_o(ready_to_LA_o)
    ,.data_i(LA_data_i)
    ,.v_i(LA_valid_i)

    ,.v_o(LA_valid)
    ,.data_o(LA_data)
    ,.ready_i(ready_to_LA)
    );

//------------------------------------------------
//------------- CLOCK DIVIDERS --------------------
//------------------------------------------------

logic [maxDivisionWidth_p-1:0] input_counter_r, output_counter_r;

// clk is divided by the configured outpt_clk_divider_i plus one. So 0 
// means no clk division and 15 means clk division by factor of 16.
bsg_counter_dynamic_limit #(.width_p(maxDivisionWidth_p)) output_counter

            ( .clk_i(clk)
            , .reset_i(channel_reset_o)

            , .limit_i(output_clk_divider)
            , .counter_o(output_counter_r)
            );

//------------------------------------------------
//------------- OUTPUT MODULE --------------------
//------------------------------------------------

localparam counter_bits_lp = (width_p+1)*2+1;

// internal signal for channel output
logic [width_p-1:0] output_data;

// internal output_ready signals based on the output mode 
logic output_ready, ready_to_sync1, ready_to_sync2;

// counter for sync2 output mode
logic [counter_bits_lp-1:0] out_ctr_r, out_ctr_n;

// shift register for sending out the pattern in sync1 output mode
logic [7:0]          out_rot_r,   out_rot_n;

// Counter and shift register
always_ff @(posedge clk)
  begin
    if (channel_reset_o)
      begin
        out_ctr_r <= counter_bits_lp ' (0);
        out_rot_r <= 8'b1010_0101;   // bit alignment sequence
      end
    else
      begin
        if (ready_to_sync1)
          out_rot_r <= out_rot_n;
        if (ready_to_sync2)
          out_ctr_r <= out_ctr_n;
      end
  end

wire [counter_bits_lp-1:0] out_ctr_r_p1 = out_ctr_r + 1'b1;

// fill pattern with at least as many 10's to fill out_cntr_width_p bits
// having defaults be 10101 reduces electromigration on pads
localparam inactive_pattern_p = {((width_p+1)>>1) {2'b01}};

// Demux that merges 1 bit outputs of Logic Analyzer and its valid signal
logic [width_p-1:0] output_demux;
assign output_demux = (LA_valid << v_output_bit_selector)
                     |(LA_data  << la_output_bit_selector);

// determning output based on output mode configuration
always_comb
  begin
     out_ctr_n = out_ctr_r;
     out_rot_n = out_rot_r;
     output_data = 0;

     unique case (mode_cfg.output_mode)
       STOP:
         begin
         end

       PAT:
         begin
            output_data = {inactive_pattern_p[0+:width_p] };
         end
       SYNC1:
         begin
            out_rot_n   = { out_rot_r[6:0], out_rot_r[7] };
            output_data = { (width_p) { out_rot_r[7] } };
         end
       SYNC2:
         begin
            out_ctr_n   = out_ctr_r_p1;
            // we do fast bits then slow bits
            output_data =   out_ctr_r[0]
                            ? out_ctr_r[(1+(width_p))+:(width_p)]
                            : out_ctr_r[1+:(width_p)];
         end
       LA:
         begin
           output_data = output_demux; 
         end
       NORM:
         begin
           // Sending inactive pattern as data for non valid data
           output_data[0] = data_i[0]; // valid
           output_data[1] = data_i[1]; // token
           output_data[width_p-1:2] = data_i[0] ? data_i [width_p-1:2] 
                                                : inactive_pattern_p[0+:width_p-2];
         end

       default:
         begin
         end
     endcase
  end

// each time outputcounter is about to over flow on clock edge, data 
// would be sent out on the clock edge as well
always_ff @ (posedge clk)
  if (channel_reset_o) begin
    pins_o <= 0;
  end else if (output_counter_r == output_clk_divider) begin
    pins_o <= output_data;
  end else begin
    // pins_o keeps its value
    pins_o <= pins_o; 
  end
  
assign output_ready = (output_counter_r == output_clk_divider) & ~channel_reset_o;

// ready signals based on the output mode 
// There is no need for awknowledge of ready in STOP and PATTERN modes
assign ready_o        = output_ready & (mode_cfg.output_mode == NORM);
assign ready_to_LA    = output_ready & (mode_cfg.output_mode == LA);
assign ready_to_sync1 = output_ready & (mode_cfg.output_mode == SYNC1);
assign ready_to_sync2 = output_ready & (mode_cfg.output_mode == SYNC2);

endmodule
