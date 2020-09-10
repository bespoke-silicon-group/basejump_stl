// bsg_mesosync_link devides the chip's clock to a slower clock for IO 
// based on the configuration it receives. In the input side, for each 
// input data line it can choose between the clock edge and which cycle 
// in the divided clock to take the sameple, based on the bit_cfg configuration. 
//
// To find out the proper values for bit configuration, it has a logic
// analzers which would sample input singal on both positive and negative
// edges of the clock. Master chooses a line at a time and sends known
// patterns to it and reads the logic analyzer's data to find out the delays
// of each line and find the proper line configurations. 
// bsg_mesosync_input provides logic_analyzer data to be used in the
// bsg_mesosync_output module to send out these read values.
//
// There is no handshake protocl on the pin side, but from channel to core
// there is valid-only handshake to tell the FIFO which data is valid to be
// used. Moreover, it has a fifo-relay for both data and logic-analyzer data,
// so it can be connected to modules in distance on a chip.
//

//`ifndef DEFINITIONS_V
//`include "definitions.v"
//`endif

`include "bsg_defines.v"

module bsg_mesosync_input
                  #( parameter cfg_tag_base_id_p = "inv"
                   , parameter ch1_width_p       = "inv"
                   , parameter ch2_width_p       = "inv"
                   , parameter LA_els_p          = "inv"
                    
                   , parameter width_lp          = ch1_width_p + ch2_width_p
                   )
                   ( input                       clk
                   , input                       reset
                   , input  config_s             config_i
                   
               
                   // Sinals with their acknowledge
                   , input  [width_lp-1:0]       pins_i
 
                   , output logic [width_lp-1:0] data_o
                   , output logic                valid_o

                   // Logic analyzer signals for mesosync_output module
                   , output                      LA_data_o
                   , output                      LA_valid_o
                   , input                       ready_to_LA_i
                   );
                   
//------------------------------------------------
//------------ CONFIG TAG NODEs ------------------
//------------------------------------------------

// Configuratons
logic [1:0]                             cfg_reset, cfg_reset_r;
logic                                   channel_reset;
logic                                   enable;
logic                                   loopback_en; // not used
logic [maxDivisionWidth_p-1:0]          input_clk_divider;
bit_cfg_s [width_lp-1:0]                bit_cfg;
mode_cfg_s                              mode_cfg;
logic [`BSG_SAFE_CLOG2(width_lp)-1:0]   la_input_bit_selector;
logic                                   output_mode_is_LA;

// Calcuating data width of each configuration node
// reset (2 bits), clock divider for input digital clock, logic analyzer line selector
localparam input_node_data_width_p       = 2 + maxDivisionWidth_p 
                                             + `BSG_SAFE_CLOG2(width_lp);
// reset (2 bits), clock divider for output digital clock, 
// logic analyzer data and valid line selector
localparam common_node_data_width_p      = $bits(mode_cfg) + 1 + 1;
// bit configurations for input
localparam ch1_bit_cfg_node_data_width_p = $bits(bit_cfg[ch1_width_p-1:0]);
localparam ch2_bit_cfg_node_data_width_p = $bits(bit_cfg[width_lp-1:ch1_width_p]);

// relay nodes
config_s [1:0] relay_out;
relay_node input_relay_1(.config_i(config_i),
                         .config_o(relay_out[0]));

relay_node input_relay_2(.config_i(config_i),
                         .config_o(relay_out[1]));

assign output_mode_is_LA = (mode_cfg.output_mode == LA);

// Config nodes 
config_node#(.id_p(cfg_tag_base_id_p)     
            ,.data_bits_p(common_node_data_width_p)
            ,.default_p('d0) 
            ) common_node

            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_out[0])
            ,.data_o({mode_cfg,enable,loopback_en})
            );

config_node#(.id_p(cfg_tag_base_id_p+1)     
            ,.data_bits_p(input_node_data_width_p)
            ,.default_p('d0) 
            ) input_node

            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_out[0])
            ,.data_o({cfg_reset,input_clk_divider,la_input_bit_selector})
            );

config_node#(.id_p(cfg_tag_base_id_p+3)     
            ,.data_bits_p(ch1_bit_cfg_node_data_width_p)
            ,.default_p('d0) 
            ) ch1_bit_cfg_node

            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_out[1])
            ,.data_o(bit_cfg[ch1_width_p-1:0])
            );


config_node#(.id_p(cfg_tag_base_id_p+4)     
            ,.data_bits_p(ch2_bit_cfg_node_data_width_p)
            ,.default_p('d0) 
            ) ch2_bit_cfg_node

            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_out[1])
            ,.data_o(bit_cfg[width_lp-1:ch1_width_p])
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
            ((cfg_reset_r == 2'b01)|(channel_reset == 1'b0)))
    channel_reset <= 1'b0;
  else
    channel_reset <= 1'b1;

// Using a relay_fifo for enabling sending data through long distances in chip
logic [width_lp-1:0] data_o_r;
logic                valid_o_r;

//------------------------------------------------
//---------------- OUTPUT RELAY ------------------
//------------------------------------------------
// For connecting to far parts on the die, we need to 
// put a register before output 
always_ff @ (posedge clk)
  if (channel_reset) begin
    valid_o <= 0;
    data_o  <= 0;
  end else begin
    valid_o <= valid_o_r;
    data_o  <= data_o_r;
  end

//------------------------------------------------
//------------- CLOCK DIVIDER --------------------
//------------------------------------------------

logic [maxDivisionWidth_p-1:0] input_counter_r;

// clk is divided by the configured clk_divider_i plus one. So 0 
// means no clk division and 15 means clk division by factor of 16.

bsg_counter_dynamic_limit #(.width_p(maxDivisionWidth_p)) input_counter

            ( .clk_i(clk)
            , .reset_i(channel_reset)

            , .limit_i(input_clk_divider)
            , .counter_o(input_counter_r)
            );

//------------------------------------------------
//------------- INPUT SAMPLER --------------------
//------------------------------------------------

// Sampling on both edges of the clock for all input bits
// and also providing stabled version of them using synchronizers
logic [width_lp-1:0] posedge_value, negedge_value,
                    posedge_synchronized, negedge_synchronized;


bsg_ddr_sampler #(.width_p(width_lp)) ddr_sampler
    ( .clk(clk)
    , .reset(channel_reset)
    , .to_be_sampled_i(pins_i)
    
    , .pos_edge_value_o(posedge_value)
    , .neg_edge_value_o(negedge_value)
    , .pos_edge_synchronized_o(posedge_synchronized)
    , .neg_edge_synchronized_o(negedge_synchronized)
    );

//------------------------------------------------
//------------- INPUT MODULE ---------------------
//------------------------------------------------
// in normal mode, for each bit a clock edge and a clk cycle based on 
// required phase delay is selected, and this data is latched
integer i1,i2,i3,i4;
logic [width_lp-1:0] sampled_r;
logic [width_lp-1:0] phase_match;
logic [width_lp-1:0] selected_edge;

// Select the edge to take sample
always_comb
  for (i1 = 0; i1 < width_lp; i1 = i1 + 1)
    if (bit_cfg[i1].clk_edge_selector)
      selected_edge[i1] = posedge_value[i1];
    else
      selected_edge[i1] = negedge_value[i1];
   
// Signal which declares phase match, 
// that would be 1 only once in each input period
always_comb
  for (i2 = 0; i2 < width_lp; i2 = i2 + 1)
    if (input_counter_r == bit_cfg[i2].phase)
      phase_match[i2] = 1'b1; 
    else
      phase_match[i2] = 1'b0;

// Latching the value of line on the phase match cycle
// to be used in rest of the input period
always_ff @ (posedge clk) 
  if (channel_reset) 
    sampled_r  <= 0;
  else if (mode_cfg.input_mode == NORMAL) 
    for (i3 = 0; i3 < width_lp; i3 = i3 + 1) 
      if (phase_match[i3])
          sampled_r[i3] <= selected_edge[i3];

// When each line reaches its phase based on the input clk counter,
// its valid register would be set to 1, and it emains 1 until the 
// yumi signal becomes 1, which means the data were send out. It remains
// zero until it reaches desired phase again. In case of clk divider of 
// 0, which means no division, valid bit would always be one, since counter
// is always zero and all the phases must be zero.
logic [width_lp-1:0] valid_n,valid_r;
logic yumi_n,yumi_r;

// valid_n becomes 1 in case of phase match, otherwise it keeps valid_r 
// value unless it recives the registered yumi signal, 
// so it becomes zero the cycle after data is valid
assign valid_n = {width_lp{~channel_reset & (mode_cfg.input_mode == NORMAL)}}
                 & ((valid_r & ~{width_lp{yumi_r}}) | phase_match);

// Registering values
always_ff @ (posedge clk) 
  if (channel_reset) begin
    valid_r <= 0;
    yumi_r  <= 0;
  end 
  else begin
    valid_r <= valid_n;
    yumi_r  <= yumi_n;
  end

// bypassing register for the line(s) with latest phase
// Afterwards the registered values would be used
always_comb 
  for (i4 = 0; i4 < width_lp; i4 = i4 + 1)
    if (phase_match[i4] & yumi_n)
        data_o_r[i4] = selected_edge[i4];
      else 
        data_o_r[i4] = sampled_r[i4];

// when all the bits are valid, it means the data is ready
// yumi_r is sent back to each bit, so from next cycle valid bits 
// become zero and yumi_n goes to zero as well.
assign yumi_n    = &valid_n;
assign valid_o_r = yumi_n & enable;


//------------------------------------------------
//------------- LOGIC ANAYZER --------------------
//------------------------------------------------

// Using a bsg_relay_fifo to abosrb any latency on the line
logic LA_valid, ready_to_LA, LA_data;

bsg_relay_fifo #(.width_p(1)) LA_relay
    (.clk_i(clk)
    ,.reset_i(channel_reset)

    ,.ready_o(ready_to_LA)
    ,.data_i(LA_data)
    ,.v_i(LA_valid)

    ,.v_o(LA_valid_o)
    ,.data_o(LA_data_o)
    ,.ready_i(ready_to_LA_i)
    );

// Logic Analyzer signals
logic LA_trigger, LA_deque, delayed_input_clk_edge;  

// When logic analyzer is configured to sample, it has to start sampling 
// from the sample that correspinds to time when input_clock_counter is zero,
// beginning of IO clock. 
assign LA_trigger = (mode_cfg.input_mode == LA_STOP) & mode_cfg.LA_enque 
                  & delayed_input_clk_edge;  

// Synchronizer in ddr module that gives the input to logic anlzer has 2 cycle 
// delay and input_clk_counter is comapred with value 2 to get the actual edge. 
// If input_clk_divider is 0 every edge is correct, and if input_clk_divider is 1,
// when input_counter_r is zero is the actual edge. 
assign delayed_input_clk_edge =  (input_clk_divider<maxDivisionWidth_p'(2))  ? 
                                 (input_counter_r == maxDivisionWidth_p'(0)) :
                                 (input_counter_r == maxDivisionWidth_p'(2)) ;

// when data is ready to send from Logic Analyzer FIFO to output, fifo will 
// be dequed until it gets empty. 
// Due to output_ready signal which is reset dependent, this singal does not
// assert during reset.
assign LA_deque   = ready_to_LA & LA_valid;

// Due to fifo_relays in both mesosync_input and mesosync_output, we need
// 2 less elements in logic analyzer's fifo (each fifo_relay keeps 2 one bit
// values, hence we would get 2 two bit fifos in totall).

bsg_logic_analyzer #( .line_width_p(width_lp)
                    , .LA_els_p(LA_els_p)
                    ) logic_analyzer
       ( .clk(clk)
       , .reset(channel_reset)
       , .valid_en_i(output_mode_is_LA)
       , .posedge_value_i(posedge_synchronized)
       , .negedge_value_i(negedge_synchronized)
       , .input_bit_selector_i(la_input_bit_selector)
       
       , .start_i(LA_trigger)
       , .ready_o()
       
       , .logic_analyzer_data_o(LA_data)
       , .v_o(LA_valid)
       , .deque_i(LA_deque)

       );

endmodule
