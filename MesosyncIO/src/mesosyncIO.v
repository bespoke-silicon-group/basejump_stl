`include "definitions.v"

module mesosyncIO #(parameter bit_num = 5
                   )
                   (input clk,
                    input reset,
                    
                    input configuration cfgtag,

                    input  [bit_num-1:0] IO_i,
                    output logic [bit_num-1:0] IO_o,

                    input  [bit_num-1:0] chip_i,
                    output logic [bit_num-1:0] chip_o,
                    output data_sent_o
                   );

//------------------------------------------------
//------------- CLOCK DIVIDERS --------------------
//------------------------------------------------

// input clk divider counter
logic [maxDivisionWidth-1:0] input_counter_n, input_counter_r;

always_comb begin
  input_counter_n = input_counter_r + 1;
  if (input_counter_n == cfgtag.input_clk_divider)
    input_counter_n = 0;
end

always_ff @ (posedge clk)
  if (reset)
    input_counter_r <= 0;
  else
    input_counter_r <= input_counter_n;

logic [maxDivisionWidth-1:0] output_counter_n, output_counter_r;

// output clk divider counter
always_comb begin
  output_counter_n = output_counter_r + 1;
  if (output_counter_n == cfgtag.output_clk_divider)
    output_counter_n = 0;
end

always_ff @ (posedge clk)
  if (reset)
    output_counter_r <= 0;
  else
    output_counter_r <= output_counter_n;
                    
//------------------------------------------------
//------------- INPUT SAMPLER --------------------
//------------------------------------------------

// Sampling on both edges of the clock for all input bits
logic [bit_num-1:0] posedge_value, negedge_value;

always_ff @ (posedge clk)
  posedge_value <= IO_i;

always_ff @ (negedge clk)
  negedge_value <= IO_i;


//------------------------------------------------
//------------- INPUT MODULE ---------------------
//------------------------------------------------
integer i;
// in normal mode, for each bit a clock edge and a clk cycle based on 
// required phase delay is selected, and this data is sent out
always_ff @ (posedge clk) 
if (reset)
  chip_o <= 0;
else if (cfgtag.input_mode) 
  for (i=0; i<bit_num; i=i+1) begin
    if (input_counter_r == cfgtag.phase[i])
      if (cfgtag.clk_edge_selector)
        chip_o[i] <= posedge_value [i];
      else
        chip_o[i] <= negedge_value [i];
  end


//------------------------------------------------
//------------- LOGIC ANAYZER --------------------
//------------------------------------------------

// Select one bit of input signal for Logic Analyzer
// LSB is posedge and MSB is negedge
logic [1:0] LA_selected_bit;
assign LA_selected_bit[0] = posedge_value [cfgtag.input_bit_selector];
assign LA_selected_bit[1] = negedge_value [cfgtag.input_bit_selector];

// Synchronizer for samples from both edges
logic [1:0] synchronizer_out;
always_ff @  (posedge clk)
  synchronizer_out <= LA_selected_bit;

// Logic Analyzer input selector, between config tag data 
// or input signal samples
logic [1:0] LA_fifo_data;
assign LA_fifo_data = cfgtag.LA_input_selector ? 
                      synchronizer_out : cfgtag.LA_input_data;

// Logic Analyzer FIFO
logic LA_enque, LA_deque, LA_fifo_empty, LA_fifo_full,
      LA_fifo_almost_full, LA_fifo_valid;

logic LA_fifo_out;

two_in_one_out_fifo #(.LG_DEPTH(log_LA_fifo_depth), .ALMOST_DIST(2))
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
logic cfgtag_LA_enque_r;
always_ff @ (posedge clk) 
  cfgtag_LA_enque_r <= cfgtag.LA_enque;

// In calibration mode, Logic Analyzer FIFO is enqueued. in ONCE mode, data
// comes from config tag and enque bit of config tag is checked to be toggled.
// in AUTO mode, each cycle two samples are inserted to FIFO until it is full.
assign LA_enque = (cfgtag.input_mode == 0)&(~(LA_fifo_almost_full|LA_fifo_full))&
    (((cfgtag.LA_enque_mode == ONCE)&(cfgtag.LA_enque != cfgtag_LA_enque_r))
    |(cfgtag.LA_enque_mode == AUTO));

// when data is sent from Logic Analyzer FIFO to output, fifo will be dequed 
// until it gets empty. data sent signal shows that one bit is sent out.
assign LA_deque = (cfgtag.output_mode == 2'b01) && data_sent_o && (~LA_fifo_empty);

//------------------------------------------------
//------------- OUTPUT SELECTOR ------------------
//------------------------------------------------

// Demux for output from 1 bit data of Logic Analyzer FIFO. 
logic [bit_num-1:0] output_demux;
assign output_demux = LA_fifo_valid ? 
                      (LA_fifo_out << cfgtag.output_bit_selector) : 0;

// Based on output mode, output data is selected from chip or logic Analyzer FIFO 
logic [bit_num-1:0] output_data;
// 01 is for LA_fifo data and 10 is for chip data 
assign output_data = cfgtag.output_mode[1] ? chip_i : output_demux; 

//------------------------------------------------
//------------- OUTPUT MODULE --------------------
//------------------------------------------------

// If output mode is sending data, each time output counter overflows
// a data has been sent out
assign data_sent_o = (cfgtag.output_mode != 0) && (output_counter_r ==0);

// each time outputcounter is about to over flow on clock edge, data 
// would be sent out on the clock edge as well
always_ff @ (posedge clk)
if (reset)
  IO_o <= 0;
else if ((cfgtag.output_mode != 0)&&(output_counter_n == 0))
  IO_o <= output_data;

endmodule
