`include "config_defs.v"

// This module has two implementations targeting for
// 1. Random regression testing, or
// 2. Synthesis
// which is controlled by the preprocessor CONFIG_SETTER_BY_FILE.

// The non-synthesizable part reads a stream of {0, 1}* bits from a file
// "config_setter.in", and feeds a single bit to its output port every clock
// cycle. The setter vector in file "config_setter.in" has varying length, and
// the author doesn't figure out a way to use dynamic-sized arrays in
// SystemVerilog. Therefore the module is designed to parse only a few
// characters according to the patterns in each clock cycle, instead of
// reading all bits into an array in the very beginning.

// The synthesizable part determines setter vector length and content by
// parameters given at instantiation time.

module config_setter
  #(parameter // parameters only matter without CONFIG_SETTER_BY_FILE defined
    setter_vector_p = 2'b11,
    setter_vector_bits_p = 2
   )
  (input clk_i,
   input reset_i,
   output config_s config_o
  );

  logic config_bit;

`ifdef CONFIG_SETTER_BY_FILE // for VCS random regression test; not synthesizable
  integer setter_file;
  integer vector_bits;
  integer rt, ch, count;

  // initialize and right shift setter vector
  always_ff @ (posedge clk_i)
  begin: always_feed_bit
    if (reset_i) begin
      config_bit = 1'b1;
      count = 0;

      // simple header processing
      setter_file = $fopen("config_setter.in", "r");
      if (!setter_file) begin
        disable always_feed_bit; // disable the always_ff block if file doesn't exist
      end
      ch = $fgetc(setter_file);
      while (ch == "#") begin // comments
        while (ch != "\n") begin // dump chars until the end of this line
          ch = $fgetc(setter_file);
        end
        ch = $fgetc(setter_file);
      end
      rt = $ungetc(ch, setter_file); // not comments any more.
      rt = $fscanf(setter_file, "vector bits: %d\n\n", vector_bits);
      //$display("\nFeed the configuration network with %d-bit coded configuration vector.", vector_bits);

      // SystemVerilog thinks the string, for example 5'b10, as a single pattern matching %d.
      //rt = $fscanf(setter_file, "%d'b", vector_bits); // This line doesn't work.
    end else begin // Regex: {0, 1, _}*(EOF); no other patterns are allowed in the body of this file.
      if (count < vector_bits) begin
        ch = $fgetc(setter_file);
      end
      while (ch == "_") begin // bit separater
        ch = $fgetc(setter_file);
      end
      if (ch == -1) begin // end of file
        $fclose(setter_file);
      end else begin
        config_bit = ch;
        count += 1;
      end
    end
  end
`else // synthesizable part; config nodes set by parameters
  logic [setter_vector_bits_p - 1 : 0] setter_vector;

  // initialize and right shift setter vector
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      setter_vector = setter_vector_p;
    end else begin
      setter_vector = {1'b0, setter_vector[setter_vector_bits_p - 1 : 1]};
    end
  end

  assign config_bit = setter_vector[0];
`endif

  assign config_o.cfg_clk = clk_i;
  assign config_o.cfg_bit = config_bit;

endmodule
