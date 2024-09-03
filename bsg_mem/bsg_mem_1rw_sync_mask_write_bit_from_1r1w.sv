// 23 July, 2021
//
// Some ASIC SRAM generators do not support bit-wise masked writes,
// and many FPGAs do not inherently support synthesizing 1RW RAMs with bit-wise masked writes.
// We can implement these with 1R1W RAMs, if available.
//
// Operation:
//  * Writes:
//    - Write match to a previous write:
//        Skip previous write scheduled to happen in this cycle, and
//        Register the previously updated write updated with 
//              the current write into the buffer for subsequent write
//    - Write no match to a previous write:
//        Register the write data for subsequent masked write into RAM
//    - Read match to previous write:
//        Register the updated write into the buffer for subsequent access
//          (To avoid read and write to same address)
//    - Data reflected in RAM (internally) in the next clock if no hazard
//   
//  * Reads:
//    - When a read request succeeds a write to the same address, 
//        updated buffer is wired out
//      Otherwise expect read data in next cycle

`include "bsg_defines.sv"

module bsg_mem_1rw_sync_mask_write_bit_from_1r1w #(
  parameter    `BSG_INV_PARAM(width_p)
  , parameter  `BSG_INV_PARAM(els_p)
  , parameter  latch_last_read_p     = 0
  , parameter  enable_clock_gating_p = 0
  , parameter  verbose_p             = 0
  , localparam addr_width_lp         = `BSG_SAFE_CLOG2(els_p)
  , localparam width_m1_lp           = `BSG_SAFE_MINUS(width_p,1)
) (
  input                          clk_i
  , input                        reset_i

  , input  [width_m1_lp:0]       data_i
  , input  [ addr_width_lp-1:0]  addr_i
  , input                        v_i
  , input  [width_m1_lp:0]       w_mask_i
  , input                        w_i

  , output [width_m1_lp:0]       data_o
);

`ifndef BSG_HIDE_FROM_SYNTHESIS
  always @(negedge clk_i)
    assert((int'(addr_i) < els_p) || (els_p <= 1)) else $warning("%m Accessing uninitialized address!");
`endif

  wire                      v_and_w_n = v_i & w_i;
  wire                      v_and_w_r;

  bsg_dff
    #(.width_p(1))
    common_next_regs
    (.clk_i  (clk_i)
    ,.data_i (v_and_w_n)
    ,.data_o (v_and_w_r)
    );

  wire [addr_width_lp-1:0]  w_addr_r;
  wire [addr_width_lp-1:0]  addr_li = els_p > 1 ? addr_i : '0;
  wire                      addr_match = w_addr_r == addr_li;
  wire                      bypass_n = v_and_w_r & addr_match;
  wire                      bypass_r;

  bsg_dff_en
    #(.width_p(addr_width_lp+1))
    common_regs
    (.clk_i  (clk_i)
    ,.en_i   (v_i)
    ,.data_i ({addr_li, bypass_n})
    ,.data_o ({w_addr_r, bypass_r})
    );

  wire [width_m1_lp:0]      w_mask_r;

  bsg_dff_en 
    #(.width_p(width_p))
    write_regs
    (.clk_i  (clk_i)
    ,.en_i   (v_i & w_i)
    ,.data_i (w_mask_i)
    ,.data_o (w_mask_r)
    );

  wire  [width_m1_lp:0]     mem_data_lo;

  // If there are no back-to-back RAW or WAW dependence, then bypass_data_r contains the
  // data to write. If there is a back-to-back dependence, then this contains the latest
  // running value of this memory address
  logic [width_m1_lp:0]     bypass_data_r;

  // If WAW, write bypass_data_r which incorporates both updates
  // else write updated mem_data_lo
  wire  [width_m1_lp:0] w_data_li = bypass_r
          ? bypass_data_r : (mem_data_lo & ~w_mask_r) | (bypass_data_r & w_mask_r);

  if(els_p > 0) 
    begin
      always_ff @(posedge clk_i)
        bypass_data_r <= bypass_n
                    ? (w_i
                      ? (w_data_li & ~w_mask_i) | (data_i & w_mask_i) // WAW
                      : w_data_li) // RAW
                    : data_i; // No hazard
    end else begin
      assign bypass_data_r = '0;
    end

  // Read if not a hazard with next pipeline stage write
  // Write previous if not a write hazard currently
  wire r_en_li = v_i & ~bypass_n;
  wire w_en_li = v_and_w_r & ~(v_and_w_n & addr_match);

  bsg_mem_1r1w_sync
    #(.width_p (width_p)
    ,.els_p    (els_p))
    ram
    (.clk_i    (clk_i)
    ,.reset_i  (reset_i)
    ,.w_v_i    (w_en_li)
    ,.w_addr_i (w_addr_r)
    ,.w_data_i (w_data_li)
    ,.r_v_i    (r_en_li)
    ,.r_addr_i (addr_li)
    ,.r_data_o (mem_data_lo)
    );

  wire [width_m1_lp:0] data_o_latchable = bypass_r ? bypass_data_r : mem_data_lo;
  
`ifndef BSG_HIDE_FROM_SYNTHESIS
  always_ff @(posedge clk_i)
    if(verbose_p==1)
      $display("w_en %b | r_en %b | w_data_li %b | mem_data_lo %b | w_addr_r %06h"
              , w_en_li, r_en_li, w_data_li, mem_data_lo, w_addr_r
              , "| bypass_data_r %b | bypass_r %b|"
              , bypass_data_r, bypass_r);
`endif

  if (latch_last_read_p)
    begin: llr
      logic read_en_r;
      bsg_dff
        #(.width_p(1))
        read_en_dff
        (.clk_i  (clk_i)
        ,.data_i (v_i & ~w_i)
        ,.data_o (read_en_r)
        );

      bsg_dff_en_bypass 
        #(.width_p (width_p)) 
        dff_bypass 
        (.clk_i   (clk_i)
        ,.en_i   (read_en_r)
        ,.data_i (data_o_latchable)
        ,.data_o (data_o)
      );
    end
  else
    begin: no_llr
      assign data_o = data_o_latchable;
    end

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1rw_sync_mask_write_bit_from_1r1w)
