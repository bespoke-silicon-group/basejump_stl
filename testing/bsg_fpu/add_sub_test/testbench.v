module testbench();

  parameter rom_size_p = `ROM_SIZE;
  parameter width_p = `WIDTH;
  parameter string input_rom_p = "add_sub_input.rom";
  parameter string output_rom_p = "add_sub_output.rom";

  // rv_tester module
  logic test_clk;
  logic test_rst;
  logic test_en;
  logic input_v;
  logic input_ready;
  logic [width_p*2:0] input_vector;
  logic output_v;
  logic output_ready;
  logic [width_p-1+4:0] output_vector;
  logic done;

  rv_tester #(
    .input_rom_width_p(width_p*2+1)
    ,.output_rom_width_p(4+width_p)
    ,.rom_size_p(rom_size_p)
    ,.input_rom_filename_p(input_rom_p)
    ,.output_rom_filename_p(output_rom_p)
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

  bsg_fpu_add_sub #(.width_p(width_p)) fpu_add_sub (
    .clk_i(test_clk)
    ,.rst_i(test_rst)
    ,.en_i(test_en)
    ,.v_i(input_v)
    ,.yumi_i(output_ready)
    ,.a_i(input_vector[width_p+:width_p])
    ,.b_i(input_vector[width_p-1:0])
    ,.sub_i(input_vector[width_p*2])
    ,.v_o(output_v)
    ,.ready_o(input_ready)
    ,.z_o(output_vector[width_p-1:0])
    ,.unimplemented_o(output_vector[width_p+3])
    ,.invalid_o(output_vector[width_p+2])
    ,.overflow_o(output_vector[width_p+1])
    ,.underflow_o(output_vector[width_p])
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
    #(1);
    #(1);
    $finish;
  end

  always begin
    #(1) test_clk <= ~test_clk;
  end

endmodule
