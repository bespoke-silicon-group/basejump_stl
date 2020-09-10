// creates an array of shift registers, with independently
// controlled three input muxes,
// 0=keep value, 1=get prev value,2=set new value
//
//


`include "bsg_defines.v"

module bsg_fifo_shift_datapath #(parameter  width_p    = "inv"
                                 ,parameter els_p      = "inv"
                                 ,parameter default_p  = { (width_p) {1'b0} }
                                 )
   (input   clk_i
    , input [width_p-1:0]    data_i
    , input [els_p-1:0][1:0] sel_i
    , output [width_p-1:0]   data_o
    );

   genvar i;

   logic [els_p:0][width_p-1:0] r, r_n;

   assign r[els_p] = default_p;

   for (i = 0; i < els_p; i=i+1)
     begin: el
        always_comb
          begin
             unique case (sel_i[i])
               2'b01:
                 r_n[i] = r[i+1];
               2'b10:
                 r_n[i] = data_i;
               default:
                 r_n[i] = r[i];
             endcase
          end

        always_ff @(posedge clk_i)
          r[i] <= r_n[i];
     end

   assign data_o = r[0];

endmodule
