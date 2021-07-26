// In this version, addr_i is registered instead of ram[addr_i]
// May not infer Block RAM, allows for maximum input delay, 
// but constrains output paths (if latch_last_read is not set)

`include "bsg_defines.v"

module bsg_mem_1rw_sync_mask_write_bit_from_1r1w_buf #(
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
    assert(int'(addr_i) < els_p) else $warning("%m Address out of range!");

  logic [addr_width_lp-1:0]      addr_r;
  logic [width_lp:0]             w_data_r;
  logic [width_lp:0]             w_mask_r;
  logic                          w_r;

  logic                          same_addr_r;
  logic [addr_width_lp-1:0]      buf_addr_r;
  logic [width_lp:0]             buf_r;
  logic                          buf_en_r;

  wire w_en = buf_en_r;
  wire hit  = buf_addr_r == addr_r;

  logic [width_lp:0] ram [els_p-1:0];

  wire [width_lp:0] r_data = ram[addr_r];

  always_ff @(posedge clk_i) begin
    if(w_en)
      ram[buf_addr_r] <= buf_r;
  end

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      same_addr_r <= 1'b0;
      w_r         <= 1'b0;
    end
    else begin
      w_r         <= v_i & w_i;
      buf_en_r    <= w_r;
      same_addr_r <= addr_r == addr_i;
      if(v_i) begin
        addr_r  <= addr_i;
        if(w_i) begin
          w_mask_r <= w_mask_i;
          w_data_r <= data_i;
        end
      end

      buf_r <= (((hit & buf_en_r) ? buf_r : r_data) & ~w_mask_r)
                | (w_data_r & w_mask_r);
      buf_addr_r <= addr_r;
    end
  end

  wire [width_lp:0] data_out = (same_addr_r & buf_en_r) ? buf_r : r_data;

  if (latch_last_read_p)
    begin: llr
      bsg_dff_en_bypass #(
        .width_p(width_p)
      ) dff_bypass (
        .clk_i(clk_i)
        ,.en_i(~w_r)
        ,.data_i(data_out)
        ,.data_o(data_o)
      );
    end
  else
    begin: no_llr
      assign data_o = data_out;
    end

endmodule

//`BSG_ABSTRACT_MODULE(bsg_mem_1rw_sync_mask_write_bit_from_1r1w_buf)
