module testbench();

  parameter rom_size_p = `LINE_COUNT;
  logic [`BSG_SAFE_CLOG2(rom_size_p)-1:0] rom_addr_i;
  logic [31:0] f2i_i;
  logic [31:0] actual;
  logic [2:0] rm;
  logic [31:0] expected;
  logic passed;

  assign passed = actual == expected;
  
  data_rom #(
    .word_width_p(32+3)
    ,.word_count_p(rom_size_p)
    ,.filename_p("f2i_32_input.rom")
  ) input_rom (
    .addr_i(rom_addr_i)
    ,.data_o({rm, f2i_i})
  );
 
  data_rom #(
    .word_width_p(32)
    ,.word_count_p(rom_size_p)
    ,.filename_p("f2i_32_output.rom")
  ) output_rom (
    .addr_i(rom_addr_i)
    ,.data_o(expected)
  );

  logic [31:0] output0;
  bsg_fpu_f2i #(.width_p(32)) f2i_32 (
    .a_i(f2i_i)
    ,.rm_i(rm)
    ,.o(actual)
  );  

  initial begin
    $vcdpluson;
    rom_addr_i = 0;
    for (int i = 0; i < rom_size_p; i++) begin
      #(1);
      assert(actual == expected);
      rom_addr_i++;
    end 
    #(1);
  end


endmodule
