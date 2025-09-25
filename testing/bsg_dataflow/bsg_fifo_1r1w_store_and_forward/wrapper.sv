
`default_nettype none

module wrapper();

  // change parameters here:
  parameter width_p = 32;
  parameter lg_size_p = 2;
  parameter harden_p = 1;

  bit                 clk_i;
  logic               reset_lo;

  logic               commit_v_lo;
  logic               commit_drop_lo;

  logic [width_p-1:0] data_lo;
  logic               v_lo;
  logic               ready_li;

  logic [width_p-1:0] data_li;
  logic               v_li;
  logic               yumi_lo;


  always #1 clk_i = ~clk_i;

  initial begin
      $vcdplusfile("dump.vpd");
      $vcdpluson();
  end

  testbench #(
     .width_p(width_p)
    ,.lg_size_p(lg_size_p)
  ) testbench (
     .clk_i(clk_i)
    ,.reset_o(reset_lo)

    ,.commit_v_o(commit_v_lo)
    ,.commit_drop_o(commit_drop_lo)
 
    ,.data_o(data_lo)
    ,.v_o(v_lo)
    ,.ready_i(ready_li)
 
    ,.data_i(data_li)
    ,.v_i(v_li)
    ,.yumi_o(yumi_lo)
  );

  bsg_fifo_1r1w_store_and_forward #(
     .width_p(width_p)
    ,.lg_size_p(lg_size_p)
    ,.harden_p(harden_p)
  ) dut (
     .clk_i(clk_i)
    ,.reset_i(reset_lo)

    ,.commit_v_i(commit_v_lo)
    ,.commit_drop_i(commit_drop_lo)

    ,.data_i(data_lo)
    ,.v_i(v_lo)
    ,.ready_o(ready_li)

    ,.data_o(data_li)
    ,.v_o(v_li)
    ,.yumi_i(yumi_lo)
  );

if (harden_p == 0) begin
  bind bsg_fifo_1r1w_store_and_forward cov #(
     .lg_size_p(lg_size_p)
  ) cov_inst (
     .*
    ,.r_incr_i(unhardened.fifo.ft.r_incr_i)
    ,.r_rewind_i(unhardened.fifo.ft.r_rewind_i)
    ,.r_forward_i(unhardened.fifo.ft.r_forward_i)
    ,.r_clear_i(unhardened.fifo.ft.r_clear_i)
                                                
    ,.w_incr_i(unhardened.fifo.ft.w_incr_i)
    ,.w_rewind_i(unhardened.fifo.ft.w_rewind_i)
    ,.w_forward_i(unhardened.fifo.ft.w_forward_i)
    ,.w_clear_i(unhardened.fifo.ft.w_clear_i)

    ,.rptr_r(unhardened.fifo.ft.rptr_r)
    ,.wptr_r(unhardened.fifo.ft.wptr_r)
    ,.rcptr_r(unhardened.fifo.ft.rcptr_r)
    ,.wcptr_r(unhardened.fifo.ft.wcptr_r)
    ,.full(unhardened.fifo.full)
    ,.empty(unhardened.fifo.empty)
 );
end else begin
  bind bsg_fifo_1r1w_store_and_forward cov #(
     .lg_size_p(lg_size_p)
  ) cov_inst (
     .*
    ,.r_incr_i(hardened.fifo.ft.r_incr_i)
    ,.r_rewind_i(hardened.fifo.ft.r_rewind_i)
    ,.r_forward_i(hardened.fifo.ft.r_forward_i)
    ,.r_clear_i(hardened.fifo.ft.r_clear_i)
                                                
    ,.w_incr_i(hardened.fifo.ft.w_incr_i)
    ,.w_rewind_i(hardened.fifo.ft.w_rewind_i)
    ,.w_forward_i(hardened.fifo.ft.w_forward_i)
    ,.w_clear_i(hardened.fifo.ft.w_clear_i)

    ,.rptr_r(hardened.fifo.ft.rptr_r)
    ,.wptr_r(hardened.fifo.ft.wptr_r)
    ,.rcptr_r(hardened.fifo.ft.rcptr_r)
    ,.wcptr_r(hardened.fifo.ft.wcptr_r)
    ,.full(hardened.fifo.full)
    ,.empty(hardened.fifo.empty)
 );
end
endmodule
