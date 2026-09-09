//
// Paul Gao   08/2021
//
// This module defines functional coverages of module bsg_serial_in_parallel_out
//
//

`include "bsg_defines.sv"

module bsg_serial_in_parallel_out_cov

 #(parameter width_p = "inv"
  ,parameter els_p = "inv"
  ,parameter out_els_p = els_p
  )

  ( input clk_i
  , input reset_i

  // interface signals
  , input valid_i

  , input [$clog2(out_els_p+1)-1:0] yumi_cnt_i

  // internal registers
  , input [$clog2(els_p+1)-1:0]    num_els_r
  , input [els_p-1:0] valid_r

//   ,input [ptr_width_lp-1:0] rptr_r
//   ,input [ptr_width_lp-1:0] wptr_r
//   ,input full  // registered in sub-module bsg_fifo_tracker
//   ,input empty // registered in sub-module bsg_fifo_tracker
//   ,input read_write_same_addr_r
  );

  // reset
  covergroup cg_reset @(negedge clk_i);
    coverpoint reset_i;
  endgroup

  // Partitioning covergroup into smaller ones
  // empty
  covergroup cg_empty @ (negedge clk_i iff ~reset_i & num_els_r == 0);

    cp_v: coverpoint valid_i;
    cp_ready: coverpoint ready_and_o {illegal_bins ig0 = {0};}
    // Cannot be something other than 0 (valid_i low) or 1 (valid_i high)
    cp_yumi: coverpoint yumi_cnt_i {illegal_bins ig0 = {[2:$]};}
    // Cannot be something other than 0 (valid_i low) or 1 (valid_i high)
    cp_valid_o: coverpoint valid_o {illegal_bins ig0 = {[2:$]};} 

    cross_all: cross cp_v, cp_ready, cp_yumi, cp_valid_o {
        illegal_bins ig0 = cross_all with (cp_valid_o == 0 & cp_yumi == 1);
        illegal_bins ig1 = cross_all with (cp_v == 0 & cp_yumi == 1);

        illegal_bins ig2 = cross_all with (cp_v == 0 & cp_valid_o == 1);
        illegal_bins ig3 = cross_all with (cp_v == 1 & cp_valid_o == 0);
    }
  endgroup

  // full
  covergroup cg_full @ (negedge clk_i iff ~reset_i & num_els_r == out_els_p);

    cp_v: coverpoint valid_i;
    // cannot supply when full
    cp_ready: coverpoint ready_and_o {illegal_bins ig0 = {1};}
    // Cannot consume more than els_p values
    cp_yumi: coverpoint yumi_cnt_i {illegal_bins ig0 = {[els_p+1:$]};}
    // Cannot be something other 15
    cp_valid_o: coverpoint valid_o {illegal_bins ig0 = {[0:(2 ** out_els_p) - 2]};} // TODO: not hardcoded?

    cross_all: cross cp_v, cp_ready, cp_yumi, cp_valid_o {
    }

  endgroup

  // fifo normal
  covergroup cg_normal @ (negedge clk_i iff ~reset_i & 0 < num_els_r & num_els_r < out_els_p);

    cp_v: coverpoint valid_i;
    // must accept values in normal
    cp_ready: coverpoint ready_and_o {illegal_bins ig0 = {0};}
    // Cannot consume more than els_p values
    cp_yumi: coverpoint yumi_cnt_i {illegal_bins ig0 = {[els_p+1:$]};}
    cp_valid_o: coverpoint valid_o {illegal_bins ig0 = {0, 2, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14};} // TODO: not hardcoded?

    cross_all: cross cp_v, cp_ready, cp_yumi, cp_valid_o {
        // If no input data, we cannot read max objects
        illegal_bins ig0 = cross_all with (!cp_v & cp_yumi == els_p);
        // Cannot read more than existing objects
        illegal_bins ig1 = cross_all with (cp_yumi > $clog2(cp_valid_o + 1));
        // If no input data, cannot have max objects
        illegal_bins ig2 = cross_all with (!cp_v & cp_valid_o == 15);

        // Covered in empty
        illegal_bins ig3 = cross_all with (cp_v & cp_valid_o == 1);
    }
  endgroup

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
    $display("Reset           functional coverage is %f%%", cov_reset.get_coverage());
    $display("Sipo empty      functional coverage is %f%%", cov_empty.cross_all.get_coverage());
    $display("Sipo full       functional coverage is %f%%", cov_full.cross_all.get_coverage());
    $display("Sipo normal     functional coverage is %f%%", cov_normal.cross_all.get_coverage());
    // $display("Sipo impossible functional coverage is %f%%", cov_impossible.cross_all.get_coverage());
    $display("-------------------------------------------------------------------------");
    $display("");
  end

endmodule
