`include "bsg_defines.v"

(* KEEP_HIERARCHY = "TRUE" *)
module bsg_mux #(
    parameter `BSG_INV_PARAM(width_p)
  , els_p=1
  , harden_p = 0
  , balanced_p = 0
  , lg_els_lp=`BSG_SAFE_CLOG2(els_p)
)
(
    input  [els_p-1:0][width_p-1:0] data_i
  , input  [lg_els_lp-1:0] sel_i
  , output [width_p-1:0] data_o
);

if ((harden_p == 1) && (balanced_p == 1)) begin : fi
  for (genvar j = 0; j < width_p; j=j+1) begin: rof
    if (els_p == 2) begin : els2
      BUFGMUX_CTRL bufgmux_ctrl (
        .I0(data_i[0][j])
        ,.I1(data_i[1][j])
        ,.O(data_o[j])
        ,.S(sel_i)
      );
    end
    else if (els_p == 4) begin : els4
      logic [1:0][width_p-1:0] data_int;
      BUFGMUX_CTRL bufgmux_ctrl1 (
        .I0(data_i[0][j])
        ,.I1(data_i[1][j])
        ,.O(data_int[0][j])
        ,.S(sel_i[0])
      );
      BUFGMUX_CTRL bufgmux_ctrl2 (
        .I0(data_i[2][j])
        ,.I1(data_i[3][j])
        ,.O(data_int[1][j])
        ,.S(sel_i[0])
      );
      BUFGMUX_CTRL bufgmux_ctrl3 (
        .I0(data_int[0][j])
        ,.I1(data_int[1][j])
        ,.O(data_o[j])
        ,.S(sel_i[1])
      );
    end
  end
  // synopsys translate_off
  if(els_p != 2 && els_p != 4)
    $error("%m error: unsupported els_p for hardened balanced bsg_mux");
  // synopsys translate_on
end
else begin : nofi
  if (els_p == 1) begin
    assign data_o = data_i;
    wire unused = sel_i;
  end
  else begin
    assign data_o = data_i[sel_i];
  end

  // synopsys translate_off
  if(harden_p == 0 && balanced_p == 1)
    $error("%m error: synthesizable implementation of bsg_mux does not support balanced_p");
  // synopsys translate_on
end

endmodule

`BSG_ABSTRACT_MODULE(bsg_mux)
