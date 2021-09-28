/**
 *    bsg_mem_multiport_latch_banked.v
 *
 */


`include "bsg_defines.v"


module bsg_mem_multiport_latch_banked 
  #(`BSG_INV_PARAM(width_p)
    , `BSG_INV_PARAM(els_p)
    , `BSG_INV_PARAM(num_rd_p)
    , `BSG_INV_PARAM(num_rs_p)
    , `BSG_INV_PARAM(num_banks_p)
    , parameter async_read_p = 0
    , parameter x0_tied_to_zero_p = 0

    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
    , parameter bank_addr_width_lp = `BSG_SAFE_CLOG2(els_p/num_banks_p)
  )
  (
    input clk_i
    , input reset_i

    , input global_w_v_i
    , input [addr_width_lp-1:0] global_w_addr_i
    , input [width_p-1:0] global_w_data_i

    , input [num_banks_p-1:0] bank_w_v_i
    , input [num_banks_p-1:0][bank_addr_width_lp-1:0] bank_w_addr_i
    , input [num_banks_p-1:0][width_p-1:0] bank_w_data_i

    , input [num_rs_p-1:0] r_v_i
    , input [num_rs_p-1:0][addr_width_lp-1:0] r_addr_i
    , output logic [num_rs_p-1:0][width_p-1:0] r_data_o
  );

  // parameter checking
  // synopsys translate_off
  initial begin
    assert((els_p%num_banks_p) == 0) else $error("els_p should be multiples of num_banks_p.");
  end
  // synopsys translate_off

  
  // Instantiate banks.
  localparam lg_num_banks_lp = `BSG_SAFE_CLOG2(num_banks_p);

  logic [num_banks_p-1:0] bank_w_v_li;
  logic [num_banks_p-1:0][bank_addr_width_lp-1:0] bank_w_addr_li;
  logic [num_banks_p-1:0][width_p-1:0] bank_w_data_li;

  logic [num_banks_p-1:0][num_rs_p-1:0] bank_r_v_li;
  logic [num_banks_p-1:0][num_rs_p-1:0][bank_addr_width_lp-1:0] bank_r_addr_li;
  logic [num_banks_p-1:0][num_rs_p-1:0][width_p-1:0] bank_r_data_lo;

  for (genvar i = 0; i < num_banks_p; i++) begin: ba
    bsg_mem_multiport_latch #(
      .width_p(width_p)
      ,.els_p(els_p/num_banks_p)
      ,.num_rs_p(num_rs_p)

      ,.x0_tied_to_zero_p(((i==0) && x0_tied_to_zero_p) ? 1 : 0)
      ,.async_read_p(async_read_p)
    ) bank (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.w_v_i(bank_w_v_li[i])
      ,.w_addr_i(bank_w_addr_li[i])
      ,.w_data_i(bank_w_data_li[i])

      ,.r_v_i(bank_r_v_li[i])
      ,.r_addr_i(bank_r_addr_li[i])
      ,.r_data_o(bank_r_data_lo[i])
    );

    for (genvar j = 0; j < num_rs_p; j++) begin
      assign bank_r_addr_li[i][j] = r_addr_i[j][0+:bank_addr_width_lp];
    end
  end


  // connecting read ports
  logic [num_rs_p-1:0][num_banks_p-1:0] r_bank_en;
  logic [num_rs_p-1:0][lg_num_banks_lp-1:0] rmux_sel;
  logic [num_rs_p-1:0][num_banks_p-1:0][width_p-1:0] rmux_data_li;

  for (genvar i = 0; i < num_rs_p; i++) begin: rm
    bsg_decode_with_v #(
      .num_out_p(num_banks_p)
    ) dv (
      .i(r_addr_i[i][bank_addr_width_lp+:lg_num_banks_lp])
      ,.v_i(r_v_i[i])
      ,.o(r_bank_en[i])
    );

    bsg_mux #(
      .els_p(num_banks_p)
      ,.width_p(width_p)
    ) rmux (
      .data_i(rmux_data_li[i])
      ,.sel_i(rmux_sel[i])
      ,.data_o(r_data_o[i])
    );  
    
    for (genvar j = 0; j < num_banks_p; j++) begin
      assign rmux_data_li[i][j] = bank_r_data_lo[j][i];
    end

    if (async_read_p) begin: asyncr
      assign rmux_sel[i] = r_addr_i[i][bank_addr_width_lp+:lg_num_banks_lp];
    end
    else begin: syncr
      bsg_dff_en #(
        .width_p(lg_num_banks_lp)
      ) rmux_sel_dff (
        .clk_i(clk_i)
        ,.en_i(r_v_i[i])
        ,.data_i(r_addr_i[i][bank_addr_width_lp+:lg_num_banks_lp])
        ,.data_o(rmux_sel[i])
      );
    end
  end

  bsg_transpose #(
    .width_p(num_banks_p)
    ,.els_p(num_rs_p)
  ) r_bank_sel_tp (
    .i(r_bank_en)
    ,.o(bank_r_v_li)
  );



  // connecting write ports
  logic [num_banks_p-1:0] global_w_v_decoded;

  bsg_decode_with_v #(
    .num_out_p(num_banks_p)
  ) wdv (
    .i(global_w_addr_i[bank_addr_width_lp+:lg_num_banks_lp])
    ,.v_i(global_w_v_i)
    ,.o(global_w_v_decoded)
  );

  for (genvar i = 0; i < num_banks_p; i++) begin: wb
    bsg_mux_one_hot #(
      .width_p(width_p)
      ,.els_p(2)
    ) wdata_mux (
      .data_i({bank_w_data_i[i], global_w_data_i})
      ,.sel_one_hot_i({bank_w_v_i[i], global_w_v_decoded[i]})
      ,.data_o(bank_w_data_li[i])
    );

    bsg_mux_one_hot #(
      .width_p(bank_addr_width_lp)
      ,.els_p(2)
    ) waddr_mux (
      .data_i({bank_w_addr_i[i], global_w_addr_i[0+:bank_addr_width_lp]})
      ,.sel_one_hot_i({bank_w_v_i[i], global_w_v_decoded[i]})
      ,.data_o(bank_w_addr_li[i])
    );
   
    assign bank_w_v_li[i] = bank_w_v_i[i] | global_w_v_decoded[i];
  end 


  // synopsys translate_off
  always_ff @ (negedge clk_i) begin
    if (~reset_i) begin
      for (integer i = 0; i < num_banks_p; i++) begin
        assert(~(bank_w_v_i[i] & global_w_v_decoded[i])) else $error("Bank write conflict. i=%d", i);
      end
    end
  end
  // synopsys translate_on



endmodule


`BSG_ABSTRACT_MODULE(bsg_mem_multiport_latch_banked)
