// MBT
//
// 1 read-port, 1 write-port ram
//
// reads are asynchronous
//
// for synthesizable internal version, we omit assertions
// these should be placed in the outer wrapper
//

module bsg_mem_1r1w_synth #(parameter width_p=-1
			    ,parameter els_p=-1
			    ,parameter read_write_same_addr_p=0
			    ,parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
			    ,parameter harden_p=0)
(
  input w_clk_i
  ,input w_reset_i

  ,input w_v_i
  ,input [addr_width_lp-1:0] w_addr_i
  ,input [width_p-1:0] w_data_i

  // currently unused
  ,input r_v_i
  ,input [addr_width_lp-1:0]  r_addr_i

  ,output logic [width_p-1:0] r_data_o
);

  logic [width_p-1:0] mem [els_p-1:0];

  wire unused0 = w_reset_i;
  wire unused1 = r_v_i;

  // this implementation ignores the r_v_i
  assign r_data_o = mem[r_addr_i];

  always_ff @(posedge w_clk_i) begin
    if (w_v_i) begin
      mem[w_addr_i] <= w_data_i;
    end
  end

endmodule
