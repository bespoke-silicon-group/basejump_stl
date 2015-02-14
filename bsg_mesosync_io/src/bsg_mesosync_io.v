module bsg_mesosync_io
                  #(  parameter bit_num_ch1_p = 5
                    , parameter bit_num_ch2_p = 5
                    , parameter log_LA_fifo_depth_p = 9
                    , parameter cfg_tag_base_id_p = 10
                    
                    , parameter bit_num_lp = bit_num_ch1_p + bit_num_ch2_p
                   )
                   (  input clk
                    , input reset
                    
                    , input config_s config_i
                    
                    , input  [bit_num_lp-1:0] IO_i

                    , output logic [bit_num_lp-1:0] chip_o
                    , output valid_o
                    
                    , input  [bit_num_lp-1:0] chip_i
                    , output data_sent_o

                    , output [bit_num_lp-1:0] IO_o

                    , output logic loop_back_o
                    );

    
// Configuration values
logic [1:0] cfg_reset, cfg_reset_r;
logic loop_back;
logic channel_reset;
clk_divider_s clk_divider;

bit_cfg_s [bit_num_lp-1:0] bit_cfg;

mode_cfg_s mode_cfg;
logic [$clog2(bit_num_lp)-1:0] input_bit_selector_ch1;
logic [$clog2(bit_num_lp)-1:0] output_bit_selector_ch1;

logic [$clog2(bit_num_lp)-1:0] input_bit_selector_ch2;
logic [$clog2(bit_num_lp)-1:0] output_bit_selector_ch2;

// Calcuating data width of each configuration node
parameter divider_node_data_width_p     = $bits(clk_divider) + 3;
parameter ch1_bit_cfg_node_data_width_p = $bits(bit_cfg[bit_num_ch1_p-1:0]);
parameter ch2_bit_cfg_node_data_width_p = $bits(bit_cfg[bit_num_lp-1:bit_num_ch1_p]);
parameter cfg_node_data_width_p         = $bits(mode_cfg) + 4*$clog2(bit_num_lp);

//------------------------------------------------
//--------------- CFGTAG NODES -------------------
//------------------------------------------------

// Relay nodes before config nodes, one at the input terminal
// and one for each channel configuration
config_s [2:0] realy_out;
    
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
            ,.data_o({cfg_reset,loop_back,clk_divider})
            );

config_node#(.id_p(cfg_tag_base_id_p+1)     
            ,.data_bits_p(cfg_node_data_width_p)
            ,.default_p('d0) 
            ) cfg_node

            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_out[1])
            ,.data_o({mode_cfg_ch,
                      input_bit_selector_ch1,output_bit_selector_ch1,
                      input_bit_selector_ch2,output_bit_selector_ch2})
            );


config_node#(.id_p(cfg_tag_base_id_p+2)     
            ,.data_bits_p(ch1_bit_cfg_node_data_width_p)
            ,.default_p('d0) 
            ) ch1_bit_cfg_node

            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_out[2])
            ,.data_o(bit_cfg[bit_num_ch1_p-1:0])
            );


config_node#(.id_p(cfg_tag_base_id_p+3)     
            ,.data_bits_p(ch2_bit_cfg_node_data_width_p)
            ,.default_p('d0) 
            ) ch2_bit_cfg_node

            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_out[2])
            ,.data_o(bit_cfg[bit_num_lp-1:bit_num_ch1_p])
            );

//------------------------------------------------
//--------------- RESET LOGIC --------------------
//------------------------------------------------

always_ff @(posedge clk)
  cfg_reset_r <= cfg_reset;

// reset is kept high until it is reset by the cfg node
always_ff @(posedge clk)
  if ((cfg_reset == 2'b10) & (cfg_reset_r == 2'b01))
    channel_reset <= 1'b0;
  else
    channel_reset <= 1'b1;

//------------------------------------------------
//------------- CLOCK DIVIDERS --------------------
//------------------------------------------------

logic [maxDivisionWidth-1:0] input_counter_r, output_counter_r;

// Each clk is divided by the configured clk_divider plus one. So 0 
// means no clk division and 15 means clk division by factor of 16.

// input clk divider counter
always_ff @ (posedge clk)
  if (channel_reset)
    input_counter_r <= 0;
  else if (input_counter_r == clk_divider.input_clk_divider)
    input_counter_r <= 0;
  else
    input_counter_r <= input_counter_r+1;

// output clk divider counter
always_ff @ (posedge clk)
  if (channel_reset)
    output_counter_r <= 0;
  else if (output_counter_r == clk_divider.output_clk_divider)
    output_counter_r <= 0;
  else
    output_counter_r <= output_counter_r+1;
 
                   
//------------------------------------------------
//------------- INPUT SAMPLER --------------------
//------------------------------------------------

// Sampling on both edges of the clock for all input bits
logic [bit_num_lp-1:0] posedge_value, negedge_value;

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
logic [bit_num_lp-1:0] sampled_r;
logic [bit_num_lp-1:0] phase_match;
logic [bit_num_lp-1:0] selected_edge;

// Select the edge to take sample
always_comb
  for (i1 = 0; i1 < bit_num_lp; i1 = i1 + 1)
    if (bit_cfg[i1].clk_edge_selector)
      selected_edge[i1] <= posedge_value[i1];
    else
      selected_edge[i1] <= negedge_value[i1];
   
// Signal which declares phase match, 
// that would be 1 only once in each input period
always_comb
  for (i2 = 0; i2 < bit_num_lp; i2 = i2 + 1)
    if (input_counter_r == bit_cfg[i2].phase)
      phase_match[i2] = 1'b1; 
    else
      phase_match[i2] = 1'b0;

// Latching the value of line on the phase match cycle
// to be used in rest of the input period
always_ff @ (posedge clk) 
  if (channel_reset) 
    sampled_r  <= 0;
  else if (mode_cfg.input_mode) 
    for (i3 = 0; i3 < bit_num_lp; i3 = i3 + 1) 
      if (phase_match[i3])
          sampled_r[i3] <= selected_edge[i3];

// When each line reaches its phase based on the input clk counter,
// its valid register would be set to 1, and it emains 1 until the 
// yumi signal becomes 1, which means the data were send out. It remains
// zero until it reaches desired phase again. In case of clk divider of 
// 0, which means no division, valid bit would always be one, since counter
// is always zero and all the phases must be zero.
logic [bit_num_lp-1:0] valid_n,valid_r;
logic yumi_n,yumi_r;

// valid_n becomes 1 in case of phase match, otherwise it keeps valid_r 
// value unless it recives the registered yumi signal, 
// so it becomes zero the cycle after data is valid
assign valid_n = ~reset & mode_cfg.input_mode & 
                 ((valid_r & ~{bit_num_lp{yumi_r}}) | phase_match);

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
  for (i4 = 0; i4 < bit_num_lp; i4 = i4 + 1)
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
logic [1:0] LA_empty, LA_full, LA_valid, LA_data, LA_deque;
logic LA_start;

assign LA_selected_bit[0][0] = posedge_value[input_bit_selector_ch1];
assign LA_selected_bit[0][1] = negedge_value[input_bit_selector_ch1];
assign LA_selected_bit[1][0] = posedge_value[input_bit_selector_ch2];
assign LA_selected_bit[1][1] = negedge_value[input_bit_selector_ch2];
assign LA_start = (mode_cfg.input_mode == LA_STOP) & mode_cfg.LA_enque;

// when data is sent from Logic Analyzer FIFO to output, fifo will be dequed 
// until it gets empty. data sent signal shows that one bit is sent out.
// Due to data_sent_o signal which is reset dependent, this singal does not
// assert during reset.
assign LA_deque[0] = data_sent_o & ~LA_empty[0];
assign LA_deque[1] = data_sent_o & ~LA_empty[1];

bsg_logic_analyzer 
                  #(.log_LA_fifo_depth_p(log_LA_fifo_depth_p)
                  ) logic_analyzer_0
                   ( .clk(clk)
                    ,.reset(channel_reset)
                   
                    ,.data_i(LA_selected_bit[0])
                    ,.start_i(LA_start)
                    ,.deque_i(LA_deque[0])
                    
                    ,.data_o(LA_data[0])
                    ,.empty_o(LA_empty[0])
                    ,.full_o(LA_full[0])
                    ,.valid_o(LA_valid[0])
                    );


bsg_logic_analyzer 
                  #(.log_LA_fifo_depth_p(log_LA_fifo_depth_p)
                  ) logic_analyzer_1
                   ( .clk(clk)
                    ,.reset(channel_reset)
                   
                    ,.data_i(LA_selected_bit[1])
                    ,.start_i(LA_start)
                    ,.deque_i(LA_deque[1])
                    
                    ,.data_o(LA_data[1])
                    ,.empty_o(LA_empty[1])
                    ,.full_o(LA_full[1])
                    ,.valid_o(LA_valid[1])
                    );

// Demux for output from 1 bit data of Logic Analyzer FIFO. 
logic [bit_num_lp-1:0] output_demux;
assign output_demux = (LA_valid[0]&LA_valid[1]) ? 
                      {(LA_data[1] << output_bit_selector_ch2),(LA_data[0] << output_bit_selector_ch1) }
                      : 0;

//------------------------------------------------
//------------- OUTPUT MODULE --------------------
//------------------------------------------------

localparam counter_min_bits_lp = 24;
localparam counter_bits_lp = `BSG_MAX(counter_min_bits_lp,(bit_num_lp+1)*2+1);

logic [counter_bits_lp-1:0] out_ctr_r, out_ctr_n;

// does not vary with channel width
logic [7:0]            out_rot_r,   out_rot_n;
logic [bit_num_lp-1:0] output_data;

// Counter and shift register
always_ff @(posedge clk)
  begin
     if (channel_reset)
       begin
          out_ctr_r                 <= counter_bits_lp ' (0);
          out_rot_r                 <= 8'b1010_0101;   // bit alignment sequence
       end
     else
       begin
          out_ctr_r                 <= out_ctr_n;
          out_rot_r                 <= out_rot_n;
       end
  end

wire [counter_bits_lp-1:0] out_ctr_r_p1 = out_ctr_r + 1'b1;

// fill pattern with at least as many 10's to fill out_cntr_width_lp bits
// having defaults be 10101 reduces electromigration on pads
wire [(((bit_num_lp+1)>>1)<<1)-1:0] inactive_pattern
                                 = { ((bit_num_lp+1) >> 1) { (2'b10) } };

always_comb
  begin
     out_ctr_n = out_ctr_r;
     out_rot_n = out_rot_r;
     output_data = {inactive_pattern[0+:bit_num_lp] };

     unique case (mode_cfg.output_mode)
       STOP:
         begin
           output_data = 0;
         end

       PAT:
         begin
            // inactive pattern
         end
       SYNC1:
         begin
            out_rot_n   = { out_rot_r[6:0], out_rot_r[7] };
            output_data = { (bit_num_lp) { out_rot_r[7] } };
         end
       SYNC1:
         begin
            out_ctr_n                 = out_ctr_r_p1;
            // we do fast bits then slow bits
            output_data =   out_ctr_r[0]
                            ? out_ctr_r[(1+(bit_num_lp))+:(bit_num_lp)]
                            : out_ctr_r[1+:(bit_num_lp)];
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
  if (reset | channel_reset) begin
    IO_o        <= 0;
    data_sent_o <= 0;
  end else if (output_counter_r == clk_divider.output_clk_divider) begin
    IO_o        <= output_data;
    data_sent_o <= ((mode_cfg.output_mode == LA)
                   |(mode_cfg.output_mode == NORM));
  end

//------------------------------------------------
//----------------- LOOP BACK --------------------
//------------------------------------------------

assign loop_back_o = loop_back;

endmodule
