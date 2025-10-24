/**
 *  bsg_mem_1r1w_sync_banked.sv
 *
 *  This module has the same interface/functionality as
 *  bsg_mem_1r1w_sync.
 *
 *  This module can be used for breaking a big SRAM block into
 *  smaller blocks. This might be useful, if the SRAM generator does not
 *  support sizes of SRAM that are too wide or too deep.
 *  It is also useful for power and delay perspective, since only one depth
 *  bank is activated while reading or writing.
 *
 *  If the desired banking is decided by node-specific (e.g. TSMC 28) SRAM 
 *  generator characteristics then the preferred methodology is to invoke this
 *  from the /hard SRAM macro, rather than to instantiate it in the RTL.
 *  However, in some cases, for example, for research infrastructures exploring
 *  a pareto design space, it may be desirable to directly use this interface.
 *
 *  - width_p : width of the total memory
 *  - els_p : depth of the total memory
 *
 *  - num_width_bank_p : Number of banks for the memory's width. width_p has
 *  to be a multiple of this number.
 *  - num_depth_bank_p : Number of banks for the memory's depth. els_p has to
 *  be a multiple of this number.
 *
 */


`include "bsg_defines.sv"

module bsg_mem_1r1w_sync_banked 
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(els_p)
    , parameter read_write_same_addr_p=0
    , parameter latch_last_read_p=0

    , parameter num_width_bank_p=1
    , parameter num_depth_bank_p=1

    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)

    , parameter bank_depth_lp=(els_p/num_depth_bank_p)
    , parameter bank_addr_width_lp=`BSG_SAFE_CLOG2(bank_depth_lp)
    , parameter depth_bank_idx_width_lp=`BSG_SAFE_CLOG2(num_depth_bank_p)
    , parameter bank_width_lp=(width_p/num_width_bank_p)
  )
  (
    input clk_i
    , input reset_i

    , input w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0] w_data_i

    , input r_v_i
    , input [addr_width_lp-1:0] r_addr_i
    , output logic [width_p-1:0] r_data_o
  );


  if (num_depth_bank_p==1) begin: db1

    for (genvar i = 0; i < num_width_bank_p; i++) begin: wb

      bsg_mem_1r1w_sync #(
        .width_p(bank_width_lp)
        ,.els_p(bank_depth_lp)
        ,.latch_last_read_p(latch_last_read_p)
        ,.read_write_same_addr_p(read_write_same_addr_p)
      ) bank (
        .clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.w_v_i(w_v_i)
        ,.w_addr_i(w_addr_i)
        ,.w_data_i(w_data_i[bank_width_lp*i+:bank_width_lp])
        ,.r_v_i(r_v_i)
        ,.r_addr_i(r_addr_i)
        ,.r_data_o(r_data_o[bank_width_lp*i+:bank_width_lp])
      );

    end

  end
  else begin: dbn

    logic [num_depth_bank_p-1:0] bank_r_v_li, bank_w_v_li;
    logic [num_depth_bank_p-1:0][width_p-1:0] bank_r_data_lo;
   
    wire [depth_bank_idx_width_lp-1:0] depth_bank_r_idx_li = r_addr_i[0+:depth_bank_idx_width_lp];
    wire [bank_addr_width_lp-1:0] bank_r_addr_li = r_addr_i[depth_bank_idx_width_lp+:bank_addr_width_lp];

    wire [depth_bank_idx_width_lp-1:0] depth_bank_w_idx_li = w_addr_i[0+:depth_bank_idx_width_lp];
    wire [bank_addr_width_lp-1:0] bank_w_addr_li = w_addr_i[depth_bank_idx_width_lp+:bank_addr_width_lp];

    bsg_decode_with_v #(
      .num_out_p(num_depth_bank_p)
    ) demux_r_v (
      .i(depth_bank_r_idx_li)
      ,.v_i(r_v_i)
      ,.o(bank_r_v_li)
    );

    bsg_decode_with_v #(
      .num_out_p(num_depth_bank_p)
    ) demux_w_v (
      .i(depth_bank_w_idx_li)
      ,.v_i(w_v_i)
      ,.o(bank_w_v_li)
    );
    
    for (genvar i = 0; i < num_width_bank_p; i++) begin: wb
      for (genvar j = 0; j < num_depth_bank_p; j++) begin: db

        bsg_mem_1r1w_sync #(
          .width_p(bank_width_lp)
          ,.els_p(bank_depth_lp)
          ,.read_write_same_addr_p(read_write_same_addr_p)
          ,.latch_last_read_p(latch_last_read_p)
        ) bank (
          .clk_i(clk_i)
          ,.reset_i(reset_i)

          ,.w_v_i(bank_w_v_li[j])
          ,.w_addr_i(bank_w_addr_li)
          ,.w_data_i(w_data_i[i*bank_width_lp+:bank_width_lp])
          ,.r_v_i(bank_r_v_li[j])
          ,.r_addr_i(bank_r_addr_li)
          ,.r_data_o(bank_r_data_lo[j][i*bank_width_lp+:bank_width_lp])
        );

      end
    end

    logic [depth_bank_idx_width_lp-1:0] depth_bank_r_idx_r;

    bsg_dff_en #(
      .width_p(depth_bank_idx_width_lp)
    ) depth_bank_idx_dff (
      .clk_i(clk_i)
      ,.en_i(r_v_i)
      ,.data_i(depth_bank_r_idx_li)
      ,.data_o(depth_bank_r_idx_r)
    );

    bsg_mux #(
      .els_p(num_depth_bank_p)
      ,.width_p(width_p)
    ) data_out_mux (
      .data_i(bank_r_data_lo)
      ,.sel_i(depth_bank_r_idx_r)
      ,.data_o(r_data_o)
    );

  end


`ifndef BSG_HIDE_FROM_SYNTHESIS

  initial begin
    assert(els_p % num_depth_bank_p == 0)
      else $error("[BSG_ERROR] num_depth_bank_p does not divide even with els_p. %m");

    assert(width_p % num_width_bank_p == 0)
      else $error("[BSG_ERROR] num_width_bank_p does not divide even with width_p. %m");
  end
  
`endif
  


endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1r1w_sync_banked)
