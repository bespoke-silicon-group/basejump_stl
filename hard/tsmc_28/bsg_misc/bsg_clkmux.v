`include "bsg_defines.v"
module bsg_clkmux #(els_p = 2
                 , width_p = 1
                 , harden_p = 1
                 , strength_p = 0
                 , lg_els_lp=`BSG_SAFE_CKOG2(els_p)
                 )
   (
    input [els_p-1:0][width_p-1:0] data_i
    ,input [lg_els_lp-1:0] sel_i
    ,output [width_p-1:0] data_o
    );

  localparam total_els_lp = width_p*els_p;
  localparam pot_els_lp = 2**$clog2(total_els_lp);

   if (total_els_lp == 2 && strength_p == 0)
     begin : s0
       CKMUX2D0BWP7T40P140ULVT c
        (.I0(data_i[0], .I1(data_i[1]), .S(sel_i), .Z(data_o));
     end
   else if (total_els_lp == 2 && strength_p == 1)
     begin : s1
       CKMUX2D1BWP7T40P140ULVT c 
        (.I0(data_i[0], .I1(data_i[1]), .S(sel_i), .Z(data_o));
     end
   else if (total_els_lp == 2 && strength_p == 2)
     begin : s1
       CKMUX2D2BWP7T40P140ULVT c
        (.I0(data_i[0], .I1(data_i[1]), .S(sel_i), .Z(data_o));
     end
   else if (total_els_lp == 2 && strength_p == 4)
     begin : s1
       CKMUX2D4BWP7T40P140ULVT c
        (.I0(data_i[0], .I1(data_i[1]), .S(sel_i), .Z(data_o));
     end
   else if (total_els_lp == 2 && strength_p == 8)
     begin : s1
       CKMUX2D8BWP7T40P140ULVT c
        (.I0(data_i[0], .I1(data_i[1]), .S(sel_i), .Z(data_o));
     end
   else
     begin
       localparam new_els_lp = new_els_lp;
       localparam lg_new_els_lp = `BSG_SAFE_CKOG2(new_els_lp);
       wire [pot_els_lp-1:0] data_li = {{(pot_els_lp-total_els_lp){1'b0}}, data_i};
       logic [new_els_lp-1:0] c0_lo;
       bsg_clkmux #(.els_p(new_els_lp), .harden_p(harden_p), .strength_p(strength_p)) c0
        (.data_i(data_li[0+:new_els_lp])
         ,.sel_i(sel_i[0+:lg_new_els_lp])
         ,.data_o(c0_lo)
         );
       logic [new_els_lp-1:0] c1_lo;
       bsg_clkmux #(.els_p(new_els_lp), .harden_p(harden_p), .strength_p(strength_p)) c1
        (.data_i(data_li[new_els_lp+:new_els_lp])
         ,.sel_i(sel_i[0+:lg_new_els_lp])
         ,.data_o(c1_lo)
         );
       bsg_clkmux #(.width_p(new_width_lp), .harden_p(harden_p), .strength_p(strength_p)) c2
        (.data_i({c1_lo, c0_lo})
         ,.sel_i(sel_i[lg_new_els_lp])
         ,.data_o(data_o)
         );
     end

endmodule

`BSG_ABSTRACT_MODULE(bsg_clkmux)

