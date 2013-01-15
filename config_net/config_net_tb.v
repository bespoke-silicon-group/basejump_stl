`timescale 1ns/1ns

module config_net_tb;

  reg clk_i;
  reg bit_i;
  wire clk_o_0;
  wire bit_o_0;
  wire [3:0] config_data;

  config_node     #(.id_width_p(4),
                    .info_width_p(4),
                    .id_p(7),
                    .config_bits_p(4),
                    .default_p(10) )
    config_node_dut(.clk_i(clk_i),
                    .bit_i(bit_i),
                    .config_o(config_data),
                    .bit_o(bit_o_0),
                    .clk_o(clk_o_0) );
  initial begin
    clk_i = 1;
    bit_i = 1;
    #151 bit_i = 0;
    //#10 bit_i = 1;
    //#30 bit_i = 0;
    //#30 bit_i = 1;
    repeat(100) begin
      #10 bit_i = $random;
    end
  end

  always #5 begin
    clk_i = !clk_i; // flip clock every 5 ns, period 10 ns
  end

  initial begin
    $dumpfile( "config_net_tb.vcd" );
    $dumpvars;
  end

  initial begin
    #500 $finish; // simulation ends
  end

endmodule
