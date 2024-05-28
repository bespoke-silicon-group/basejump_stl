//
// Davis Sauer   05/2024
//
// This module defines functional coverages of module bsg_fifo_1rw_large
//
//

`include "bsg_defines.sv"
module bsg_fifo_1rw_large_cov

 #(parameter els_p = "inv"
  ,localparam ptr_width_lp = `BSG_SAFE_CLOG2(els_p)
  )

  (input clk_i
  ,input reset_i

  // interface signals
  ,input v_i
  ,input enq_not_deq_i

  // internal registers
  ,input [ptr_width_lp-1:0] rd_ptr  // registered in sub-module bsg_circular_ptr
  ,input [ptr_width_lp-1:0] wr_ptr  // registered in sub-module bsg_circular_ptr
  ,input full_o  // not a register
  ,input empty_o // not a register
  ,input last_op_is_read_r
  );

  // reset
  covergroup cg_reset @(negedge clk_i);
    coverpoint reset_i;
  endgroup

  // Partitioning covergroup into smaller ones
  // empty
  covergroup cg_empty @ (negedge clk_i iff ~reset_i & empty_o & ~full_o);

    cp_v: coverpoint v_i;
    // cannot deque when empty
    cp_rptr: coverpoint rd_ptr;
    cp_wptr: coverpoint wr_ptr;
    cp_loir: coverpoint last_op_is_read_r {illegal_bins ig = {0};}  // resets to 1, and then only possible to read from cp_normal to get to cp_empty

    cross_all: cross cp_v, cp_rptr, cp_wptr, cp_loir {
      // by definition, fifo empty means r/w pointers are the same
      illegal_bins ig0 = cross_all with (cp_rptr != cp_wptr);
    }

  endgroup

  // full
  covergroup cg_full @ (negedge clk_i iff ~reset_i & ~empty_o & full_o);

    cp_v: coverpoint v_i;
    cp_rptr: coverpoint rd_ptr;
    cp_wptr: coverpoint wr_ptr;
    // If read write same address happened in previous cycle, fifo should
    // only have one element in current cycle, which contradicts with the
    // condition that fifo is full.
    cp_loir: coverpoint last_op_is_read_r {illegal_bins ig = {1};}  // cannot fill fifo by reading

    cross_all: cross cp_v, cp_rptr, cp_wptr, cp_loir {
      // by definition, fifo full means r/w pointers are the same
      illegal_bins ig0 = cross_all with (cp_rptr != cp_wptr);
    }

  endgroup

  // fifo normal
  covergroup cg_normal @ (negedge clk_i iff ~reset_i & ~empty_o & ~full_o);

    cp_v: coverpoint v_i;
    cp_rptr: coverpoint rd_ptr;
    cp_wptr: coverpoint wr_ptr;
    cp_loir: coverpoint last_op_is_read_r;

    cross_all: cross cp_v, cp_rptr, cp_wptr, cp_loir {
      // by definition, r/w pointers are different when fifo is non-empty & non-full
      illegal_bins ig0 = cross_all with (cp_rptr == cp_wptr);
    }

  endgroup

  // fifo impossible (fifo cannot be both empty and full at the same time)
  // covergroup cg_impossible @ (negedge clk_i iff ~reset_i & empty & full);

  // create cover groups
  cg_reset cov_reset = new;
  cg_empty cov_empty = new;
  cg_full cov_full = new;
  cg_normal cov_normal = new;

  // print coverages when simulation is done
  final
  begin
    $display("");
    $display("Instance: %m");
    $display("---------------------- Functional Coverage Results ----------------------");
    $display("Reset       functional coverage is %f%%", cov_reset.get_coverage());
    $display("Fifo empty  functional coverage is %f%%", cov_empty.cross_all.get_coverage());
    $display("Fifo full   functional coverage is %f%%", cov_full.cross_all.get_coverage());
    $display("Fifo normal functional coverage is %f%%", cov_normal.cross_all.get_coverage());
    $display("-------------------------------------------------------------------------");
    $display("");
  end

endmodule
