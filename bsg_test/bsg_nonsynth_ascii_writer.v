// MBT 10-29-14
//
//

module bsg_nonsynth_ascii_writer
  #(parameter width_p      = "inv"
    , parameter values_p   = "inv"
    , parameter filename_p = -1
    , parameter format_p   = "%h ")
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
       file = $fopen(filename_p,"w");

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
     if (capture_valid_r)
       begin
          for (i = 0; i < values_p; i++)
	    begin
               $fwrite(file,"%x ",capture_data_r[i*width_p+:width_p]);
	    end
          $fwrite(file,"\n");
       end
   
endmodule

