`include "bsg_defines.v"


module bsg_mem_multiport_write_banked_bypassing
  #(`BSG_INV_PARAM(els_p)
    , `BSG_INV_PARAM(width_p)
    , `BSG_INV_PARAM(num_rs_p)
    , `BSG_INV_PARAM(num_banks_p)
    , parameter latch_not_ff_p=0   
    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
    , parameter bank_addr_width_lp=`BSG_SAFE_CLOG2(els_p/num_banks_p)
  )
  (
    input clk_i
    , input reset_i

    , input [num_banks_p-1:0] w_v_i
    , input [num_banks_p-1:0][bank_addr_width_lp-1:0] w_addr_i
    , input [num_banks_p-1:0][width_p-1:0] w_data_i

    // async read
    , input [num_rs_p-1:0][addr_width_lp-1:0] r_addr_i
    , output logic [num_rs_p-1:0][width_p-1:0] r_data_o
  );

  if (latch_not_ff_p) begin: latch
    bsg_mem_multiport_write_banked_bypassing_latch #(
      .els_p(els_p)
      ,.width_p(width_p)
      ,.num_rs_p(num_rs_p)
      ,.num_banks_p(num_banks_p)
    ) lf (.*);
  end
  else begin: ff
    bsg_mem_multiport_write_banked_bypassing_ff #(
      .els_p(els_p)
      ,.width_p(width_p)
      ,.num_rs_p(num_rs_p)
      ,.num_banks_p(num_banks_p)
    ) rf (.*);
  end


endmodule


`BSG_ABSTRACT_MODULE(bsg_mem_multiport_write_banked_bypassing)
