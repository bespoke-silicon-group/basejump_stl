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
// mode is enabled and it sends out the input data to its output (this is done
// outside this module, it just asserts the enable signal). 
//
// There is no handshake protocl on the IO side, but from channel to chip 
// there is valid handshake to tell the FIFO which data is valid to be
// sampled. On the chip to channel connection, it has ready protocol, to let 
// the chip know when it can send data. 
//
`ifndef DEFINITIONS_V
`include "definitions.v"
`endif

module bsg_mesosync_channel
                  #(  parameter width_p = -1
                    , parameter LA_els_p = -1
                    )
                   (  input                          clk
                    , input                          reset
                    
                    // Configuration inputs
                    , input  clk_divider_s           clk_divider_i
                    , input  bit_cfg_s [width_p-1:0] bit_cfg_i
                    , input  mode_cfg_s              mode_cfg_i
                    , input  [$clog2(width_p)-1:0]   input_bit_selector_ch1_i
                    , input  [$clog2(width_p)-1:0]   output_bit_selector_ch1_i
                    , input  [$clog2(width_p)-1:0]   input_bit_selector_ch2_i
                    , input  [$clog2(width_p)-1:0]   output_bit_selector_ch2_i

               
                    // Sinals with their acknowledge
                    , input  [width_p-1:0]           IO_i

                    , output logic [width_p-1:0]     chip_o
                    , output logic                   valid_o
                    
                    , input  [width_p-1:0]           chip_i
                    , output logic                   ready_o

                    , output logic [width_p-1:0]     IO_o

                    );

// internal output_ready signals based on the output mode 
logic output_ready, ready_to_LA, ready_to_sync1, ready_to_sync2;

//------------------------------------------------
//------------- CLOCK DIVIDERS --------------------
//------------------------------------------------

logic [maxDivisionWidth-1:0] input_counter_r, output_counter_r;

// Each clk is divided by the configured clk_divider_i plus one. So 0 
// means no clk division and 15 means clk division by factor of 16.

// input clk divider counter
always_ff @ (posedge clk)
  if (reset)
    input_counter_r <= 0;
  else if (input_counter_r == clk_divider_i.input_clk_divider)
    input_counter_r <= 0;
  else
    input_counter_r <= input_counter_r+1;

// output clk divider counter
always_ff @ (posedge clk)
  if (reset)
    output_counter_r <= 0;
  else if (output_counter_r == clk_divider_i.output_clk_divider)
    output_counter_r <= 0;
  else
    output_counter_r <= output_counter_r+1;
 
                   
//------------------------------------------------
//------------- INPUT SAMPLER --------------------
//------------------------------------------------

// Sampling on both edges of the clock for all input bits
logic [width_p-1:0] posedge_value, negedge_value;

always_ff @ (posedge clk)
  posedge_value <= IO_i;

always_ff @ (negedge clk)
  negedge_value <= IO_i;

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
      selected_edge[i1] <= posedge_value[i1];
    else
      selected_edge[i1] <= negedge_value[i1];
   
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
  else if (mode_cfg_i.input_mode == NORMAL) 
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
assign valid_n = {width_p{~reset & (mode_cfg_i.input_mode == NORMAL)}}
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
    if (phase_match[i4]&yumi_n)
        chip_o[i4] <= selected_edge[i4];
      else 
        chip_o[i4] <= sampled_r[i4];

// when all the bits are valid, it means the data is ready
// yumi_r is sent back to each bit, so from next cycle valid bits 
// become zero and yumi_n goes to zero as well.
assign yumi_n  = &valid_n;
assign valid_o = yumi_n;


//------------------------------------------------
//------------- LOGIC ANAYZER --------------------
//------------------------------------------------

// Select one bit of input signal for Logic Analyzer
// LSB is posedge and MSB is negedge
logic [1:0] LA_selected_bit [2];
logic [1:0] LA_valid, LA_data, LA_deque;
logic LA_enque;

assign LA_selected_bit[0][0] = posedge_value[input_bit_selector_ch1_i];
assign LA_selected_bit[0][1] = negedge_value[input_bit_selector_ch1_i];
assign LA_selected_bit[1][0] = posedge_value[input_bit_selector_ch2_i];
assign LA_selected_bit[1][1] = negedge_value[input_bit_selector_ch2_i];
assign LA_enque = (mode_cfg_i.input_mode == LA_STOP) & mode_cfg_i.LA_enque;

// when data is ready to send from Logic Analyzer FIFO to output, fifo will 
// be dequed until it gets empty. 
// Due to output_ready signal which is reset dependent, this singal does not
// assert during reset.
assign LA_deque[0] = ready_to_LA & LA_valid[0];
assign LA_deque[1] = ready_to_LA & LA_valid[1];

// two logic analyzers
bsg_logic_analyzer 
                  #(.LA_els_p(LA_els_p)
                  ) logic_analyzer_0
                   ( .clk(clk)
                    ,.reset(reset)
                   
                    ,.data_i(LA_selected_bit[0])
                    ,.enque_i(LA_enque)
                    ,.deque_i(LA_deque[0])
                    
                    ,.data_o(LA_data[0])
                    ,.valid_o(LA_valid[0])
                    );


bsg_logic_analyzer 
                  #(.LA_els_p(LA_els_p)
                  ) logic_analyzer_1
                   ( .clk(clk)
                    ,.reset(reset)
                   
                    ,.data_i(LA_selected_bit[1])
                    ,.enque_i(LA_enque)
                    ,.deque_i(LA_deque[1])
                    
                    ,.data_o(LA_data[1])
                    ,.valid_o(LA_valid[1])
                    );

// Demux that merges 1 bit outputs of Logic Analyzers 
logic [width_p-1:0] output_demux;
assign output_demux = (LA_valid[0]&LA_valid[1]) ? 
                      ((LA_data[1] << output_bit_selector_ch2_i)|(LA_data[0] << output_bit_selector_ch1_i))
                      : 0;

//------------------------------------------------
//------------- OUTPUT MODULE --------------------
//------------------------------------------------

localparam counter_min_bits_lp = 24;
localparam counter_bits_lp     = `BSG_MAX(counter_min_bits_lp,(width_p+1)*2+1);

// internal signal for channel output
logic [width_p-1:0] output_data;

// counter for sync2 output mode
logic [counter_bits_lp-1:0] out_ctr_r, out_ctr_n;

// shift register for sending out the pattern in sync1 output mode
logic [7:0]          out_rot_r,   out_rot_n;

// Counter and shift register
always_ff @(posedge clk)
  begin
    if (reset)
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

// fill pattern with at least as many 10's to fill out_cntr_width_lp bits
// having defaults be 10101 reduces electromigration on pads
wire [(((width_p+1)>>1)<<1)-1:0] inactive_pattern
                                 = { ((width_p+1) >> 1) { (2'b10) } };

// determning output based on output mode configuration
always_comb
  begin
     out_ctr_n = out_ctr_r;
     out_rot_n = out_rot_r;
     output_data = 0;

     unique case (mode_cfg_i.output_mode)
       STOP:
         begin
         end

       PAT:
         begin
            output_data = {inactive_pattern[0+:width_p] };
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
           output_data = chip_i;
         end

       default:
         begin
         end
     endcase
  end

// each time outputcounter is about to over flow on clock edge, data 
// would be sent out on the clock edge as well
always_ff @ (posedge clk)
  if (reset) begin
    IO_o <= 0;
  end else if (output_counter_r == clk_divider_i.output_clk_divider) begin
    IO_o <= output_data;
  end else begin
    // IO_o keeps its value
    IO_o <= IO_o; 
  end
  
assign output_ready = (output_counter_r == clk_divider_i.output_clk_divider) & ~reset ;

// ready signals based on the output mode 
// There is no need for awknowledge of ready in STOP and PATTERN modes
assign ready_o        = output_ready & (mode_cfg_i.output_mode == NORM);
assign ready_to_LA    = output_ready & (mode_cfg_i.output_mode == LA);
assign ready_to_sync1 = output_ready & (mode_cfg_i.output_mode == SYNC1);
assign ready_to_sync2 = output_ready & (mode_cfg_i.output_mode == SYNC2);

endmodule
