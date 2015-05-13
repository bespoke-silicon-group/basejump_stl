module bsg_mux #(parameter width_p="inv"
		 , els_p=1
		 , lg_els_lp=`BSG_SAFE_CLOG2(els_p)
		 )
   (
    input [els_p-1:0][width_p-1:0] data_i
    ,input [lg_els_lp-1:0] sel_i
    ,output [width_p-1:0] data_o
    );

   assign data_o = data_i[sel_i];

endmodule

