module testbench();

  parameter rom_size_p = `ROM_SIZE;
  logic sub_i;
  logic [31:0] a_i;
  logic [31:0] b_i;

  // rv_tester module
  logic test_clk;
  logic test_rst;
  logic test_en;
  logic input_v;
  logic input_ready;
  logic [64:0] input_vector;
  logic output_v;
  logic output_ready;
  logic [35:0] output_vector;
  logic done;

  rv_tester #(
    .input_rom_width_p(32*2+1)
    ,.output_rom_width_p(4+32)
    ,.rom_size_p(rom_size_p)
    ,.input_rom_filename_p("add_sub_32_input.rom")
    ,.output_rom_filename_p("add_sub_32_output.rom")
  ) tester0 (
    .clk_i(test_clk)
    ,.rst_i(test_rst)
    ,.en_i(test_en)
    ,.input_v_o(input_v)
    ,.input_ready_i(input_ready)
    ,.input_vector_o(input_vector)
    ,.output_v_i(output_v)
    ,.output_ready_o(output_ready)
    ,.output_vector_i(output_vector)
    ,.done_o(done)
  );

  bsg_fpu_add_sub #(.width_p(32)) fpu_add_sub (
    .clk_i(test_clk)
    ,.rst_i(test_rst)
    ,.en_i(test_en)
    ,.v_i(input_v)
    ,.yumi_i(output_ready)
    ,.a_i(input_vector[63:32])
    ,.b_i(input_vector[31:0])
    ,.sub_i(input_vector[64])
    ,.v_o(output_v)
    ,.ready_o(input_ready)
    ,.z_o(output_vector[31:0])
    ,.unimplemented_o(output_vector[35])
    ,.invalid_o(output_vector[34])
    ,.overflow_o(output_vector[33])
    ,.underflow_o(output_vector[32])
    ,.wr_en_2_o()
    ,.wr_en_3_o()
  );
  

  initial begin
    $vcdpluson;
    test_clk = 0;
    test_rst = 1;
    test_en = 0;
    #(4);
    test_rst = 0;
    #(4);
    test_en = 1;
 
    while (~done) begin 
      #(1);
    end
    $finish;
  end

  always begin
    #(1) test_clk <= ~test_clk;
  end

endmodule
