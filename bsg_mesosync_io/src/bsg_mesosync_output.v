// bsg_mesosync_channel is the designed IO in bsg group that devides
// the chip's clock to a slower clock for IO based on the configuration 
// it receives. 
//
// output_module has three phases to be calibrated. After reset, it would 
// send out a known pattern so the other side (master) can bit-allign its 
// input. Next it would send all possible transitions of data using two 
// counters to make sure the output channel is reliable.
//
// To find out the proper values for bit configuration, it sends outputs of 
// 2 logic analzers from the input side. 
//
// It receives the read values of logic_analyzers from the bsg_mesosync_input
// module. On the chip to channel connection, it has ready protocol, to let 
// the chip know when it can send data. For the output to pins there is 
// no handshake protocol
//
//`ifndef DEFINITIONS_V
//`include "definitions.v"
//`endif

module bsg_mesosync_output
                  #( parameter width_p  = -1
                   )
                   ( input                          clk
                   , input                          reset
                    
                                
                   // Sinals with their acknowledge
                   , input  [width_p-1:0]           chip_i
                   , output logic                   ready_o

                   , output logic [width_p-1:0]     pins_o
                   
                   // Logic analyzer signals for mesosync_input module
                   , input                          logic_analyzer_data_i
                   , input                          LA_valid_i
                   , output                         ready_to_LA_o

                   // Configuration inputs
                   , input  [maxDivisionWidth-1:0]  output_clk_divider_i
                   , input  output_mode_e           output_mode_i
                   , input  [$clog2(width_p)-1:0]   la_output_bit_selector_i
                   , input  [$clog2(width_p)-1:0]   v_output_bit_selector_i

                   );

// internal output_ready signals based on the output mode 
logic output_ready, ready_to_sync1, ready_to_sync2;

//------------------------------------------------
//------------- CLOCK DIVIDERS --------------------
//------------------------------------------------

logic [maxDivisionWidth-1:0] input_counter_r, output_counter_r;

// clk is divided by the configured outpt_clk_divider_i plus one. So 0 
// means no clk division and 15 means clk division by factor of 16.
counter_w_overflow #(.width_p(maxDivisionWidth)) output_counter

            ( .clk(clk)
            , .reset(reset)

            , .overflow_i(output_clk_divider_i)
            , .counter_o(output_counter_r)
            );

//------------------------------------------------
//------------- OUTPUT MODULE --------------------
//------------------------------------------------

localparam counter_bits_lp = (width_p+1)*2+1;

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

// Demux that merges 1 bit outputs of Logic Analyzer and its valid signal
logic [width_p-1:0] output_demux;
assign output_demux = (LA_valid_i << v_output_bit_selector_i)
                     |(logic_analyzer_data_i << la_output_bit_selector_i);

// determning output based on output mode configuration
always_comb
  begin
     out_ctr_n = out_ctr_r;
     out_rot_n = out_rot_r;
     output_data = 0;

     unique case (output_mode_i)
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
    pins_o <= 0;
  end else if (output_counter_r == output_clk_divider_i) begin
    pins_o <= output_data;
  end else begin
    // pins_o keeps its value
    pins_o <= pins_o; 
  end
  
assign output_ready = (output_counter_r == output_clk_divider_i) & ~reset ;

// ready signals based on the output mode 
// There is no need for awknowledge of ready in STOP and PATTERN modes
assign ready_o        = output_ready & (output_mode_i == NORM);
assign ready_to_LA_o  = output_ready & (output_mode_i == LA);
assign ready_to_sync1 = output_ready & (output_mode_i == SYNC1);
assign ready_to_sync2 = output_ready & (output_mode_i == SYNC2);

endmodule
