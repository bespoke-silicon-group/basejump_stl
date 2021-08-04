// 23 July, 2021
//
// Some ASIC SRAM generators do not support bit-wise masked writes,
// and many FPGAs do not inherently support synthesizing 1RW RAMs with bit-wise masked writes.
// In such cases, where, also, a 1R1W RAM is on the offer,
// we can use this module to mimic the required RAM.
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
//  * Reads: operationally unchanged, with one quirk:
//    - When a read request succeeds a write to the same address, 
//        updated buffer is wired to data_o
//
// Design choice: Unoptimistic
//   This version does not latch the read data from the instantiated RAM.
//   Doing so, however, leads to slightly lower number of reads and writes overall,
//   if the consecutive accesses repeat the addresses frequently, 
//   as the previously read data can be reused without reaccessing RAM.

`include "bsg_defines.v"

module bsg_mem_1rw_sync_mask_write_bit_from_1r1w #(
  parameter    `BSG_INV_PARAM(width_p)
  , parameter  `BSG_INV_PARAM(els_p)
  , parameter  latch_last_read_p     = 0
  , parameter  enable_clock_gating_p = 0
  , parameter  verbose_p             = 0
  , localparam addr_width_lp         = `BSG_SAFE_CLOG2(els_p)
  , localparam width_lp              = `BSG_SAFE_MINUS(width_p,1)
) (
  input                          clk_i
  , input                        reset_i

  , input  [width_lp:0]          data_i
  , input  [ addr_width_lp-1:0]  addr_i
  , input                        v_i
  , input  [width_lp:0]          w_mask_i
  , input                        w_i

  , output [width_lp:0]          data_o
);

  // synopsys translate_off
  always @(negedge clk_i)
    assert(int'(addr_i) < els_p) else $warning("%m Accessing uninitialized address!");
  // synopsys translate_on

  logic [addr_width_lp-1:0]      addr_r;
  logic [width_lp:0]             w_mask_r;
  logic [width_lp:0]             buf_r;
  logic                          w_next_r;
  logic                          w_r;
  logic                          r_match_r;
  logic                          w_match_r;

  wire  [width_lp:0] r_data_lo;
  wire  [width_lp:0] w_data_li = w_match_r ? buf_r 
                                : (r_data_lo & ~w_mask_r) | (buf_r & w_mask_r);
  wire               haz       = addr_r == addr_i;
  wire               r_en_li   = v_i & (haz & ~w_next_r | ~haz);
  wire               w_en_li   = w_next_r & ~(v_i & w_i & haz);

  bsg_mem_1r1w_sync
    #(.width_p   (width_p)
      ,.els_p    (els_p)
      ,.latch_last_read_p(0)
      ) ram
      (.clk_i    (clk_i)
      ,.reset_i  (reset_i)
      ,.w_v_i    (w_en_li)
      ,.w_addr_i (addr_r)
      ,.w_data_i (w_data_li)
      ,.r_v_i    (r_en_li)
      ,.r_addr_i (addr_i)
      ,.r_data_o (r_data_lo)
      );

  always_ff @(posedge clk_i) begin
    if(reset_i)
      w_r <= 1'b0;
    else begin
      w_next_r     <= v_i & w_i;
      if(v_i) begin
        w_r        <= w_i;
        addr_r     <= addr_i;
        r_match_r  <= haz & w_next_r;
        w_match_r  <= v_i & w_i & haz & w_next_r;
        if(w_i)
          w_mask_r <= w_mask_i;
      end
      buf_r <= (w_r & haz) 
                 ? (w_i
                   ? (w_data_li & ~w_mask_i) | (data_i & w_mask_i)
                   : w_data_li)
                 : data_i;
    end
  end

  wire [width_lp:0] data_out = r_match_r ? buf_r : r_data_lo;
  
  // synopsys translate_off
  always_ff @(posedge clk_i)
    if(verbose_p==1)
      $display("w_en %b | r_en %b | w_data %b | r_data %b | w_addr %06h"
              , w_en_li, r_en_li, w_data_li, r_data_lo, addr_r
              , "| buf_r %b | r_match %b | w_match %b |"
              , buf_r, r_match_r, w_match_r);
  // synopsys translate_on

  if (latch_last_read_p)
    begin: llr
      bsg_dff_en_bypass #(
        .width_p (width_p)
      ) dff_bypass (
        .clk_i   (clk_i)
        ,.en_i   (~w_r)
        ,.data_i (data_out)
        ,.data_o (data_o)
      );
    end
  else
    begin: no_llr
      assign data_o = data_out;
    end

endmodule

//`BSG_ABSTRACT_MODULE(bsg_mem_1rw_sync_mask_write_bit_from_1r1w)
