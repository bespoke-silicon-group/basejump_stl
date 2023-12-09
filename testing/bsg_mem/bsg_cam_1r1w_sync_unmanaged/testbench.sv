
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

  localparam els_lp = 4;
  localparam lg_els_lp = `BSG_SAFE_CLOG2(els_lp);
  localparam tag_width_lp = 8;
  localparam data_width_lp = 16;

  logic [els_lp-1:0] w_v_li;
  logic w_set_not_clear_li;
  logic [tag_width_lp-1:0] w_tag_li;
  logic [data_width_lp-1:0] w_data_li;
  logic [els_lp-1:0] w_empty_lo;

  logic r_v_li;
  logic [tag_width_lp-1:0] r_tag_li;
  logic [data_width_lp-1:0] r_data_lo;
  logic r_v_lo;
  bsg_cam_1r1w_sync_unmanaged
   #(.els_p(els_lp)
     ,.tag_width_p(tag_width_lp)
     ,.data_width_p(data_width_lp)
     )
   DUT
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.w_v_i(w_v_li)
     ,.w_set_not_clear_i(w_set_not_clear_li)
     ,.w_tag_i(w_tag_li)
     ,.w_data_i(w_data_li)

     ,.w_empty_o(w_empty_lo)

     ,.r_v_i(r_v_li)
     ,.r_tag_i(r_tag_li)

     ,.r_data_o(r_data_lo)
     ,.r_v_o(r_v_lo)
     );

  initial
    begin
      w_v_li = '0;
      w_set_not_clear_li = '0;
      w_tag_li = '0;
      w_data_li = '0;

      r_v_li = '0;
      r_tag_li = '0;

      @(negedge reset);

      @(posedge clk);

      @(negedge clk);
      $display("Checking initial not empty");
      assert (w_empty_lo == 4'b1111);

      @(negedge clk);
      $display("Writing data 1");
      w_v_li = 4'b0001;
      w_set_not_clear_li = 1'b1;
      w_tag_li = 8'h00;
      w_data_li = 16'hdead;
      @(negedge clk);
      $display("Writing data 2");
      w_v_li = 4'b0010;
      w_set_not_clear_li = 1'b1;
      w_tag_li = 8'h11;
      w_data_li = 16'hbeef;

      @(negedge clk);
      w_v_li = '0;
      
      @(negedge clk);
      $display("Checking not empty");
      assert (w_empty_lo == 4'b1100);

      @(posedge clk)
      $display("Checking read data 1");
      r_v_li = 1'b1;
      r_tag_li = 8'h00;
      @(posedge clk);
      @(negedge clk);
      assert (r_v_lo);
      assert (r_data_lo == 16'hdead);
    
      @(posedge clk);
      $display("Checking read data 2");
      r_v_li = 1'b1;
      r_tag_li = 8'h11;
      @(posedge clk);
      @(negedge clk);
      assert (r_v_lo);
      assert (r_data_lo == 16'hbeef);

      @(posedge clk);
      r_v_li = 1'b0;
      
      @(posedge clk);
      $display("Testing invalidate");
      w_v_li = 4'b0001;
      w_set_not_clear_li = 1'b0;
      w_tag_li = 'X;
      w_data_li = 'X;
      @(posedge clk);
      w_v_li = 1'b0;
      r_v_li = 1'b1;
      r_tag_li = 8'h00;
      @(negedge clk);
      assert (~r_v_lo);
      assert (w_empty_lo == 4'b1101);

      $finish();
    end

endmodule

