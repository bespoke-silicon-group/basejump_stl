// MBT 10-29-14
//
//

`include "bsg_defines.v"

module bsg_nonsynth_ascii_writer
  #(parameter width_p      = "inv"
    , parameter values_p   = "inv"
    , parameter filename_p = -1
    , parameter fopen_param_p = "w"
    , parameter format_p   = "%x ")
   (input clk
    , input reset_i
    , input valid_i
    , input [width_p*values_p-1:0] data_i
    );

   integer file = -1;
   integer i;

   // fixme: check error condition

   always @(posedge reset_i)
     if (file == -1)
       begin
	  file = $fopen(filename_p,fopen_param_p);
       end
   
   logic [width_p*values_p-1:0] capture_data_r;
   logic                        capture_valid_r;

   // delay the data by one cycle to avoid races
   // in timing simulation

   always @(posedge clk)
     begin
        capture_data_r  <= data_i;
        capture_valid_r <= valid_i;
     end

   // format does not work as parameter
   always @(negedge clk)
     if (capture_valid_r && file != -1)
       begin
          for (i = 0; i < values_p; i++)
	    begin
               $fwrite(file,format_p,capture_data_r[i*width_p+:width_p]);
	    end
          $fwrite(file,"\n");
       end
   
endmodule

