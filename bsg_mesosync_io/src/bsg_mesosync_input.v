// bsg_mesosync_channel is the designed IO in bsg group that devides
// the chip's clock to a slower clock for IO based on the configuration 
// it receives. In the input side, for each input data line it can 
// choose between the clock edge and which cycle in the divided clock 
// to take the sameple, based on the bit_cfg_i configuration. 
//
// To find out the proper values for bit configuration, it has 2 logic
// analzers which would sample input singal on both positive and negative
// edges of the clock. Master chooses two lines at a time and sends known
// patterns to them and read the logic analyzer's data to find out the delays
// of each line and find the proper line configurations. 
//
// It also provides Logic_analyzer outputs which are used in the
// bsg_mesosync_output module to send out the read values.
//
// There is no handshake protocl on the pin side, but from channel to chip 
// there is valid handshake to tell the FIFO which data is valid to be
// sampled. 
//

//`ifndef DEFINITIONS_V
//`include "definitions.v"
//`endif

module bsg_mesosync_input
                  #( parameter width_p  = -1
                   , parameter LA_els_p = -1
                   )
                   ( input                          clk
                   , input                          reset
                   
               
                   // Sinals with their acknowledge
                   , input  [width_p-1:0]           pins_i

                   , output logic [width_p-1:0]     chip_o
                   , output logic                   valid_o
                   
                   // Logic analyzer signals for mesosync_output module
                   , output                         logic_analyzer_data_o
                   , output                         LA_valid_o
                   , input                          ready_to_LA_i

                   // Configuration inputs
                   , input  [maxDivisionWidth-1:0]  input_clk_divider_i
                   , input  bit_cfg_s [width_p-1:0] bit_cfg_i
                   , input  input_mode_e            input_mode_i
                   , input                          LA_enque_i
                   , input  [$clog2(width_p)-1:0]   la_input_bit_selector_i

                   );

//------------------------------------------------
//------------- CLOCK DIVIDER --------------------
//------------------------------------------------

logic [maxDivisionWidth-1:0] input_counter_r;

// clk is divided by the configured clk_divider_i plus one. So 0 
// means no clk division and 15 means clk division by factor of 16.

counter_w_overflow #(.width_p(maxDivisionWidth)) input_counter

            ( .clk(clk)
            , .reset(reset)

            , .overflow_i(input_clk_divider_i)
            , .counter_o(input_counter_r)
            );

//------------------------------------------------
//------------- INPUT SAMPLER --------------------
//------------------------------------------------

// Sampling on both edges of the clock for all input bits
// and also providing stabled version of them using synchronizers
logic [width_p-1:0] posedge_value, negedge_value,
                    posedge_synchronized, negedge_synchronized;


bsg_ddr_sampler #(.width_p(width_p)) ddr_sampler
    ( .clk(clk)
    , .reset(reset)
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
logic [width_p-1:0] sampled_r;
logic [width_p-1:0] phase_match;
logic [width_p-1:0] selected_edge;

// Select the edge to take sample
always_comb
  for (i1 = 0; i1 < width_p; i1 = i1 + 1)
    if (bit_cfg_i[i1].clk_edge_selector)
      selected_edge[i1] = posedge_value[i1];
    else
      selected_edge[i1] = negedge_value[i1];
   
// Signal which declares phase match, 
// that would be 1 only once in each input period
always_comb
  for (i2 = 0; i2 < width_p; i2 = i2 + 1)
    if (input_counter_r == bit_cfg_i[i2].phase)
      phase_match[i2] = 1'b1; 
    else
      phase_match[i2] = 1'b0;

// Latching the value of line on the phase match cycle
// to be used in rest of the input period
always_ff @ (posedge clk) 
  if (reset) 
    sampled_r  <= 0;
  else if (input_mode_i == NORMAL) 
    for (i3 = 0; i3 < width_p; i3 = i3 + 1) 
      if (phase_match[i3])
          sampled_r[i3] <= selected_edge[i3];

// When each line reaches its phase based on the input clk counter,
// its valid register would be set to 1, and it emains 1 until the 
// yumi signal becomes 1, which means the data were send out. It remains
// zero until it reaches desired phase again. In case of clk divider of 
// 0, which means no division, valid bit would always be one, since counter
// is always zero and all the phases must be zero.
logic [width_p-1:0] valid_n,valid_r;
logic yumi_n,yumi_r;

// valid_n becomes 1 in case of phase match, otherwise it keeps valid_r 
// value unless it recives the registered yumi signal, 
// so it becomes zero the cycle after data is valid
assign valid_n = {width_p{~reset & (input_mode_i == NORMAL)}}
                 & ((valid_r & ~{width_p{yumi_r}}) | phase_match);

// Registering values
always_ff @ (posedge clk) 
  if (reset) begin
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
  for (i4 = 0; i4 < width_p; i4 = i4 + 1)
    if (phase_match[i4] & yumi_n)
        chip_o[i4] = selected_edge[i4];
      else 
        chip_o[i4] = sampled_r[i4];

// when all the bits are valid, it means the data is ready
// yumi_r is sent back to each bit, so from next cycle valid bits 
// become zero and yumi_n goes to zero as well.
assign yumi_n  = &valid_n;
assign valid_o = yumi_n;


//------------------------------------------------
//------------- LOGIC ANAYZER --------------------
//------------------------------------------------

// Logic Analyzer signals
logic LA_trigger, LA_deque;

// When logic analyzer is configured to sample, it has to start sampling 
// from the sample that correspinds to time when input_clock_counter is zero,
// beginning of IO clock. However, due to synchronizer in ddr module that
// gives the input to logic anlzer, it has 2 cycle delay and input_clk_counter
// is comapred with value 2.
assign LA_trigger = (input_mode_i == LA_STOP) & LA_enque_i 
                  & (input_counter_r == {{(maxDivisionWidth-2){1'b0}},2'b10});

// when data is ready to send from Logic Analyzer FIFO to output, fifo will 
// be dequed until it gets empty. 
// Due to output_ready signal which is reset dependent, this singal does not
// assert during reset.
assign LA_deque   = ready_to_LA_i & LA_valid_o;

bsg_logic_analyzer #( .line_width_p(width_p)
                    , .LA_els_p(LA_els_p)
                    ) logic_analyzer
       ( .clk(clk)
       , .reset(reset)

       , .posedge_value_i(posedge_synchronized)
       , .negedge_value_i(negedge_synchronized)
       , .input_bit_selector_i(la_input_bit_selector_i)
       
       , .start_i(LA_trigger)
       , .ready_o()
       
       , .logic_analyzer_data_o(logic_analyzer_data_o)
       , .v_o(LA_valid_o)
       , .deque_i(LA_deque)

       );
endmodule
