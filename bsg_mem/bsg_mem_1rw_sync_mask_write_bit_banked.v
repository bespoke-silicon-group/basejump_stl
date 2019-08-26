/**
 *  bsg_mem_1rw_sync_mask_write_bit_banked.v
 *
 */


module bsg_mem_1rw_sync_mask_write_bit_banked
  #(parameter width_p="inv"
    , parameter els_p="inv"
    , parameter latch_last_read_p=0

    // bank parameters
    , parameter num_width_bank_p=1    // number of width banks
    , parameter num_depth_bank_p=1    // number of depth banks

    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)

    , parameter bank_depth_lp=(els_p/num_depth_bank_p)
    , parameter bank_addr_width_lp=`BSG_SAFE_CLOG2(bank_depth_lp)
  
    , parameter depth_bank_idx_width_lp=`BSG_SAFE_CLOG2(num_depth_bank_p)
    , parameter depth_bank_start_idx_p=0 // pick which portion of addr_i to select depth_bank. By default, LSB.

    , parameter bank_width_lp=(width_p/num_width_bank_p)
  )
  (
    input clk_i
    , input reset_i
    
    , input v_i
    , input w_i

    , input [addr_width_lp-1:0] addr_i
    , input [width_p-1:0] data_i
    , input [width_p-1:0] w_mask_i
    , output [width_p-1:0] data_o
  );


  if (num_depth_bank_p==1) begin: db1

    for (genvar i = 0; i < num_width_bank_p; i++) begin: wb

      bsg_mem_1rw_sync_mask_write_bit #(
        .width_p(bank_width_lp)
        ,.els_p(bank_depth_lp)
        ,.latch_last_read_p(latch_last_read_p)
      ) bank (
        .clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.v_i(v_i)
        ,.w_i(w_i)
        ,.addr_i(addr_i)
        ,.data_i(data_i[bank_width_lp*i+:bank_width_lp])
        ,.w_mask_i(w_mask_i[bank_width_lp*i+:bank_width_lp])
        ,.data_o(data_o[bank_width_lp*i+:bank_width_lp])
      );

    end

  end
  else begin: dbn

    logic [depth_bank_idx_width_lp-1:0] depth_bank_idx;
    logic [num_depth_bank_p-1:0] bank_v_li;
    logic [bank_addr_width_lp-1:0] bank_addr_li;
    logic [num_depth_bank_p-1:0][width_p-1:0] bank_data_lo;
   
    assign depth_bank_idx = addr_i[depth_bank_start_idx_p+:depth_bank_idx_width_lp];
    
    if (depth_bank_start_idx_p == 0) begin // LSB

      assign bank_addr_li = addr_i[depth_bank_idx_width_lp+:bank_addr_width_lp];

    end
    else if (depth_bank_start_idx_p == (addr_width_lp-depth_bank_idx_width_lp)) begin // MSB

      assign bank_addr_li = addr_i[0+:bank_addr_width_lp];

    end
    else begin // in the middle

      assign bank_addr_li =
        {addr_i[addr_width_lp-1:depth_bank_start_idx_p+depth_bank_idx_width_lp],
         addr_i[depth_bank_start_idx_p-1:0]};

    end

    bsg_decode_with_v #(
      .num_out_p(num_depth_bank_p)
    ) demux_v (
      .i(depth_bank_idx)
      ,.v_i(v_i)
      ,.o(bank_v_li)
    );
    
    for (genvar i = 0; i < num_width_bank_p; i++) begin: wb
      for (genvar j = 0; j < num_depth_bank_p; j++) begin: db

        bsg_mem_1rw_sync_mask_write_bit #(
          .width_p(bank_width_lp)
          ,.els_p(bank_depth_lp)
          ,.latch_last_read_p(latch_last_read_p)
        ) bank (
          .clk_i(clk_i)
          ,.reset_i(reset_i)
          ,.v_i(bank_v_li[j])
          ,.w_i(w_i)
          ,.addr_i(bank_addr_li)
          ,.data_i(data_i[i*bank_width_lp+:bank_width_lp])
          ,.w_mask_i(w_mask_i[i*bank_width_lp+:bank_width_lp])
          ,.data_o(bank_data_lo[j][i*bank_width_lp+:bank_width_lp])
        );

      end
    end

    logic [depth_bank_idx_width_lp-1:0] depth_bank_idx_r;

    bsg_dff_reset_en #(
      .width_p(depth_bank_idx_width_lp)
    ) depth_bank_idx_dff (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.en_i(v_i & ~w_i)
      ,.data_i(depth_bank_idx)
      ,.data_o(depth_bank_idx_r)
    );

    bsg_mux #(
      .els_p(num_depth_bank_p)
      ,.width_p(width_p)
    ) data_out_mux (
      .data_i(bank_data_lo)
      ,.sel_i(depth_bank_idx_r)
      ,.data_o(data_o)
    );

  end


  // synopsys translate_off

  initial begin
    assert(els_p % num_depth_bank_p == 0)
      else $error("[BSG_ERROR] num_depth_bank_p does not divide even with els_p. %m");

    assert(width_p % num_width_bank_p == 0)
      else $error("[BSG_ERROR] num_width_bank_p does not divide even with width_p. %m");

    // this assertion will not even fire,
    // because the compilation will fail before simulation begins.
    assert((depth_bank_start_idx_p>=0) & ((depth_bank_start_idx_p+depth_bank_idx_width_lp)<=addr_width_lp))
      else $error("[BSG_ERROR] depth_bank_start_idx_p out of range. %m");
  end
  
  // synopsys translate_on


endmodule
