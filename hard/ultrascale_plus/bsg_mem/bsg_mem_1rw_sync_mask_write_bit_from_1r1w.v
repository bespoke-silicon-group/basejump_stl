// 23 July, 2021
//
// Technically, a synchronous-read SDP RAM with no masks involved
// But essentially, a single port, synchronous-read RAM with bit-wise mask
// 
// Motivation:
// Some FPGAs (like Zynq 7020) do not support bit-wise masks.
// 
// Operation:
//  * Bit-masked Write:
//    - Read the address in the 0th cycle
//    - If there's a different address requested by an incoming op, only then:
//        Apply the masked write to the read data in 1st cycle and write using write port of RAM
//      Else,
//        Delay the write until such time as a different address gets requested by an incoming op
//    - Data reflected in RAM in 2nd cycle
//   
//  * Byte-masked or no-mask Write:
//    - Register the write data, mask (to avoid structural hazards)
//    - Write the data through write port of RAM
//    - Data reflected in RAM in 2nd or later cycles (similar to masked writes)
// 
//  * Reads: operationally unchanged, except:
//    - When a read request immediately succeeds a write to the same address, 
//        previously read data is bypassed to the read register with applicable updates

`include "bsg_defines.v"

module bsg_mem_1rw_sync_mask_write_bit_from_1r1w #(
  parameter    `BSG_INV_PARAM(width_p)
  , parameter  `BSG_INV_PARAM(els_p)
  , localparam addr_width_lp = `BSG_SAFE_CLOG2(els_p)
  , localparam width_lp = `BSG_SAFE_MINUS(width_p,1)
) (
  input                          clk_i
  , input                        reset_i

  , input                        v_i
  , input  [ addr_width_lp-1:0]  addr_i
  , input                        w_i
  , input  [width_lp:0]          data_i
  , input  [width_lp:0]          w_mask_i

  , output [width_lp:0]          data_o
);
  
  initial assert(int'(addr_i) < els_p) else $warning("Accessing uninitialized address!");

  logic [addr_width_lp-1:0] addr_r;
  logic [width_lp:0]        r_data_r;
  logic [width_lp:0]        w_data_r;
  logic [width_lp:0]        w_mask_r;
  logic                     w_en_r;
  logic                     w_r;

  //AM: may be skipped if it's guaranteed that the first operation to an uninitialized address is always a full write
  logic                     not_first_r;

  // Infers an SDP BRAM
  (* ram_style = "block" *) logic [width_lp:0] ram [els_p-1:0];

  wire masked = (w_mask_i != '1) && w_i;
  wire w_en   = v_i && (addr_r != addr_i) && w_en_r;
  wire r_en   = v_i && (masked || !w_i) && ((addr_r != addr_i) || !not_first_r);

  always_ff @(posedge clk_i) begin
     if(r_en)
        r_data_r <= ram[addr_i];
       
     if(w_en) 
        ram[addr_r] <= r_data_r & ~w_mask_r | w_data_r & w_mask_r;
  end

  `ifndef SYNTHESIS
  generate
    integer ram_index;
    initial
      for (ram_index = 0; ram_index < els_p; ram_index = ram_index + 1)
        ram[ram_index] = {(width_lp+1){1'b0}};
  endgenerate
  `endif

  always_ff @(posedge clk_i) begin
    if(!reset_i) begin
      not_first_r <= 1'b0;
      w_en_r   <= 1'b0;
      w_r      <= 1'b0;
      w_data_r <= '0;
      r_data_r <= '0;
      w_mask_r <= '0;
      addr_r   <= '0;
    end

    else
      if(v_i) begin: v
        w_r     <= w_i;
        addr_r  <= addr_i;
        w_mask_r <= ((addr_r == addr_i) && w_i == 1'b0) ? '0 : w_mask_i;
        w_data_r <= ((addr_r == addr_i) && w_i == 1'b0) ? '0 : data_i;

        if(!not_first_r)
          not_first_r <= 1'b1;
        else begin
          w_en_r <= (addr_r == addr_i) ? 
            (!w_i && !w_r) ? w_en_r : 1'b1 :
            w_i;
          if(addr_r == addr_i)
            r_data_r <= w_r ? (r_data_r & ~w_mask_r | w_data_r & w_mask_r) : r_data_r;
        end
      end: v
  end

  assign data_o = r_data_r;
endmodule
