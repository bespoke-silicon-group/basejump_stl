`include "bsg_defines.sv"

module bsg_mem_multiport_latch_write_banked_bypassing_sync
  #(`BSG_INV_PARAM(els_p)
    , `BSG_INV_PARAM(width_p)
    , `BSG_INV_PARAM(num_rs_p)
    , `BSG_INV_PARAM(num_banks_p)
    
    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
    , parameter bank_addr_width_lp=`BSG_SAFE_CLOG2(els_p/num_banks_p)
  )
  (
    input clk_i
    , input reset_i

    , input [num_banks_p-1:0] w_v_i
    , input [num_banks_p-1:0][bank_addr_width_lp-1:0] w_addr_i
    , input [num_banks_p-1:0][width_p-1:0] w_data_i

    // sync read
    , input [num_rs_p-1:0] r_v_i
    , input [num_rs_p-1:0][addr_width_lp-1:0] r_addr_i
    , output logic [num_rs_p-1:0][width_p-1:0] r_data_o
  );

  logic [num_rs_p-1:0][addr_width_lp-1:0] r_addr_r;

  for (genvar i = 0; i < num_rs_p; i++) begin: rs
    bsg_dff_en #(
      .width_p(addr_width_lp)
    ) r_addr_dff (
      .clk_i(clk_i)
      ,.en_i(r_v_i[i])
      ,.data_i(r_addr_i[i])
      ,.data_o(r_addr_r[i])
    );
  end

  bsg_mem_multiport_latch_write_banked_bypassing #(
    .els_p(els_p)
    ,.width_p(width_p)
    ,.num_rs_p(num_rs_p)
    ,.num_banks_p(num_banks_p)
  ) mem (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.w_v_i(w_v_i)
    ,.w_addr_i(w_addr_i)
    ,.w_data_i(w_data_i)
    
    ,.r_addr_i(r_addr_r)
    ,.r_data_o(r_data_o)
  );

endmodule



`BSG_ABSTRACT_MODULE(bsg_mem_multiport_latch_write_banked_bypassing_sync)
