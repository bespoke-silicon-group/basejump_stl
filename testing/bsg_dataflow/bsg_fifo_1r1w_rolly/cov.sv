
`default_nettype none

`include "bsg_defines.v"

program cov
 #(parameter `BSG_INV_PARAM(lg_size_p)
  )

  (input clk_i
  ,input reset_i

  // interface signals
  ,input v_i
  ,input yumi_i

  // control signals
  ,input r_incr_i
  ,input r_rewind_i
  ,input r_forward_i
  ,input r_clear_i

  ,input w_incr_i
  ,input w_rewind_i
  ,input w_forward_i
  ,input w_clear_i

  // internal signals
  ,input [lg_size_p+1-1:0] rptr_r
  ,input [lg_size_p+1-1:0] wptr_r
  ,input [lg_size_p+1-1:0] rcptr_r
  ,input [lg_size_p+1-1:0] wcptr_r
  ,input full
  ,input empty

  ,input ready_o
  );

  clocking cb @(posedge clk_i);
    input reset_i;

    input v_i;
    input yumi_i;

    input r_incr_i;
    input r_rewind_i;
    input r_forward_i;
    input r_clear_i;
    
    input w_incr_i;
    input w_rewind_i;
    input w_forward_i;
    input w_clear_i;

    input rptr_r;
    input wptr_r;
    input rcptr_r;
    input wcptr_r;
    input full;
    input empty;
    input ready_o;
  endclocking

  function automatic bit check_ptrs_helper (
      int unsigned front_ptr
    , int unsigned back_ptr
    , ref bit has_wrapped
    , int unsigned lg_size
  );
    int unsigned front_ptr_msb = (front_ptr >> lg_size);
    int unsigned back_ptr_msb = (back_ptr >> lg_size);
    int unsigned front_ptr_main = (front_ptr % (1 << lg_size));
    int unsigned back_ptr_main = (back_ptr % (1 << lg_size));
    if(front_ptr_msb != back_ptr_msb) begin
      if(front_ptr_main < back_ptr_main)
        return 1'b0;
      if(has_wrapped) begin
        return 1'b0;
      end else begin
        has_wrapped = 1'b1;
        return 1'b1;
      end
    end else begin
      return front_ptr_main <= back_ptr_main;
    end

  endfunction

  // true if valid
  function automatic bit check_ptrs (
      int unsigned wptr
    , int unsigned wcptr
    , int unsigned rptr
    , int unsigned rcptr
    , int unsigned lg_size
  );
    bit has_wrapped = 0;
    assert(wptr < 2 * (1 << lg_size));
    assert(wcptr < 2 * (1 << lg_size));
    assert(rptr < 2 * (1 << lg_size));
    assert(rcptr < 2 * (1 << lg_size));
    if(!check_ptrs_helper(rcptr, rptr, has_wrapped, lg_size))
      return 0;
    if(!check_ptrs_helper(rptr, wcptr, has_wrapped, lg_size))
      return 0;
    if(!check_ptrs_helper(wcptr, wptr, has_wrapped, lg_size))
      return 0;
    if(has_wrapped) begin
      return (wptr % (1 << lg_size)) <= (rcptr % (1 << lg_size));
    end
    return 1;
  endfunction


  covergroup cg @(cb iff ~cb.reset_i);
    cp_v:    coverpoint cb.v_i;
    cp_yumi: coverpoint cb.yumi_i;

    cp_rptr:  coverpoint cb.rptr_r;
    cp_wptr:  coverpoint cb.wptr_r;
    cp_rcptr: coverpoint cb.rcptr_r;
    cp_wcptr: coverpoint cb.wcptr_r;

    cp_r_incr:   coverpoint cb.r_incr_i;
    cp_r_rewind: coverpoint cb.r_rewind_i;
    // wired to 0
    cp_r_forward: coverpoint cb.r_forward_i {illegal_bins ilg = {1};}
    // wired to 0
    cp_r_clear: coverpoint cb.r_clear_i {illegal_bins ilg = {1};}

    // wired to 0
    cp_w_incr: coverpoint cb.w_incr_i {illegal_bins ilg = {1};}
    // wired to 0
    cp_w_rewind: coverpoint cb.w_rewind_i {illegal_bins ilg = {1};}
    // wired to 1
    cp_w_forward: coverpoint cb.w_forward_i {illegal_bins ilg = {0};}
    cp_w_clear: coverpoint cb.w_clear_i;

    cross_all: cross cp_v, cp_yumi
        , cp_rptr, cp_wptr, cp_rcptr, cp_wcptr
        , cp_r_incr, cp_r_rewind, cp_r_forward, cp_r_clear
        , cp_w_incr, cp_w_rewind, cp_w_forward, cp_w_clear {
      illegal_bins bins_0 = cross_all with (
         // remove all invalid combinations
         (~check_ptrs(cp_wptr, cp_wcptr, cp_rptr, cp_rcptr, lg_size_p)));
      illegal_bins bins_1 = cross_all with (
         // yumi == 1'b0 when empty
         ((cp_rptr == cp_wcptr) && cp_yumi));
      illegal_bins bins_2 = cross_all with (
         // This illegal case would allow rcptr to go past rptr.
         (cp_r_incr && (cp_rptr == cp_rcptr) && ((cp_yumi == 1'b0) || cp_r_rewind))
      );
      // Since w_forward_i is wired to 1, wptr == wcptr
      illegal_bins bins_3 = cross_all with (
         (cp_wptr != cp_wcptr)
      );
      illegal_bins bins_4 = cross_all with (
         // yumi == 1'b0 when r_rewind_i is 1
         ((cp_r_rewind && cp_yumi))
      );
    }
    endgroup

  // create cover groups
  cg cg_inst = new;

  initial begin
    forever begin
        for(int i = 0;i < 100000;i++) begin
          @(cb);
        end
        $display("Functional coverage is %f%%", cg_inst.cross_all.get_coverage());
    end
  end

  // print coverages when simulation is done
  final begin
    $display("");
    $display("Instance: %m");
    $display("---------------------- Functional Coverage Results ----------------------");
    $display("Cross_all coverage is %f%%", cg_inst.cross_all.get_coverage());
    $display("Functional coverage is %f%%", cg_inst.get_coverage());
    $display("-------------------------------------------------------------------------");
    $display("");
  end

endprogram
