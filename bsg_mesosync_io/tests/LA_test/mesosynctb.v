//`include "definitions.v"
`define half_period 16
parameter bit_num_p = 5;

module mesosynctb();

logic clk, reset, reset_r, data_sent, toggle_bit,valid;
logic [bit_num_p-1:0] from_IO, from_chip;
logic [bit_num_p-1:0] to_IO, to_chip;

clk_divider_s clk_divider;
mode_cfg_s mode_cfg;
logic [$clog2(bit_num_p)-1:0] input_bit_selector_ch1;
logic [$clog2(bit_num_p)-1:0] output_bit_selector_ch1;
logic [$clog2(bit_num_p)-1:0] input_bit_selector_ch2;
logic [$clog2(bit_num_p)-1:0] output_bit_selector_ch2;
bit_cfg_s [bit_num_p-1:0] bit_cfg;


bsg_mesosync_channel 
           #(  .width_p(bit_num_p)
             , .LA_els_p(16)
             ) DUT
            (  .clk(clk)
             , .reset(reset_r)
             
             // Configuration inputs
             , .clk_divider_i(clk_divider)
             , .bit_cfg_i(bit_cfg)
             , .mode_cfg_i(mode_cfg)
             , .input_bit_selector_ch1_i(input_bit_selector_ch1)
             , .output_bit_selector_ch1_i(output_bit_selector_ch1)
             , .input_bit_selector_ch2_i(input_bit_selector_ch2)
             , .output_bit_selector_ch2_i(output_bit_selector_ch2)

        
             // Sinals with their acknowledge
             , .IO_i(from_IO)

             , .chip_o(to_chip)
             , .valid_o(valid)
             
             , .chip_i(from_chip)
             , .data_sent_o(data_sent)

             , .IO_o(to_IO)

             );

always_ff@(posedge clk)
  reset_r <= reset;

assign from_IO   = {1'b0,1'b0,toggle_bit,1'b1,1'b1};
assign from_chip = '0;
assign clk_divider.output_clk_divider = 4'b1111;
assign clk_divider.input_clk_divider = 4'b1111;

int i;

initial begin

  $display("clk\t reset\t from_IO to_IO\t valid\t sent\t fifo_in_0,1");
  $monitor("%b\t %b\t %b\t %b\t %b\t %b\t %b\t %b\t %b\t %b\t %b",clk,reset,from_IO,to_IO,valid,DUT.data_sent,DUT.LA_selected_bit[1],DUT.LA_selected_bit[0],
            DUT.LA_data, DUT.LA_valid, DUT.output_demux
          );
  for (i=0 ; i<bit_num_p; i= i+1)
  bit_cfg[i]='{clk_edge_selector:1'b0, phase: 4'b0000};
  input_bit_selector_ch1  = 3'b010;
  output_bit_selector_ch1 = 3'b011;
  input_bit_selector_ch2  = 3'b001;
  output_bit_selector_ch2 = 3'b100;
  mode_cfg = create_cfg (LA_STOP,1'b0,STOP);
  
  reset = 1'b1;
  @ (negedge clk)
  @ (negedge clk)
  reset = 1'b0;
  @ (posedge clk)
  $display("module has been reset");
 
 
  mode_cfg = create_cfg (LA_STOP,1'b1,STOP);
  #600

  $display ("sampling finished");

  @(negedge clk)
  mode_cfg = create_cfg (LA_STOP,1'b0,LA);

  #5000
  
  $display ("Output bit changed");
  output_bit_selector_ch2 = 3'b010;
  #5000

  $stop;
end

always begin
  #`half_period clk = 1'b0;
  #`half_period clk = 1'b1;
end
    
always begin
  #(`half_period/2) toggle_bit = 1'b1;
  #(`half_period/2) toggle_bit = 1'b1;
  #(`half_period/2) toggle_bit = 1'b1;
  #(`half_period/2) toggle_bit = 1'b1;
  #(`half_period/2) toggle_bit = 1'b1;
  #(`half_period/2) toggle_bit = 1'b1;
  #(`half_period/2) toggle_bit = 1'b0;
  #(`half_period/2) toggle_bit = 1'b0;
end

function mode_cfg_s create_cfg(input input_mode_e in_mode,input LA_enque, output_mode_e out_mode);
    create_cfg = 
           '{input_mode:   in_mode
            ,LA_enque:    LA_enque
            ,output_mode: out_mode
            };
endfunction

endmodule
