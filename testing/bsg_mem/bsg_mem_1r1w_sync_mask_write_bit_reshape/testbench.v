
module testbench;

  logic clk;
  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) clock_gen (
    .o(clk)
  );

  logic reset;
  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(4)
    ,.reset_cycles_hi_p(4)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

  localparam skinny_width_lp = 2;
  localparam skinny_els_lp = 4;
  localparam skinny_addr_width_lp = `BSG_SAFE_CLOG2(skinny_els_lp);
  localparam fat_width_lp = 4;
  localparam fat_els_lp = 2;
  localparam fat_addr_width_lp = `BSG_SAFE_CLOG2(fat_els_lp);

  `include "bsg_defines.v"

  logic w_v_li;
  logic [skinny_width_lp-1:0] w_mask_li;
  logic [skinny_addr_width_lp-1:0] w_addr_li;
  logic [skinny_width_lp-1:0] w_data_li;
  logic r_v_li;
  logic [skinny_addr_width_lp-1:0] r_addr_li;
  logic [skinny_width_lp-1:0] r_data_lo;

  logic fat_w_v_lo;
  logic [fat_width_lp-1:0] fat_w_mask_lo;
  logic [fat_addr_width_lp-1:0] fat_w_addr_lo;
  logic [fat_width_lp-1:0] fat_w_data_lo;
  logic fat_r_v_lo;
  logic [fat_addr_width_lp-1:0] fat_r_addr_lo;
  logic [fat_width_lp-1:0] fat_r_data_li;

  logic skinny_w_v_lo;
  logic [skinny_width_lp-1:0] skinny_w_mask_lo;
  logic [skinny_addr_width_lp-1:0] skinny_w_addr_lo;
  logic [skinny_width_lp-1:0] skinny_w_data_lo;
  logic skinny_r_v_lo;
  logic [skinny_addr_width_lp-1:0] skinny_r_addr_lo;
  logic [skinny_width_lp-1:0] skinny_r_data_li;
  bsg_mem_1r1w_sync_mask_write_bit_reshape
   #(.skinny_width_p(skinny_width_lp)
     ,.skinny_els_p(skinny_els_lp)
     ,.fat_width_p(fat_width_lp)
     ,.fat_els_p(fat_els_lp)
     )
   DUT
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.w_v_i(w_v_li)
     ,.w_mask_i(w_mask_li)
     ,.w_addr_i(w_addr_li)
     ,.w_data_i(w_data_li)

     ,.r_v_i(r_v_li)
     ,.r_addr_i(r_addr_li)

     ,.r_data_o(r_data_lo)

     ,.w_v_o(fat_w_v_lo)
     ,.w_mask_o(fat_w_mask_lo)
     ,.w_addr_o(fat_w_addr_lo)
     ,.w_data_o(fat_w_data_lo)

     ,.r_v_o(fat_r_v_lo)
     ,.r_addr_o(fat_r_addr_lo)

     ,.r_data_i(fat_r_data_li)
     );

  bsg_mem_1r1w_sync_mask_write_bit
   #(.width_p(fat_width_lp)
     ,.els_p(fat_els_lp)
     ,.read_write_same_addr_p(1)
     )
   fat_mem
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.w_v_i(fat_w_v_lo)
     ,.w_mask_i(fat_w_mask_lo)
     ,.w_addr_i(fat_w_addr_lo)
     ,.w_data_i(fat_w_data_lo)

     ,.r_v_i(fat_r_v_lo)
     ,.r_addr_i(fat_r_addr_lo)

     ,.r_data_o(fat_r_data_li)
     );

  assign skinny_w_v_lo = w_v_li;
  assign skinny_w_mask_lo = w_mask_li;
  assign skinny_w_addr_lo = w_addr_li;
  assign skinny_w_data_lo = w_data_li;
  assign skinny_r_v_lo = r_v_li;
  assign skinny_r_addr_lo = r_addr_li;
  bsg_mem_1r1w_sync_mask_write_bit
   #(.width_p(skinny_width_lp)
     ,.els_p(skinny_els_lp)
     ,.read_write_same_addr_p(1)
     )
   skinny_mem
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.w_v_i(skinny_w_v_lo)
     ,.w_mask_i(skinny_w_mask_lo)
     ,.w_addr_i(skinny_w_addr_lo)
     ,.w_data_i(skinny_w_data_lo)

     ,.r_v_i(skinny_r_v_lo)
     ,.r_addr_i(skinny_r_addr_lo)

     ,.r_data_o(skinny_r_data_li)
     );

  logic r_v_r;
  bsg_dff
   #(.width_p(1))
   r_v_reg
    (.clk_i(clk)

     ,.data_i(r_v_li)
     ,.data_o(r_v_r)
     );

  initial
    begin
      w_v_li =  '0;
      w_mask_li = '0;
      w_addr_li = '0;
      w_data_li = '0;

      r_v_li = '0;
      r_addr_li = '0;

      @(negedge reset);

      @(posedge clk);
      @(negedge clk);

      for (integer i = 0; i < 10000; i++)
        begin
          w_v_li = $random();
          w_mask_li = $random();
          w_addr_li = $random();
          w_data_li = $random();

          r_v_li = $random();
          r_addr_li = $random();

          @(negedge clk);
          assert ((|skinny_r_data_li === 'X) || (skinny_r_data_li === r_data_lo));
        end

      $finish();
    end

endmodule

