/*
* bsg_mem_1rw_sync_mask.v
*
* URAM synchronous 1-port ram for xilinx ultrascale or ultrascale plus FPGA
*
*/

`include "bsg_defines.v"

module bsg_mem_1rw_sync #(
  parameter `BSG_INV_PARAM(width_p )
  , parameter `BSG_INV_PARAM(els_p )
  , parameter latch_last_read_p=0
  , parameter enable_clock_gating_p=0
  , localparam addr_width_lp = `BSG_SAFE_CLOG2(els_p)
) (
  input                                     clk_i
  , input                                   reset_i
  , input  [`BSG_SAFE_MINUS(width_p,1):0] data_i
  , input  [ addr_width_lp-1:0]             addr_i
  , input                                   v_i
  , input                                   w_i
  , output [`BSG_SAFE_MINUS(width_p,1):0] data_o
);

  wire unused = reset_i;

  if (width_p == 0)
   begin: z
     wire unused0 = &{clk_i, v_i, data_i, addr_i, w_i};
     assign data_o = '0;
   end
  else
   begin: nz

  (* ram_style = "ultra" *) logic [`BSG_SAFE_MINUS(width_p,1):0] mem [els_p-1:0];

  logic [`BSG_SAFE_MINUS(width_p,1):0] data_r;
  always_ff @(posedge clk_i) begin
    if (v_i & ~w_i)
      data_r <= mem[addr_i];
  end

  initial
    begin
      $display("BSG INFO: els_p=%d width_p=%d 1RW SRAM Mask Write ram will be inferred as ultra RAM.",els_p,width_p);
    end
  
  assign data_o = data_r;

    always_ff @(posedge clk_i) begin
      if (v_i & w_i)
          mem[addr_i] <= data_i;
    end
  end // non_zero_width

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1rw_sync)
