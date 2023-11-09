// MBT
//
// 1 read-port, 1 write-port ram
//
// reads are asynchronous
//
// for synthesizable internal version, we omit assertions
// these should be placed in the outer wrapper
//

`include "bsg_defines.sv"

module bsg_mem_1r1w_synth #(parameter `BSG_INV_PARAM(width_p)
			    ,parameter `BSG_INV_PARAM(els_p)
			    ,parameter read_write_same_addr_p=0
			    ,parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p))
(
  input w_clk_i
  ,input w_reset_i

  ,input w_v_i
  ,input [addr_width_lp-1:0] w_addr_i
  ,input [`BSG_SAFE_MINUS(width_p, 1):0] w_data_i

  // currently unused
  ,input r_v_i
  ,input [addr_width_lp-1:0]  r_addr_i

  ,output logic [`BSG_SAFE_MINUS(width_p, 1):0] r_data_o
);

  wire unused0 = w_reset_i;
  wire unused1 = r_v_i;

  if (width_p == 0 || els_p == 0)
   begin: z
     wire unused2 = &{w_clk_i, w_addr_i, w_data_i, r_addr_i};
     assign r_data_o = '0;
   end
  else
   begin: nz

  logic [width_p-1:0] mem [els_p-1:0];

  wire [addr_width_lp-1:0] r_addr_li = (els_p > 0) ? r_addr_i:'0;
  wire [addr_width_lp-1:0] w_addr_li = (els_p > 0) ? w_addr_i:'0;

  // this implementation ignores the r_v_i
  assign r_data_o = mem[r_addr_li];

  always_ff @(posedge w_clk_i) begin
    if (w_v_i) begin
      mem[w_addr_li] <= w_data_i;
    end
  end
   end
endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1r1w_synth)
