//
// Eli Orona   05/2024
//
// This module defines functional coverages of module bsg_two_fifo
//
//

`include "bsg_defines.sv"

module bsg_two_fifo_cov

 #(parameter allow_enq_deq_on_full_p = 0
  )

  (input clk_i
  ,input reset_i

  // interface signals
  ,input v_i
  ,input yumi_i

  // internal registers
  ,input full_r
  ,input empty_r
  ,input head_r
  ,input tail_r
  );

  // reset
  covergroup cg_reset @(negedge clk_i);
    coverpoint reset_i;
  endgroup

  // Partitioning covergroup into smaller ones
  // empty
  covergroup cg_empty @ (negedge clk_i iff ~reset_i & empty_r & ~full_r);

    cp_v: coverpoint v_i;
    // cannot deque when empty
    cp_yumi: coverpoint yumi_i {illegal_bins ig = {1};}
    // cannot be full when empty
    cp_full: coverpoint full_r {illegal_bins ig = {1};}
    // must be empty by definition
    cp_empty: coverpoint empty_r {illegal_bins ig = {0};}
    cp_head: coverpoint head_r;
    cp_tail: coverpoint tail_r;

    cross_all: cross cp_v, cp_yumi, cp_full, cp_empty, cp_head, cp_tail {
      // by definition, fifo empty means h/t pointers are the same
      illegal_bins ig0 = cross_all with (cp_head != cp_tail);
    }

  endgroup

  // full
  covergroup cg_full @ (negedge clk_i iff ~reset_i & ~empty_r & full_r);

    cp_v: coverpoint v_i;
    cp_yumi: coverpoint yumi_i;
    // must be full by definition
    cp_full: coverpoint full_r {illegal_bins ig = {0};}
    // cannot be empty by definition
    cp_empty: coverpoint empty_r {illegal_bins ig = {1};}
    cp_head: coverpoint head_r;
    cp_tail: coverpoint tail_r;

    cross_all: cross cp_v, cp_yumi, cp_full, cp_empty, cp_head, cp_tail {
      // by definition, fifo full means h/t pointers are the same
      illegal_bins ig0 = cross_all with (cp_head != cp_tail);
    }

  endgroup

  // fifo normal
  covergroup cg_normal @ (negedge clk_i iff ~reset_i & ~empty_r & ~full_r);

    cp_v: coverpoint v_i;
    cp_yumi: coverpoint yumi_i;
    // cannot be full
    cp_full: coverpoint full_r {illegal_bins ig = {1};}
    // cannot be empty
    cp_empty: coverpoint empty_r {illegal_bins ig = {1};}
    cp_head: coverpoint head_r;
    cp_tail: coverpoint tail_r;

    cross_all: cross cp_v, cp_yumi, cp_full, cp_empty, cp_head, cp_tail {
      // by definition, normal fifo means h/t pointers cannot be the same
      illegal_bins ig0 = cross_all with (cp_head == cp_tail);
    }

  endgroup

  // fifo impossible (fifo cannot be both empty and full at the same time)
  covergroup cg_impossible @ (negedge clk_i iff ~reset_i);
    cp_full: coverpoint full_r;
    cp_empty: coverpoint empty_r;

    cross_all: cross cp_full, cp_empty {
        illegal_bins igo = cross_all with (cp_full & cp_empty);
    }
  endgroup

  // create cover groups
  cg_reset cov_reset = new;
  cg_empty cov_empty = new;
  cg_full cov_full = new;
  cg_normal cov_normal = new;
  cg_impossible cov_impossible = new;

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
    $display("Fifo impossible        coverage is %f%%", cov_impossible.cross_all.get_coverage());
    $display("-------------------------------------------------------------------------");
    $display("");
  end

endmodule
