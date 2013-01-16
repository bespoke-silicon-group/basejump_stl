`timescale 1ns/1ns

module config_net_tb;

  `define tb_id_p           7
  `define tb_data_bits_p   21 //
  `define tb_len_width_c    8 //
  `define tb_id_width_c     8 //
  `define tb_default_p     10
  `define tb_shift_width_c (`tb_data_bits_p + `tb_id_width_p + `tb_len_width_p + 1)

  `define input_vec_bits   500 // should be long enought to keep input_vec_init
  `define input_vec_init   `input_vec_bits'b0_10001_0_01100011_0_10101000_0_00000111_0_00101010_0_0_0_11111111_0_11101101_0_00010001_0_00100101_0_1111111111111111111111111111111
  //   non-match packet:                                                                          f f          f     data f       id f      len v                           reset
  //       match packet:                            f          f     data f       id f      len v
  //                                      f indicates framing bits, v indicates valid bits

  reg                             tb_clk_i;
  reg  [`input_vec_bits - 1 : 0]  tb_input_vec;
  reg                             tb_bit_i;
  wire                            tb_clk_o_0;
  wire                            tb_bit_o_0;
  wire [`tb_data_bits_p - 1 : 0]  tb_data_o;

  config_node     #(.id_p(`tb_id_p),
                    .data_bits_p(`tb_data_bits_p),
                    .default_p(`tb_default_p) )
    config_node_dut(.clk_i(tb_clk_i),
                    .bit_i(tb_bit_i),
                    .data_o(tb_data_o),
                    .bit_o(tb_bit_o_0),
                    .clk_o(tb_clk_o_0) );
  initial begin
    tb_clk_i = 1;
    tb_bit_i = 1;
    tb_input_vec = 0;
    #1 tb_input_vec = `input_vec_init;
    #2 tb_bit_i = tb_input_vec[0];
  end

  always #5 begin
    tb_clk_i = ~tb_clk_i; // flip clock every 5 ns, period 10 ns
  end

  always @ (posedge tb_clk_i) begin
    tb_input_vec = {1'b0, tb_input_vec[`input_vec_bits - 1 : 1]};
    tb_bit_i = tb_input_vec[0];
  end

  initial begin
    $dumpfile( "config_net_tb.vcd" );
    $dumpvars;
  end

  initial begin
    #3500 $finish; // simulation ends
  end

endmodule
