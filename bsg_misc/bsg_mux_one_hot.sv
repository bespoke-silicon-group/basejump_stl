
`include "bsg_defines.sv"

module bsg_mux_one_hot #(parameter `BSG_INV_PARAM(width_p)
                         , int els_p=1
			 , harden_p=1
                         )
   (
    input [els_p-1:0][width_p-1:0] data_i
    ,input [els_p-1:0] sel_one_hot_i
    ,output [width_p-1:0] data_o
    );

// The Verilator and non-Verilator models are functionally equivalent. However, Verilator
//   flattens the design, so every instance gets its own copy of each single-bit assign in
//   the reduce loop below (2,560 for a 256x10 mux), which can dominate its memory use.
//   The Verilator model does the same AND-OR on whole words: first for the elements above
//   the last whole 32-bit chunk of the select, then for each whole chunk whose select bits
//   are not all zero.
`ifdef VERILATOR
   localparam int whole_els_lp = els_p - els_p % 32;
   logic [width_p-1:0] data_lo;

   always_comb
     begin
        data_lo = '0;
        for (int j = whole_els_lp; j < els_p; j++)
          data_lo |= data_i[j] & { width_p { sel_one_hot_i[j] } };
        for (int c = 0; c < whole_els_lp; c += 32)
          if (32'(sel_one_hot_i >> c) != '0)
            for (int j = c; j < c+32; j++)
              data_lo |= data_i[j] & { width_p { sel_one_hot_i[j] } };
     end

   assign data_o = data_lo;

`else

   wire [els_p-1:0][width_p-1:0]   data_masked;

   genvar                          i,j;

   for (i = 0; i < els_p; i++)
     begin : mask
        assign data_masked[i] = data_i[i] & { width_p { sel_one_hot_i[i] } };
     end

   for (i = 0; i < width_p; i++)
     begin: reduce
        wire [els_p-1:0] gather;

        for (j = 0; j < els_p; j++)
          begin : reduce2
            assign gather[j] = data_masked[j][i];
          end

        assign data_o[i] = | gather;
     end

   if (els_p == 0)
     begin : zero
        assign data_o = '0;
     end

`endif

endmodule

`BSG_ABSTRACT_MODULE(bsg_mux_one_hot)
