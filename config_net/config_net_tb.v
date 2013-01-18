`define timescale 1ns/1ns

module config_net_tb;

  localparam tb_id_lp          =  7; 
  localparam tb_data_bits_lp   = 21; //
  localparam tb_len_width_lp   =  8; //
  localparam tb_id_width_lp    =  8; //
  localparam tb_default_lp     = 10; 
  localparam tb_shift_width_lp = (tb_data_bits_lp + tb_id_width_lp + tb_len_width_lp + 1);

  `define input_vec_bits_lp   500  // should be long enought to keep input_vec_init_lp
  `define input_vec_init_lp   `input_vec_bits_lp'b0_10001_0_01100011_0_10101000_0_00000111_0_00101010_0_0_0_11111111_0_11101101_0_00010001_0_00100101_0_1111111111111111111111111111111
  //   non-match packet:                                                                          f f          f     data f       id f      len v                           reset
  //       match packet:                            f          f     data f       id f      len v
  //                                      f indicates framing bits, v indicates valid bits

  logic                              tb_clk_i;
  logic [`input_vec_bits_lp - 1 : 0] tb_input_vec;
  logic                              tb_bit_i;
  logic                              tb_bit_o_0;
  logic [tb_data_bits_lp - 1 : 0]    tb_data_o;

  config_node     #(.id_p(tb_id_lp),
                    .data_bits_p(tb_data_bits_lp),
                    .default_p(tb_default_lp) )
    config_node_dut(.clk_i(tb_clk_i),
                    .bit_i(tb_bit_i),
                    .data_o(tb_data_o),
                    .bit_o(tb_bit_o_0) );
  initial begin
    tb_clk_i = 1;
    tb_bit_i = 1;
    tb_input_vec = 0;
    #1 tb_input_vec = `input_vec_init_lp;
    #2 tb_bit_i = tb_input_vec[0];
  end

  always #5 begin
    tb_clk_i = ~tb_clk_i; // flip clock every 5 ns, period 10 ns
  end

  always @ (posedge tb_clk_i) begin
    tb_input_vec = {1'b0, tb_input_vec[`input_vec_bits_lp - 1 : 1]};
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
