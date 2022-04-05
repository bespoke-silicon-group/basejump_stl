/*
* bsg_mem_1rw_sync_mask_write_byte.v
*
* ultra synchronous 1-port ram for xilinx ultrascale or ultrascale plus FPGA
*
*/

`include "bsg_defines.v"

module bsg_mem_1rw_sync_mask_write_byte #(
  parameter `BSG_INV_PARAM(data_width_p )
  , parameter `BSG_INV_PARAM(els_p )
  , parameter latch_last_read_p=0
  , parameter enable_clock_gating_p=0
  , localparam addr_width_lp = `BSG_SAFE_CLOG2(els_p)
  , localparam mask_width_lp = data_width_p >> 3
) (
  input                                     clk_i
  , input                                   reset_i
  , input  [`BSG_SAFE_MINUS(data_width_p,1):0] data_i
  , input  [ addr_width_lp-1:0]             addr_i
  , input                                   v_i
  , input  [`BSG_SAFE_MINUS(mask_width_lp,1):0] write_mask_i
  , input                                   w_i
  , output [`BSG_SAFE_MINUS(data_width_p,1):0] data_o
);

  wire unused = reset_i;

  if (data_width_p == 0)
   begin: z
     wire unused0 = &{clk_i, v_i, data_i, addr_i, w_i};
     assign data_o = '0;
   end
  else
   begin: nz

  (* ram_style = "ultra" *) logic [`BSG_SAFE_MINUS(data_width_p,1):0] mem [els_p-1:0];

  logic [`BSG_SAFE_MINUS(data_width_p,1):0] data_r;
  always_ff @(posedge clk_i) begin
    if (v_i & ~w_i)
      data_r <= mem[addr_i];
  end

  initial
    begin
      $display("BSG INFO: els_p=%d data_width_p=%d 1RW SRAM Mask Write ram will be inferred as ultra RAM.",els_p,data_width_p);
    end
  
  assign data_o = data_r;

    always_ff @(posedge clk_i) begin
      for (integer i=0; i<mask_width_lp; i=i+1) begin
      if (v_i)
        if (w_i & write_mask_i[i])
          mem[addr_i][i*8+:8] <= data_i[i*8+:8];
      end
    end
  end // non_zero_width

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1rw_sync_mask_write_bit)
