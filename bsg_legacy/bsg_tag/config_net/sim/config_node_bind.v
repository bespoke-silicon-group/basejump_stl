`include "bsg_defines.v"

`include "config_defs.v"

module config_node_bind
  #(parameter             // node specific parameters
    id_p = -1,            // unique ID of this node
    data_bits_p = -1)     // number of bits of configurable register associated with this node
   (input clk, // this reflects the destiniation domain clock

    input [data_bits_p - 1 : 0] data_o);

  logic [data_bits_p - 1 : 0] data_o_r, data_o_n;

  logic [data_bits_p - 1 : 0] data_o_ref;

  integer probe_file;
  integer rt, ch;
  integer test_idx = 0;
  integer node_id = -1;
  integer test_sets = -1;
  integer node_id_found = 0;
  integer restart_pos; // start position of valid probe reference

  integer errors = 0;

  initial
  begin: initial_open_file

    if ($test$plusargs("config-node-bind")) begin
      probe_file = $fopen("config_probe.in", "r"); // open config_probe.in file to read
    end else begin
      probe_file = 0;
    end
    if (!probe_file) begin
      disable initial_open_file;
    end

    data_o_ref = '0; // just to get rid of Lint warning about never assigning to this variable

    ch = $fgetc(probe_file);
    while(ch != -1) begin // end of file
      if (ch == "#") begin // comments
        rt = $ungetc(ch, probe_file);
        while ( (ch != "\n") && (ch != -1) ) begin // dump chars until the end of this line
          ch = $fgetc(probe_file);
        end
      end else if (ch == "c") begin // a line giving config_node id
        rt = $ungetc(ch, probe_file);
        rt = $fscanf(probe_file, "config id: %d\n", node_id);
        if (node_id == id_p) begin // found relevant reference data
          node_id_found = 1;
          rt = $fscanf(probe_file, "test sets: %d\n", test_sets); // a line giving number of test sets for a config_node with that id
          restart_pos = $ftell(probe_file); // bookmark the probe_file position
          rt = $fscanf(probe_file, "reference: %b\n", data_o_ref); // a line giving a reference configuration string in binary
          break; // to be continued from here
        end else begin // invalid patterns
          while ( (ch != "\n") && (ch != -1) ) begin // dump chars until the end of this line
            ch = $fgetc(probe_file);
          end
        end
      end else begin
        while ( (ch != "\n") && (ch != -1) ) begin // dump chars until the end of this line
          ch = $fgetc(probe_file);
        end
      end
      ch = $fgetc(probe_file);
    end
  end

  assign data_o_n = data_o;
  always @ (posedge clk) begin
    data_o_r <= data_o_n;
  end

  // Since the design is synchronized to posedge of clk, using negedge clk
  // here is to allow all flip-flops become stable in the register connected
  // to data_o. This might guarantee simulation correct even at gate level,
  // when all flip-flops don't necessarily change at the same time.

  always @ (negedge clk)
  begin: always_check_change
    if (probe_file && (node_id_found == 1)) begin
      if(test_idx == 0) begin
        if (data_o === data_o_ref) begin
          $display("\n  @time %0d: \t output data_o_%0d\t reset   to %b", $time, id_p, data_o);
          test_idx += 1;
          rt = $fscanf(probe_file, "reference: %b\n", data_o_ref); // read next reference value
        end
      end else begin
        if (data_o !== data_o_r) begin
          $display("\n  @time %0d: \t output data_o_%0d\t changed to %b", $time, id_p, data_o);
          if (data_o !== data_o_ref) begin
            $display("\n  @time %0d: \t ERROR output data_o_%0d = %b <-> expected = %b", $time, id_p, data_o, data_o_ref);
            errors += 1;
          end
          test_idx += 1;
          if (test_idx == test_sets) begin
            if ($test$plusargs("cyclic-test")) begin
              rt = $fseek(probe_file, restart_pos, 0); // circulate
              rt = $fscanf(probe_file, "reference: %b\n", data_o_ref); // read next reference value
              test_idx = 0;
            end
          end else begin
            rt = $fscanf(probe_file, "reference: %b\n", data_o_ref); // read next reference value
          end
        end
      end
    end else begin // probe_file doesn't exist
      disable always_check_change;
    end
  end

  final
  begin: final_statistics
    if (probe_file) begin
      if (node_id_found == 1) begin
        if (errors != 0) begin
          $display("### FAILED:  Config node %5d has received at least %0d wrong packet(s)!\n", id_p, errors);
        end else begin
          $display("### PASSED:  Config node %5d is probably working properly.\n", id_p);
        end

        if (!$test$plusargs("cyclic-test")) begin
          if(test_idx == 0) begin
            $display("### FAILED:  Config node %5d has not reset properly!\n", id_p);
          end else if (test_idx < test_sets) begin
            $display("### FAILED:  Config node %5d has missed at least %0d packet(s)!\n", id_p, test_sets - test_idx);
          end else if (test_idx > test_sets) begin
            $display("### FAILED:  Config node %5d has received at least %0d more packet(s)!\n", id_p, test_idx - test_sets);
          end
        end
      end else begin // config_node having id_p is instantiated but not listed in the probe_file
        $display("### WARNING: Config node %5d is detected in design but not listed in the probe file.\n", id_p);
      end
      $fclose(probe_file);
    end else begin
      disable final_statistics;
    end
  end

endmodule
