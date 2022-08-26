
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

  logic v_li, w_li;
  logic [skinny_width_lp-1:0] w_mask_li;
  logic [skinny_addr_width_lp-1:0] addr_li;
  logic [skinny_width_lp-1:0] data_li;
  logic [skinny_width_lp-1:0] data_lo;

  logic skinny_v_li, skinny_w_li;
  logic [skinny_width_lp-1:0] skinny_w_mask_li;
  logic [skinny_addr_width_lp-1:0] skinny_addr_li;
  logic [skinny_width_lp-1:0] skinny_data_li, skinny_data_lo;
  bsg_mem_1rw_sync_mask_write_bit_reshape
   #(.skinny_width_p(skinny_width_lp)
     ,.skinny_els_p(skinny_els_lp)
     ,.fat_width_p(fat_width_lp)
     ,.fat_els_p(fat_els_lp)
     )
   DUT
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.v_i(v_li)
     ,.w_i(w_li)
     ,.w_mask_i(w_mask_li)
     ,.addr_i(addr_li)
     ,.data_i(data_li)

     ,.data_o(data_lo)
     );

  assign skinny_v_li = v_li;
  assign skinny_w_li = w_li;
  assign skinny_w_mask_li = w_mask_li;
  assign skinny_addr_li = addr_li;
  assign skinny_data_li = data_li;
  bsg_mem_1rw_sync_mask_write_bit
   #(.width_p(skinny_width_lp)
     ,.els_p(skinny_els_lp)
     )
   skinny_mem
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.v_i(skinny_v_li)
     ,.w_i(skinny_w_li)
     ,.w_mask_i(skinny_w_mask_li)
     ,.addr_i(skinny_addr_li)
     ,.data_i(skinny_data_li)

     ,.data_o(skinny_data_lo)
     );

  initial
    begin
      v_li = '0;
      w_li = '0;
      w_mask_li = '0;
      addr_li = '0;
      data_li = '0;

      @(negedge reset);

      @(posedge clk);
      @(negedge clk);

      for (integer i = 0; i < 100000; i++)
        begin
          v_li = $random();
          w_li = $random();
          w_mask_li = $random();
          addr_li = $random();
          data_li = $random();

          @(negedge clk);
          assert ((|skinny_data_lo === 'X) || (skinny_data_lo === data_lo));
        end

      $finish();
    end

endmodule

