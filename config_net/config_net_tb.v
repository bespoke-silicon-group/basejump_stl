`timescale 1ns/1ns

module config_net_tb;

  `define tb_id_width_c     4 //
  `define tb_len_width_c    8 //
  `define tb_id_p           7
  `define tb_data_bits_p    4 //
  `define tb_default_p     10
  `define tb_shift_width_c (`tb_data_bits_p + `tb_id_width_p + `tb_len_width_p + 1)

  `define input_vec_bits   36
  `define input_vec_init   `input_vec_bits'b1_1000_00000111_1100_0_111111111111111110
  //                                          data       id  len v         reset

  reg                             clk_i;
  reg  [`input_vec_bits - 1 : 0]  input_vec;
  reg                             bit_i;
  wire                            clk_o_0;
  wire                            bit_o_0;
  wire [`tb_data_bits_p - 1 : 0]  config_data;

  config_node     #(.id_p(`tb_id_p),
                    .data_bits_p(`tb_data_bits_p),
                    .default_p(`tb_default_p) )
    config_node_dut(.clk_i(clk_i),
                    .bit_i(bit_i),
                    .data_o(config_data),
                    .bit_o(bit_o_0),
                    .clk_o(clk_o_0) );
  initial begin
    clk_i = 1;
    bit_i = 1;
    input_vec = 0;
    #1 input_vec = `input_vec_init;
    #2 bit_i = input_vec[0];
    //#151 bit_i = 0;
    //#10 bit_i = 1;
    //#30 bit_i = 0;
    //#70 bit_i = 1;
    //repeat(100) begin
      //#10 bit_i = $random;
    //end
  end

  always #5 begin
    clk_i = !clk_i; // flip clock every 5 ns, period 10 ns
  end

  always @ (posedge clk_i) begin
    input_vec = {1'b0, input_vec[`input_vec_bits - 1 : 1]};
    bit_i = input_vec[0];
  end

  //always #10 begin
    //input_vec = {input_vec[`input_vec_bits - 2 : 0], 1'b0};
    //bit_i = input_vec[`input_vec_bits - 1];
  //end

  initial begin
    $dumpfile( "config_net_tb.vcd" );
    $dumpvars;
  end

  initial begin
    #400 $finish; // simulation ends
  end

endmodule
