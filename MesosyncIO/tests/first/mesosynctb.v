//`include "definitions.v"
`define half_period 16

module mesosynctb();

logic clk, reset, reset_r, data_sent, toggle_bit;
logic [47:0] cfg;
logic [4:0] from_IO, from_chip;
logic [4:0] to_IO, to_chip;

mesosyncIO #(.bit_num(5)) dut
                   (.clk(clk),
                    .reset(reset_r),
                    
                    .cfgtag(cfg),

                    .IO_i(from_IO),
                    .IO_o(to_IO),

                    .chip_i(from_chip),
                    .chip_o(to_chip),
                    .data_sent_o(data_sent)
                   );

always_ff@(posedge clk)
  reset_r <= reset;

assign from_IO   = {1'b0,1'b0,toggle_bit,1'b0,1'b0};
assign from_chip = '0;

initial begin

  $display("clk\t reset\t from_IO\t to_IO\t data_sent\t fifo_in\n");
  $monitor("%b\t %b\t %b\t %b\t %b\t %b\n",clk,reset,from_IO,to_IO,data_sent,dut.LA_fifo_data);

  cfg = 48'b0100_0100_010_0_0_00_1_00_11111_0000_0000_0000_0000_0000_00_011;
  cfg = '0;
  reset = 1'b1;
  @ (negedge clk)
  @ (negedge clk)
  $display("module has been reset");
  reset = 1'b0;
  cfg = 48'b0100_0100_010_0_1_11_1_00_11111_0000_0000_0000_0000_0000_00_011;
  #1000
  cfg = 48'b0100_0100_010_0_0_00_1_00_11111_0000_0000_0000_0000_0000_01_011;
  #10000
  $stop;
end


always begin
  #`half_period clk = 1'b0;
  #`half_period clk = 1'b1;
end
    
always begin
  #(`half_period/2) toggle_bit = 1'b0;
  #`half_period toggle_bit = 1'b1;
  #(`half_period/2) toggle_bit = 1'b0;
end


endmodule
