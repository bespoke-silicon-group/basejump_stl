`include "config_defs.v"

module config_node_bind
  #(parameter             // node specific parameters 
    id_p = -1,            // unique ID of this node
    data_bits_p = -1)     // number of bits of configurable register associated with this node
   (input clk, // this reflects the destiniation domain clock
    input config_s config_i,
    
    input [data_bits_p - 1 : 0] data_o);

   logic [data_bits_p - 1 : 0] data_o_r, data_o_n;
   //logic [data_bits_p - 1 : 0] data_ref[data_ref_len_p] = '{default:'b0}; // data_o change reference array read from file
   logic [data_bits_p - 1 : 0] data_ref[100];

   integer probe_file;
   integer rt, ch;
   integer dump;
   integer test_idx = 0;
   integer node_id = -1;
   integer data_ref_len = -1;

   integer errors = 0;

   initial begin
     probe_file = $fopen("sc_probe.in", "r"); // open sc_probe.in file to read

     ch = $fgetc(probe_file);
     while(ch != -1) begin // end of file
       if (ch == "#") begin // comments
         rt = $ungetc(ch, probe_file);
         rt = $fscanf(probe_file, "#%s\n", dump);
       end else if (ch == "i") begin // a line giving config_node id
         rt = $ungetc(ch, probe_file);
         rt = $fscanf(probe_file, "id: %d\n", node_id);
         test_idx = 0;
       end else if (ch == "t") begin // a line giving number of test sets for a config_node with that id
         rt = $ungetc(ch, probe_file);
         if (node_id == id_p) begin
           rt = $fscanf(probe_file, "test sets: %d\n", data_ref_len);
         end else begin
           rt = $fscanf(probe_file, "%s\n", dump);
         end
       end else if (ch == "r") begin // a line giving a reference configuration string in binary
         if (node_id == id_p) begin
           rt = $ungetc(ch, probe_file);
           rt = $fscanf(probe_file, "reference: %b\n", data_ref[test_idx]);
           test_idx += 1;
         end else begin
           rt = $fscanf(probe_file, "%s\n", dump);
         end
       end else begin
         rt = $fscanf(probe_file, "%s\n", dump);
       end
       ch = $fgetc(probe_file);
     end

     $fclose(probe_file);
   end

   assign data_o_n = data_o;
   always @ (posedge clk) begin
     data_o_r <= data_o_n;
   end

   // Since the design is synchronized to posedge of clk, using negedge clk
   // here is to allow all flip-flops become stable in the register connected
   // to data_o. This might guarantee simulation correct even at gate level,
   // when all flip-flops don't necessarily change at the same time.

   integer data_ref_idx = 0;
   always @ (negedge clk) begin
     if(data_ref_idx == 0) begin
       if (data_o === data_ref[0]) begin
         $display("  @time %0d: \t output data_o_%0d\t reset   to %b", $time, id_p, data_o);
         data_ref_idx += 1;
       end
     end else begin
       if (data_o !== data_o_r) begin
         $display("  @time %0d: \t output data_o_%0d\t changed to %b", $time, id_p, data_o);
         if (data_o !== data_ref[data_ref_idx]) begin
           $display("  @time %0d: \t ERROR output data_o_%0d = %b <-> expected = %b", $time, id_p, data_o, data_ref[data_ref_idx]);

           errors += 1;
         end
         data_ref_idx += 1;
       end
     end
   end

   final begin
     if(data_ref_idx == 0) begin
       $display("!!! FAILED: Config node %5d has not reset properly!\n", id_p);
     end else begin
       if (errors != 0) begin
         $display("!!! FAILED: Config node %5d has received at least %0d wrong packet(s)!\n", id_p, errors);
       end else if (data_ref_idx < data_ref_len) begin
         $display("!!! FAILED: Config node %5d has missed at least %0d packet(s)!\n", id_p, data_ref_len - data_ref_idx);
       end else if (data_ref_idx > data_ref_len) begin
         $display("!!! FAILED: Config node %5d has received at least %0d more packet(s)!\n", id_p, data_ref_idx - data_ref_len);
       end else begin
         $display("### PASSED: Config node %5d is probably working properly.\n", id_p);
       end
     end
   end

endmodule
