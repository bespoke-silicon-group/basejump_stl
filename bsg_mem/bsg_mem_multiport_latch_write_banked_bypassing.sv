/**
 *    bsg_mem_multiport_latch_write_banked_bypassing.sv
 *
 *    Data latches are transparent when the clock is low, and the write data can be bypassed to the read outputs.
 *    Write enable signal needs to arrive before the negedge of the clock. 
 */


`include "bsg_defines.sv"


module bsg_mem_multiport_latch_write_banked_bypassing
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

    // async read
    , input [num_rs_p-1:0][addr_width_lp-1:0] r_addr_i
    , output logic [num_rs_p-1:0][width_p-1:0] r_data_o
  );


  // parameter checking
`ifndef BSG_HIDE_FROM_SYNTHESIS
  initial begin
    assert((els_p%num_banks_p) == 0) else $error("els_p has to be multiples of num_banks_p.");
  end
`endif


  wire unused = reset_i;


  // write ports
  localparam bank_els_lp = (els_p/num_banks_p);

  logic [num_banks_p-1:0][bank_els_lp-1:0] w_v_onehot;
  logic [num_banks_p-1:0][bank_els_lp-1:0] mem_we_clk;

  for (genvar i = 0; i < num_banks_p; i++) begin: ba
    // write enable decoder
    bsg_decode_with_v #(
      .num_out_p(bank_els_lp)
    ) dv0 (
      .i(w_addr_i[i])
      ,.v_i(w_v_i[i])
      ,.o(w_v_onehot[i])
    );

    // write icg
    for (genvar j = 0; j < bank_els_lp; j++) begin: we_icg
      bsg_icg_neg icg0 (
        .clk_i(clk_i)
        ,.en_i(w_v_onehot[i][j])
        ,.clk_o(mem_we_clk[i][j])
      );
    end
  end


  // latch file
  logic [els_p-1:0][width_p-1:0] mem_r; 

  for (genvar i = 0; i < els_p; i++) begin: x
    // address is striped with banks.
    localparam bank_id_lp = (i%num_banks_p);
    localparam bank_addr_lp = (i/num_banks_p);

    wire clk_neg = ~mem_we_clk[bank_id_lp][bank_addr_lp];

    bsg_dlatch #(.width_p(width_p), .i_know_this_is_a_bad_idea_p(1'b1)) lat0
    ( .clk_i(clk_neg)
     ,.data_i(w_data_i[bank_id_lp])
     ,.data_o(mem_r[i])
    );
    
    //for (genvar j = 0; j < width_p; j++) begin: b
    //  bsg_latch lat0 (
    //    .clk_i(clk_neg)
    //    ,.data_i(w_data_i[bank_id_lp][j])
    //    ,.data_o(mem_r[i][j])
    //  );
    end
  end


  // read ports
  for (genvar i = 0; i < num_rs_p; i++) begin: rs
    bsg_mux #(
      .width_p(width_p)
      ,.els_p(els_p)
    ) rmux0 (
      .data_i(mem_r)
      ,.sel_i(r_addr_i[i])
      ,.data_o(r_data_o[i])
    );
  end


endmodule


`BSG_ABSTRACT_MODULE(bsg_mem_multiport_latch_write_banked_bypassing)
