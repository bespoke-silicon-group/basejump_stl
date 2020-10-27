// MBT 11/26/2014
//
// bsg_nonsynth_fsb_node_trace_replay
//
// note: generally it is better to use
//       bsg_fsb_node_trace_replay
//       than this module, because 1)
//       it is synthesizeable, and 2)
//       it may have races (see fixme)
//
// trace format
//
//
// 0: wait one cycle
// 1: send data
// 2: receive data
// 3: assert done_o; test complete.
// 4: end test; call $finish

`include "bsg_defines.v"

module bsg_nonsynth_fsb_node_trace_replay
  #(parameter ring_width_p=80
    , parameter master_id_p="inv"
    , parameter slave_id_p="inv"
    , parameter filename_p="trace.in"
    )
   (input clk_i
    , input reset_i
    , input en_i

    // input channel
    , input v_i
    , input [ring_width_p-1:0] data_i
    , output ready_o

    // output channel
    , output v_o
    , output [ring_width_p-1:0] data_o
    , input yumi_i

    , output reg done_o
    );

   integer data_file, result_code;

   //logic [7:0] read_line[255:0];
   string  read_line;

   logic [ring_width_p-1:0] data_r;
   logic [3:0] op_r;
   logic                    eof;
   logic                    next_line_r;

   logic [$bits(byte) * 1000-1:0] filename_string;
   string 			  filename_path = filename_p;

   initial
     begin

	// check for command line argument; otherwise use default.
	if ($test$plusargs("fsb_trace"))
	  begin
	     if ($value$plusargs("fsb_trace=%s", filename_string))
	       begin
		  // make it prettier when we print it out
		  filename_path = string ' (filename_string);
		  $display("### %m using filename %s", filename_path);
	       end
	  end

	data_file = $fopen(filename_path,"r");

        if (data_file == 0)
          begin
             $display("############################################################################");
             $display("### %m Failed to open file %s", filename_path);
             $display("############################################################################");
             $finish;
          end
        else
          begin
             $display("############################################################################");
             $display("### %m OPENED FILE %s", filename_path);
             $display("############################################################################");
          end
        next_line_r = 1;
        eof = 0;
        op_r = 0;
        done_o = 0;
     end

   assign v_o = ~reset_i & ~eof & (op_r == 1) & en_i;
   assign data_o = data_r;

   wire receive_op = (op_r == 2);

   // we absorb data if we are receiving or if we are done.
   assign ready_o = receive_op | done_o;

   // mbt fixme: I suspect this should actually
   // be done on the negative edge of the clock
   // to avoid races.
   
   always @(posedge clk_i)
     begin
        if (!done_o)
          begin
             case (op_r)
               0: next_line_r = 1;
               1:
                 // send data
                 if (v_o & yumi_i)
                   begin
                      next_line_r = 1;
                      // for now we just print out the data
                      $display("### trace %s sent %h", filename_p, data_r);
                   end
               2:
                 // receive and check
                 if (v_i)
                   begin
                      if (data_i != data_r)
                        begin
                           $display("############################################################################");
                           $display("### %m ");
                           $display("###    ");
                           $display("### FAIL (trace mismatch) = %h", data_i);
                           $display("###              expected = %h\n", data_r);
                           $display("############################################################################");
                           $finish();
                        end
                      else
                        begin
                           $display("### %m trace %s matched %h", filename_p, data_r);
                           next_line_r = 1;
                        end // else: !if(data_i != data_r)
                   end // if (v_i)
               3:
                 begin
                    $display("############################################################################");
                    $display("###### done_o=1 (trace %s finished) (%m)", filename_p);
                    $display("############################################################################");
                    done_o = 1;
                 end
               4:
                 begin
                    $display("############################################################################");
                    $display("###### DONE (trace %s finished; CALLING $finish) (%m)", filename_p);
                    $display("############################################################################");
                    $finish;
                 end
               default:
                 $display("%m unknown op %x\n", op_r);
             endcase

             if (next_line_r)
               begin
                  next_line_r = 0;

                  result_code = $fgets (read_line, data_file);
                  if (result_code == 0)
                    eof = 1;

                  // skip comments
                  while (!eof & ((read_line[0] == "\n") || (read_line[0] == " ") || (read_line[0] == "") || (read_line[0] == "#")))
                    begin
                       result_code = $fgets (read_line, data_file);
                       if (result_code == 0)
                         eof = 1;
                    end

                  if (eof)
                    begin
                       $display("############################################################################");
                       $display("###### End of Trace (trace %s finished) (%m)", filename_p);
                       $display("############################################################################");
                    end
                  else
                    begin
                       result_code = $sscanf(read_line, "%b\n", {op_r, data_r});
                       if (result_code == 0)
                         begin
                            $display("### error reading file %s:\n", read_line);
                            $finish();
                         end
                    end
               end // if (next_line_r)
          end // if (!done_o)

     end


endmodule
