// MBT 11/26/2014
//
// bsg_node_trace_replay
//
// trace format
//
//
// 0: wait one cycle
// 1: send data
// 2: receive data


`define FILENAME "trace.in"

module bsg_nonsynth_node_trace_replay
  #(parameter ring_width_p=80
    , parameter master_id_p="inv"
    , parameter slave_id_p="inv"
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

    , output done_o
    );


   integer data_file, result_code;

   //logic [7:0] read_line[255:0];
   string  read_line;

   logic [ring_width_p-1:0] data_r;
   logic [3:0] op_r;
   logic                    eof;
   logic                    next_line_r;

   assign done_o = eof;

   initial
     begin
        data_file = $fopen(`FILENAME,"r");
        if (data_file == 0)
          begin
	     $display("############################################################################");
             $display("### Failed to open file %s", `FILENAME);
	     $display("############################################################################");
             $finish;
          end
	else
	  begin
	     $display("############################################################################");
             $display("### OPENED FILE %s", `FILENAME);
	     $display("############################################################################");
	  end
        next_line_r = 1;
        eof = 0;
        op_r = 0;
     end

   assign v_o = ~reset_i & ~eof & (op_r == 1) & en_i;
   assign data_o = data_r;

   assign ready_o = (op_r == 2);

   wire match    = ready_o & v_i & (data_i == data_r);
   wire mismatch = ready_o & v_i & (data_i != data_r);

   always @(posedge clk_i)
     begin
        if (mismatch)
          begin
	     $display("############################################################################");
             $display("### FAIL (trace mismatch) = %h", data_i);
             $display("###              expected = %h\n", data_r);
	     $display("############################################################################");
             $finish();
          end
        else
          if (match)
            begin
               $display("### trace matched %h", data_r);
               next_line_r = 1;
            end

        if (op_r == 0)
          next_line_r = 1;

        if (v_o & yumi_i)
          begin
             next_line_r = 1;
             // for now we just print out the data
             $display("### trace sent %h\n", data_r);
          end

        if (next_line_r)
          begin
             next_line_r = 0;

             result_code = $fgets (read_line, data_file);
             if (result_code == 0)
               eof = 1;

             // skip comments
             while (!eof & ((read_line[0] == " ") || (read_line[0] == "") || (read_line[0] == "#")))
               begin
                  result_code = $fgets (read_line, data_file);
                  if (result_code == 0)
                    eof = 1;
               end

             if (eof)
               begin
                  $display("############################################################################");
                  $display("###### DONE (trace finished) (%m)");
                  $display("############################################################################");
                  $finish();
               end
             else
               begin
                  result_code = $sscanf(read_line, "%d %b\n", op_r, data_r);
                  if (result_code == 0)
                    begin
                       $display("### error reading file %s:\n", read_line);
                       $finish();
                    end
               end
          end // if (next_line_r)
     end


endmodule
