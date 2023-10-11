`include "bsg_defines.v"

`include "config_defs.v"

// This module reads a stream of {0, 1}* bits from a file
// "config_file_setter.in", and feeds a single bit to its output port every
// clock cycle. The setter vector in file "config_file_setter.in" has varying
// length, and the author doesn't figure out a way to use dynamic-sized arrays
// in SystemVerilog. Therefore the module is designed to parse only a few
// characters according to the patterns in each clock cycle, instead of
// reading all bits into an array in the very beginning.

module config_file_setter
  (input clk_i,
   input reset_i,
   output config_s config_o
  );

  logic config_bit;

  integer setter_file;
  integer vector_bits;
  integer rt, ch, count;
  integer restart_pos; // start position of valid vector bits in file

  // initialize and right shift setter vector
  always_ff @ (posedge clk_i)
  begin: always_feed_bit
    if (reset_i) begin
      config_bit = 1'b1;
      count = 0;
      vector_bits = '0;

      if ($test$plusargs("config-file-setter")) begin
        setter_file = $fopen("config_file_setter.in", "r");
      end else begin
        setter_file = 0;
      end

      // simple header processing
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
      restart_pos = $ftell(setter_file); // bookmark the setter_file position

      // SystemVerilog thinks the string, for example 5'b10, as a single pattern matching %d.
      //rt = $fscanf(setter_file, "%d'b", vector_bits); // This line doesn't work.
    end else begin // Regex: {0, 1, _}*(EOF); no other patterns are allowed in the body of this file.
      if (count <= vector_bits) begin
        ch = $fgetc(setter_file);
      end
      while (ch == "_") begin // bit separater
        ch = $fgetc(setter_file);
      end

      if (ch == -1) begin // end of file
        if ($test$plusargs("cyclic-test")) begin
          rt = $fseek(setter_file, restart_pos, 0); // circulate
          config_bit = 1'b1;                 // |--> 0 means restart_pos offsets from the beginning of setter_file
          count = 0;
        end else begin
          config_bit = 1'b0; // consecutive '0's are NOPs
        end
      end else begin
        config_bit = ch;
        count += 1;
      end
    end
  end

  final
  begin: close_file
    $fclose(setter_file);
  end

  assign config_o.cfg_clk = clk_i;
  assign config_o.cfg_bit = config_bit;

endmodule
