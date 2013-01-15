`timescale 1ns/1ns

module config_net_tb;

  reg clk_i;
  reg bit_i;
  wire clk_o0;
  wire [3:0] config_data;

  config_node     #(.id_width_p(4),
                    .info_width_p(5),
                    .id_p(14),
                    .config_bits_p(8),
                    .default_p(10) )
    config_node_dut(.clk_i(clk_i),
                    .bit_i(bit_i),
                    .clk_o(clk_o0),
                    .config_o(config_data) );
  initial begin
    clk_i = 1;
    bit_i = 1;
    #171 bit_i = 0;
    #10 bit_i = 1;
    #30 bit_i = 0;
    #30 bit_i = 1;
  end

  always #5
    clk_i = !clk_i; // flip clock every 5 ns, period 10 ns

  initial begin
    $dumpfile( "config_net_tb.vcd" );
    $dumpvars;
  end

  initial
  #400 $finish; // ends at 100 ns

endmodule
