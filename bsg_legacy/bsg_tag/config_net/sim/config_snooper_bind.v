`include "bsg_defines.v"

`include "config_defs.v"

module config_snooper_bind
   (input clk, // this reflects the destiniation domain clock

    input [data_max_bits_lp - 1 : 0] id_o,
    input [data_max_bits_lp - 1 : 0] data_o);

  logic [data_max_bits_lp - 1 : 0] id_o_r, id_o_n;
  logic [data_max_bits_lp - 1 : 0] data_o_r, data_o_n;

  logic [id_width_lp - 1 : 0] id_o_ref;
  logic [data_max_bits_lp - 1 : 0] data_o_ref;

  integer test_file;
  integer rt, ch;
  integer has_reset = 0;
  integer node_id = -1;
  integer test_sets = -1;
  integer node_id_found = 0;
  integer restart_pos; // start position of valid references

  integer errors = 0;

  initial
  begin: initial_open_file

    if ($test$plusargs("config-snooper-bind")) begin
      test_file = $fopen("config_test.in", "r"); // open config_probe.in file to read
    end else begin
      test_file = 0;
    end
    if (!test_file) begin
      disable initial_open_file;
    end

    id_o_ref = '0;
    data_o_ref = '0; // need initialization to get rid of Lint warning about never assigning variables

    ch = $fgetc(test_file);
    while(ch != -1) begin // end of file
      if ( (ch == "#") || (ch == " ") ) begin // comments, and white spaces are skipped
        rt = $ungetc(ch, test_file);
        while ( (ch != "\n") && (ch != -1) ) begin // dump chars until the end of this line
          ch = $fgetc(test_file);
        end
      end else if (ch == "\n") begin // empty newlines are also skipped
        ch = $fgetc(test_file);
        continue;
      end else begin
        rt = $ungetc(ch, test_file);
        restart_pos = $ftell(test_file); // bookmark the test_file position
        rt = $fscanf(test_file, "%d\t\t%b\n", id_o_ref, data_o_ref);
        break; // to be continued from here
      end
      ch = $fgetc(test_file);
    end
  end

  assign id_o_n = id_o;
  assign data_o_n = data_o;
  always @ (posedge clk) begin
    id_o_r <= id_o_n;
    data_o_r <= data_o_n;
  end

  // Since the design is synchronized to posedge of clk, using negedge clk
  // here is to allow all flip-flops become stable in the register connected
  // to data_o. This might guarantee simulation correct even at gate level,
  // when all flip-flops don't necessarily change at the same time.

  always @ (negedge clk)
  begin: always_check_change
    if (test_file) begin
      if (has_reset == 0) begin // reset value check
        if (data_o === '0) begin
          $display("\n  @time %0d: \t snooper node data_o     reset to %b", $time, data_o);
          has_reset = 1;
        end
      end else begin
        if ( (id_o !== id_o_r) || (data_o !== data_o_r) ) begin
          $display("\n  @time %0d: \t snooped id, tag, and data changed to %d, %b, %b", $time, id_o[0 +: id_width_lp], id_o[id_width_lp +: id_tag_bits_lp], data_o);
          if (data_o !== data_o_ref) begin
            $display("\n  @time %0d: \t ERROR snooped data_o = %b <-> expected = %b", $time, data_o, data_o_ref);
            errors += 1;
          end
          if (id_o[0 +: id_width_lp] !== id_o_ref) begin
            $display("\n  @time %0d: \t ERROR snooped id_o = %d <-> expected = %d", $time, id_o[0 +: id_width_lp], id_o_ref);
            errors += 1;
          end
          ch = $fgetc(test_file);
          if (ch == -1) begin // end of file
            if ($test$plusargs("cyclic-test")) begin
              rt = $fseek(test_file, restart_pos, 0); // circulate
              rt = $fscanf(test_file, "%d\t\t%b\n", id_o_ref, data_o_ref);
              has_reset = 0;
            end
          end else begin
            rt = $ungetc(ch, test_file);
            rt = $fscanf(test_file, "%d\t\t%b\n", id_o_ref, data_o_ref);
          end
        end
      end
    end else begin
      disable always_check_change;
    end
  end

  final
  begin: final_statistics
    if (test_file) begin
      if (has_reset == 0) begin
        $display("### FAILED:  Snooper node      has not reset properly!\n");
      end else begin
        if (errors != 0) begin
          $display("### FAILED:  Snooper node      has detected at least %0d wrong packet(s)!\n", errors);
        end else begin
          $display("### PASSED:  Snooper node      is probably working properly.\n");
        end
      end
      $fclose(test_file);
    end else begin
      disable final_statistics;
    end
  end

endmodule
