// 23 July, 2021
//
// Some ASIC SRAM generators do not support bit-wise masked writes,
// and many FPGAs do not inherently support synthesizing 1RW RAMs with bit-wise masked writes.
// In such cases, where, also, a 1R1W RAM is on the offer,
// we can use this module to mimic the required RAM.
// 
// Operation:
//  * Writes:
//    - Register the write data, mask; read the address in the 0th cycle
//    - Apply the masked write to the read data availble in 1st cycle; write using write port of RAM
//    - Data reflected in RAM (internally) in 2nd clock
//   
//  * Reads: operationally unchanged, with one quirk:
//    - When a read request succeeds a write to the same address, 
//        previously read data with updates applied is wired to data_o

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
 
  always @(negedge clk_i)
    assert(int'(addr_i) < els_p) else $warning("%m Accessing uninitialized address!");

  logic [width_lp:0]             w_data_r;
  logic [addr_width_lp-1:0]      addr_r;
  logic [width_lp:0]             w_mask_r;
  logic                          w_r;

  logic [width_lp:0]             buf_r;
  logic                          haz_r;

  wire  [width_lp:0] r_data_lo;
  wire  [width_lp:0] w_data_li   = ((haz_r ? buf_r : r_data_lo) & ~w_mask_r) | (w_data_r & w_mask_r);
  wire               haz         = w_r & (addr_r == addr_i);
  wire               r_en_li     = v_i & !haz;
  wire               w_en_li     = ~(v_i & w_i & addr_r == addr_i) & w_r;

  bsg_mem_1r1w_sync
    #(.width_p   (width_p)
      ,.els_p    (els_p)
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
    if(verbose_p==1)
      $display("w_en %b | r_en %b | w_data %b | w_addr %06h| haz %b | buf_r %b |"
              , w_en_li, r_en_li, w_data_li, addr_r, haz, buf_r);

    if(~reset_i) begin
      haz_r <= haz;
      w_r   <= v_i & w_i;
      if(v_i) begin
        addr_r <= addr_i;
        if(w_i) begin
          w_mask_r <= w_mask_i;
          w_data_r <= data_i;
        end
      end
      if(w_r)
        buf_r <= w_data_li;
    end
  end

  wire [width_lp:0] data_out = haz_r ? buf_r : r_data_lo;

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
