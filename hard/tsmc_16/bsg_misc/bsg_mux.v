module bsg_mux #(
  parameter width_p    = "inv",
  parameter els_p      = "inv",
  parameter harden_p   = 1,
  parameter balanced_p = 0,
  parameter lg_els_lp  = `BSG_SAFE_CLOG2(els_p)
) (
  input  [els_p-1:0][width_p-1:0] data_i,
  input  [lg_els_lp-1:0]          sel_i,
  output [width_p-1:0]            data_o
);

    if (harden_p && balanced_p && (els_p==2) && (width_p==1))
      begin: macro

        logic lo;

        // This cell has great edge balancing characteristics
        // on pins B and D if A=1 and C=1
        MXIT4_X2N_A7P5PP96PTS_C16 mxit4 (
          .A(1'b1),
          .B(data_i[0]),
          .C(1'b1),
          .D(data_i[1]),
          .S0(1'b1),
          .S1(sel_i[0]),
          .Y(lo)
        );

        INV_X16N_A7P5PP96PTS_C16 inv (
          .A(lo),
          .Y(data_o)
        );
        
      end: macro
    else
      begin: notmacro
         initial assert (harden_p==0) else $error("## %m: warning, failed to harden bsg_mux width=%d, els=%d, balanced=%d",width_p, els_p, balanced_p);
         assign data_o = data_i[sel_i];
      end: notmacro

endmodule

