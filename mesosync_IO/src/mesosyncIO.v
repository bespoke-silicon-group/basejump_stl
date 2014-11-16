`include "definitions.v"

module mesosyncIO #(parameter bit_num_p = 5,
                    parameter log_LA_fifo_depth_p = 9
                   )
                   (input clk,
                    input reset,
                    
                    input clk_divider_s clk_divider_i,
                    input mode_cfg_s mode_cfg_i,
                    input [$clog2(bit_num_p)-1:0] input_bit_selector_i,
                    input [$clog2(bit_num_p)-1:0] output_bit_selector_i,
                    input bit_cfg_s [bit_num_p-1:0] bit_cfg_i,

                    input  [bit_num_p-1:0] IO_i,
                    output logic [bit_num_p-1:0] IO_o,

                    input  [bit_num_p-1:0] chip_i,
                    output logic [bit_num_p-1:0] chip_o,
                    output valid_o,
                    output data_sent_o
                   );

//------------------------------------------------
//------------- CLOCK DIVIDERS --------------------
//------------------------------------------------

logic [maxDivisionWidth-1:0] input_counter_r, output_counter_r;

// Each clk is divided by the configured clk_divider plus one. So 0 
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
logic [bit_num_p-1:0] posedge_value, negedge_value;

always_ff @ (posedge clk)
  posedge_value <= IO_i;

always_ff @ (negedge clk)
  negedge_value <= IO_i;

//------------------------------------------------
//------------- INPUT MODULE ---------------------
//------------------------------------------------
integer i;
logic [bit_num_p-1:0] valid_r;
logic yumi;
// in normal mode, for each bit a clock edge and a clk cycle based on 
// required phase delay is selected, and this data is sent out
// when each line reaches its phase based on the input clk counter,
// its valid register would be set to 1, and it emains 1 until the 
// yumi signal becomes 1, which means the data were send out. It remains
// zero until it reaches desired phase again. In case of clk divider of 
// 0, which means no division, valid bit would always be one, since counter
// is always zero and all the phases must be zero.
always_ff @ (posedge clk) 
  if (reset) begin
    chip_o  <= 0;
    valid_r <= 0;
  end
  else if (mode_cfg_i.input_mode) 
    for (i=0; i<bit_num_p; i=i+1) begin
      if (input_counter_r == bit_cfg_i[i].phase)begin
        valid_r[i] <= 1'b1;
        if (bit_cfg_i[i].clk_edge_selector)
          chip_o[i] <= posedge_value [i];
        else
          chip_o[i] <= negedge_value [i];
      end
      else 
        valid_r[i] <= valid_r[i] & (~yumi);
    end
  // Valid is always zero when module is in calibration mode
  else 
    valid_r <= '0;

// when all the bits are valid, it means the data is stored on chip_o 
// register, since valid_r is a FF as well. So output is valid, and also
// yumi is sent back to each bit. From next cycle valid bits become zero
// and yumi bit goes to zero as well.
assign yumi    = &valid_r;
assign valid_o = yumi;

//------------------------------------------------
//------------- LOGIC ANAYZER --------------------
//------------------------------------------------

// Select one bit of input signal for Logic Analyzer
// LSB is posedge and MSB is negedge
logic [1:0] LA_selected_bit;
assign LA_selected_bit[0] = posedge_value [input_bit_selector_i];
assign LA_selected_bit[1] = negedge_value [input_bit_selector_i];

// Synchronizer for samples from both edges
logic [1:0] synchronizer_out;
always_ff @  (posedge clk)
  synchronizer_out <= LA_selected_bit;

// Logic Analyzer input selector, between config tag data 
// or input signal samples
logic [1:0] LA_fifo_data;
assign LA_fifo_data = mode_cfg_i.LA_input_selector ? 
                      synchronizer_out : mode_cfg_i.LA_input_data; 

// Logic Analyzer FIFO
logic LA_enque, LA_deque, LA_fifo_empty, LA_fifo_full,
      LA_fifo_almost_full, LA_fifo_valid;

logic LA_fifo_out;

two_in_one_out_fifo #(.LG_DEPTH(log_LA_fifo_depth_p), .ALMOST_DIST(2))
LA_fifo
(
	.clk(clk),
	.din(LA_fifo_data),
	.enque(LA_enque), 
	.deque(LA_deque),	
	.clear(reset),
	.dout(LA_fifo_out),
	.empty(LA_fifo_empty),
	.full(LA_fifo_full),
  .almost_full(LA_fifo_almost_full),
	.valid(LA_fifo_valid)
);

// Toglle of enque bit is used for inserting data to Logic Analyzer from
// configtag, hence a history bit is kept
logic cfg_LA_enque_r;
always_ff @ (posedge clk)
  if (reset)
    cfg_LA_enque_r <= 1'b0;
  else
    cfg_LA_enque_r <= mode_cfg_i.LA_enque;

// In calibration mode, Logic Analyzer FIFO is enqueued. in ONCE mode, data
// comes from config tag and enque bit of config tag is checked to be toggled.
// in AUTO mode, each cycle two samples are inserted to FIFO until it is full.
assign LA_enque = (~reset)&(mode_cfg_i.input_mode == 0)&
                  (~(LA_fifo_almost_full|LA_fifo_full))&
    (((mode_cfg_i.LA_enque_mode == ONCE)&(mode_cfg_i.LA_enque != cfg_LA_enque_r))
    |((mode_cfg_i.LA_enque_mode == AUTO)&(mode_cfg_i.LA_enque == 1'b1)));

// when data is sent from Logic Analyzer FIFO to output, fifo will be dequed 
// until it gets empty. data sent signal shows that one bit is sent out.
// Due to data_sent_o signal which is reset dependent, this singal does not
// assert during reset.
assign LA_deque = (mode_cfg_i.output_mode == CALIB) & data_sent_o & (~LA_fifo_empty);

//------------------------------------------------
//------------- OUTPUT SELECTOR ------------------
//------------------------------------------------

// Demux for output from 1 bit data of Logic Analyzer FIFO. 
logic [bit_num_p-1:0] output_demux;
assign output_demux = LA_fifo_valid ? 
                      (LA_fifo_out << output_bit_selector_i) : 0;

// Based on output mode, output data is selected from chip or logic Analyzer FIFO 
logic [bit_num_p-1:0] output_data;
// 01 is for LA_fifo data and 10 is for chip data 
assign output_data = (mode_cfg_i.output_mode == NORM) ? chip_i : output_demux; 

//------------------------------------------------
//------------- OUTPUT MODULE --------------------
//------------------------------------------------

// If output mode is sending data, each time output counter overflows
// a data has been sent out
assign data_sent_o = (output_counter_r ==0) & (~reset) & 
                     (((mode_cfg_i.output_mode == CALIB) & (~LA_fifo_empty)) 
                      |(mode_cfg_i.output_mode == NORM));

// each time outputcounter is about to over flow on clock edge, data 
// would be sent out on the clock edge as well
always_ff @ (posedge clk)
if (reset)
  IO_o <= 0;
else if ((mode_cfg_i.output_mode != STOP)&(output_counter_r == clk_divider_i.output_clk_divider))
  IO_o <= output_data;

endmodule
