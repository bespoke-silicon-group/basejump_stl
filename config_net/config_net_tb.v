`timescale 1ns/1ns

module config_net_tb;

  reg clk_i, reset, enable;
  reg clk_o0;
  reg bit_i;
  wire [3:0] config_data;

  config_node     #(.id_width_p(4),
                    .info_width_p(5),
                    .id_p(1),
                    .config_bits_p(8),
                    .default_p(1) )
    config_node_dut(.clk_i(clk_i),
                    .reset(reset),
                    .enable(enable),
                    .bit_i(bit_i),
                    .clk_o(clk_o0),
                    .config_o(config_data) );
  initial begin
    clk_i = 1;
    reset = 0;
    enable = 0;
    bit_i = 1;
    #11 reset = 1;
    #10 reset = 0;
    #10 enable = 1;
  end

  always #5
    clk_i = !clk_i; // flip clock every 5 ns, cycle 10 ns

  initial begin
    $dumpfile( "config_net_tb.vcd" );
    $dumpvars;
  end

  //initial begin
    //$display("\t\ttime, \tclk_i, \treset, \tenable, \tclk_o0, \tconfig_data");
    //$monitor("%d, \t %b, \t  %b, \t   %b, \t   %b, \t\t  %d", $time, clk_i, reset, enable, clk_o0, config_data);
  //end

  initial
  #300 $finish; // ends at 100 ns

endmodule
