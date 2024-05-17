
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

   if ((els_p == 2) && (harden_p) && (balenced_p))
     begin : fi
        for (genvar j = 0; j < width_p; j=j+1)
          begin : macro
            // https://diychip.org/sky130/sky130_fd_sc_hdll/cells/clkmux2/
            sky130_fd_sc_hdll__clkmux2 m (.X(data_o[j]), .A1(data_i[1][j]), .A0(data_i[0][j]), .S(sel_i));
          end
     end
   if ((els_p == 4) && (harden_p) && (balanced_p))
     begin : fi
        wire [width_p-1:0] data32_lo, data10_lo;
        // recurse
        bsg_mux #(.width_p(width_p), .els_p(2), .harden_p(1), .balanced_p(1))
          m32 (.data_o(data32_lo), .data_i({data_i[3], data_i[2]}), .sel_i(sel_i[0]));
        bsg_mux #(.width_p(width_p), .els_p(2), .harden_p(1), .balanced_p(1))
          m10 (.data_o(data10_lo), .data_i({data_i[1], data_i[0]}), .sel_i(sel_i[0]));
        bsg_mux #(.width_p(width_p), .els_p(2), .harden_p(1), .balanced_p(1))
          m (.data_o(data_o), .data_i({data32_lo, data10_lo}), .sel_i(sel_i[1]));
     end
   else
     begin : nofi
        assign data_o = data_i[sel_i];
     end

endmodule

