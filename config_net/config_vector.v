`include "config_defs.v"

// This module reads a stream of {0, 1}* bits from a file "config_vector.in",
// and feeds a single bit to its output port every clock cycle. The module is
// is made for random verification purpose and it's not synthesizable.
// Use `config_vector` module in real hardware for the same purpose.

// The bit vector in file "config_vector.in" has varying length, and the
// author doesn't figure out a way to use dynamic-sized arrays in
// SystemVerilog. Therefore the module is designed to parse only a few
// characters according to the patterns in each clock cycle, instead of
// reading all bits into an array in the very beginning.

module config_vector
  (input clk_i,
   input reset_i,
   output config_s config_o
  );

  logic config_bit;
  integer vector_file;
  integer vector_bits;
  integer rt, ch, count;

  // initialize and right shift test vector
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      config_bit = 1'b1;
      count = 0;

      // simple header processing
      vector_file = $fopen("config_vector.in", "r");
      ch = $fgetc(vector_file);
      while (ch == "#") begin // comments
        while (ch != "\n") begin // dump chars until the end of this line
          ch = $fgetc(vector_file);
        end
        ch = $fgetc(vector_file);
      end
      rt = $ungetc(ch, vector_file); // not comments any more.
      rt = $fscanf(vector_file, "vector bits: %d\n\n", vector_bits);
      $display("\nFeed the configuration network with %d coded configuration network bits.", vector_bits);

      // SystemVerilog thinks the string, for example 5'b10, as a single pattern matching %d.
      //rt = $fscanf(vector_file, "%d'b", vector_bits); // This line doesn't work.
    end else begin // Regex: {0, 1, _}*(EOF); no other patterns are allowed in the body of this file.
      if (count < vector_bits) begin
        ch = $fgetc(vector_file);
      end
      while (ch == "_") begin // bit separater
        ch = $fgetc(vector_file);
      end
      if (ch == -1) begin // end of file
        $fclose(vector_file);
      end else begin
        config_bit = ch;
        count += 1;
      end
    end
  end

  assign config_o.cfg_clk = clk_i;
  assign config_o.cfg_bit = config_bit;

endmodule
