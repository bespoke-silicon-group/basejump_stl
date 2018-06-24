/**
 *  rv_tester.v
 *
 *  unit-testing wrapper for modules with ready-valid interface.
 *
 *  @author Tommy Jung
 */

module rv_tester #( parameter input_rom_width_p = "inv"
                    ,parameter output_rom_width_p = "inv"
                    ,parameter rom_size_p = "inv"
                    ,parameter input_rom_filename_p = "inv"
                    ,parameter output_rom_filename_p = "inv")
(
  input clk_i
  ,input rst_i
  ,input en_i
  // input_rom
  ,output logic input_v_o
  ,input input_ready_i
  ,output logic [input_rom_width_p-1:0] input_vector_o
  // output rom
  ,input output_v_i
  ,output logic output_ready_o
  ,input [output_rom_width_p-1:0] output_vector_i
  // result
  ,output logic done_o
);

  logic [`BSG_SAFE_CLOG2(rom_size_p):0] input_rom_addr_r;
  logic [`BSG_SAFE_CLOG2(rom_size_p):0] output_rom_addr_r;
  logic [`BSG_SAFE_CLOG2(rom_size_p):0] input_rom_addr_n;
  logic [`BSG_SAFE_CLOG2(rom_size_p):0] output_rom_addr_n;
  logic [input_rom_width_p-1:0] input_rom_data;
  logic [output_rom_width_p-1:0] output_rom_data;

  data_rom #(
    .word_width_p(input_rom_width_p)
    ,.word_count_p(rom_size_p)
    ,.filename_p(input_rom_filename_p)
  ) input_rom (
    .addr_i(input_rom_addr_r[`BSG_SAFE_CLOG2(rom_size_p)-1:0])
    ,.data_o(input_rom_data)
  );

  data_rom #(
    .word_width_p(output_rom_width_p)
    ,.word_count_p(rom_size_p)
    ,.filename_p(output_rom_filename_p)
  ) output_rom (
    .addr_i(output_rom_addr_r[`BSG_SAFE_CLOG2(rom_size_p)-1:0])
    ,.data_o(output_rom_data)
  );

  always_ff @ (posedge clk_i) begin
    if (rst_i) begin
      input_rom_addr_r <= 0;
      output_rom_addr_r <= 0;
    end
    else begin
      if (en_i) begin
        input_rom_addr_r <= input_rom_addr_n;
        output_rom_addr_r <= output_rom_addr_n;
      end
    end
  
    if (output_v_i & output_ready_o) begin
      assert(output_vector_i == output_rom_data)
        else $fatal("test failed. expected: %x actual: %x", output_rom_data, output_vector_i);
    end

  end

  always_comb begin

    input_v_o = input_rom_addr_r < rom_size_p;
    input_vector_o = input_rom_data;
    output_ready_o = output_v_i & (output_rom_addr_r < rom_size_p);
    done_o = output_rom_addr_r == (rom_size_p - 1); 

    input_rom_addr_n = input_v_o & input_ready_i & (input_rom_addr_r < rom_size_p - 1)
      ? input_rom_addr_r + 1
      : input_rom_addr_r;

    output_rom_addr_n = output_v_i & output_ready_o & (output_rom_addr_r < rom_size_p - 1)
      ? output_rom_addr_r + 1
      : output_rom_addr_r;
  end

endmodule
