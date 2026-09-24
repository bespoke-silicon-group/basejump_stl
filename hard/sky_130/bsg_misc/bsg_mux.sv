
module bsg_mux #(parameter width_p = 2
                 , parameter els_p = 2
                 , parameter harden_p = 0
                 , parameter balanced_p = 0
                 , parameter lg_els_lp=$clog2(els_p)
                 )
   (
    input [els_p-1:0][width_p-1:0] data_i
    ,input [lg_els_lp-1:0] sel_i
    ,output [width_p-1:0] data_o
    );

   if ((els_p == 2) && (harden_p) && (balanced_p))
     begin : macro
        for (genvar j = 0; j < width_p; j=j+1)
          sky130_fd_sc_hd__mux2_1 m
	    (.X(data_o[j])
	     ,.A1(data_i[1][j])
	     ,.A0(data_i[0][j])
	     ,.S(sel_i)
	     );
     end
   else if ((els_p == 4) && (harden_p) && (balanced_p))
     begin : macro
        for (genvar j = 0; j < width_p; j=j+1)
          sky130_fd_sc_hd__mux4_1 m
            (.X(data_o)
             ,.A3(data_i[3][j])
             ,.A2(data_i[2][j])
             ,.A1(data_i[1][j])
             ,.A0(data_i[0][j])
             ,.S1(sel_i[1])
             ,.S0(sel_i[0])
             );
     end
   else
     begin : nofi
	for (genvar j = 0; j < width_p; j+=1)
          assign data_o[j] = data_i[sel_i][j];
     end

endmodule

