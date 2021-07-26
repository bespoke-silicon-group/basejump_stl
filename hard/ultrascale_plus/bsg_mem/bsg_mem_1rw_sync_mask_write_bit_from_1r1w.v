// 23 July, 2021
//
// Essentially, a 1RW synchronous-read RAM supporting bit-wise masked writes.
// Some FPGAs do not inherently support synthesising 1RW RAMs with bit-wise masked writes.
// In such cases, where, also, a 1R1W RAM is on the offer, 
// we can use this module to mimic the required RAM.
// 
// Operation:
//  * Writes:
//    - If op is not masked, or byte-masked,
//        Register the write data, mask (to avoid structural hazard)
//      Else,
//        Read the address in the 0th cycle
//    - If there's a different address requested by an incoming op, only then:
//        Apply the masked write to the read data in 1st cycle and write using write port of RAM
//      Else,
//        Delay the write until such time as a different address gets requested by a valid op
//    - Data reflected in RAM (internally) in 2nd or later cycles
//   
//  * Reads: operationally unchanged, with one quirk:
//    - When a read request succeeds a write to the same address, 
//        previously read data is bypassed to the read register with applicable update
// This version does well with low input delay, but allows for longer output paths
// Can infer Block RAM with permissive parameter values

`include "bsg_defines.v"

module bsg_mem_1rw_sync_mask_write_bit_from_1r1w #(
  parameter    `BSG_INV_PARAM(width_p)
  , parameter  `BSG_INV_PARAM(els_p)
  , parameter  latch_last_read_p     = 0
  , parameter  enable_clock_gating_p = 0
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
    assert(int'(addr_i) < els_p) else $warning("Accessing uninitialized address!");

  logic [addr_width_lp-1:0]      addr_r;
  logic [width_lp:0]             w_data_r;
  logic [width_lp:0]             w_mask_r;
  logic                          w_r;
  logic [width_lp:0]             r_data_r;
  logic                          w_en_r;

  logic [width_lp:0] ram [els_p-1:0];

  generate
    integer ram_index;
    initial
      for (ram_index = 0; ram_index < els_p; ram_index = ram_index + 1)
        ram[ram_index] = {(width_p){1'b0}};
  endgenerate


  wire same_addr = addr_r == addr_i;
  wire masked    = (w_mask_i != '1) & w_i;
  wire w_en      = v_i & !same_addr & w_en_r;
  wire r_en      = v_i & (masked | !w_i) & !same_addr;

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      w_en_r   <= 1'b0;
      w_r      <= 1'b0;
      r_data_r <= '0;
    end
    else begin
      if(v_i) begin
        w_r      <= w_i;
        addr_r   <= addr_i;
        w_mask_r <= (same_addr & !w_i) ? '0 : w_mask_i;
        w_data_r <= (same_addr & !w_i) ? '0 : data_i;
        w_en_r   <= same_addr ? ((w_i | w_r) ? 1'b1 : w_en_r) : w_i;
      end
      
      if(r_en)
        r_data_r <= ram[addr_i];
      else if(v_i & w_r  & same_addr)
        r_data_r <= (r_data_r & ~w_mask_r | w_data_r & w_mask_r);
       
      if(w_en) 
        ram[addr_r] <= r_data_r & ~w_mask_r | w_data_r & w_mask_r;
    end
  end

  if (latch_last_read_p)
    begin: llr
      bsg_dff_en_bypass #(
        .width_p(width_p)
      ) dff_bypass (
        .clk_i(clk_i)
        ,.en_i(~w_r)
        ,.data_i(r_data_r)
        ,.data_o(data_o)
      );
    end
  else
    begin: no_llr
      assign data_o = r_data_r;
    end

endmodule

//`BSG_ABSTRACT_MODULE(bsg_mem_1rw_sync_mask_write_bit_from_1r1w)
