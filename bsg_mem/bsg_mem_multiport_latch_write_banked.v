/**
 *    bsg_mem_multiport_latch_write_banked.v
 *
 *    This latch file is divided into banks (num_banks_p). Read ports can read from any of the banks.
 *    Each bank has a write port, and each write port can only write into its corresponding bank.
 */



`include "bsg_defines.v"


module bsg_mem_multiport_latch_write_banked
  #(`BSG_INV_PARAM(width_p)
    , `BSG_INV_PARAM(els_p)
    , `BSG_INV_PARAM(num_rs_p)
    , `BSG_INV_PARAM(num_banks_p)

    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
    , parameter bank_addr_width_lp=`BSG_SAFE_CLOG2(els_p/num_banks_p)

    , parameter x0_tied_to_zero_p = 0
    , parameter async_read_p = 0
  )
  (
    input clk_i
    , input reset_i

    , input [num_banks_p-1:0] w_v_i
    , input [num_banks_p-1:0][bank_addr_width_lp-1:0] w_addr_i
    , input [num_banks_p-1:0][width_p-1:0] w_data_i

    , input [num_rs_p-1:0] r_v_i
    , input [num_rs_p-1:0][addr_width_lp-1:0] r_addr_i
    , output logic [num_rs_p-1:0][width_p-1:0] r_data_o
  );

  // parameter checking
  // synopsys translate_off
  initial begin
    assert((els_p%num_banks_p) == 0) else $error("els_p has to be multiples of num_banks_p.");
  end
  // synopsys translate_on


  wire unused = reset_i;

  // write ports
  localparam bank_els_lp = (els_p/num_banks_p);

  logic [num_banks_p-1:0][bank_els_lp-1:0] w_v_onehot;
  logic [num_banks_p-1:0][bank_els_lp-1:0] mem_we_clk;
  logic [num_banks_p-1:0][width_p-1:0] w_data_r;

  for (genvar i = 0; i < num_banks_p; i++) begin: ba
    // write enable decoder
    bsg_decode_with_v #(
      .num_out_p(bank_els_lp)
    ) dv0 (
      .i(w_addr_i[i])
      ,.v_i(w_v_i[i])
      ,.o(w_v_onehot[i])
    ); 

    // write icg
    for (genvar j = 0; j < bank_els_lp; j++) begin: we_icg
      bsg_icg icg0 (
        .clk_i(clk_i)
        ,.en_i(w_v_onehot[i][j])
        ,.clk_o(mem_we_clk[i][j])
      );
    end
    
    // write data latch 
    for (genvar j = 0; j < width_p; j++) begin:wl
      bsg_latch wlat0 (
        .clk_i(~clk_i)
        ,.data_i(w_data_i[i][j])
        ,.data_o(w_data_r[i][j])
      );
    end
  end


  // latch file
  localparam start_idx_lp = (x0_tied_to_zero_p ? 1 : 0);

  logic [els_p-1:start_idx_lp][width_p-1:0] mem_r;

  for (genvar i = start_idx_lp; i < els_p; i++) begin: x
    for (genvar j = 0; j < width_p; j++) begin: b
      bsg_latch lat0 (
        .clk_i(mem_we_clk[i/bank_els_lp][i%bank_els_lp])
        ,.data_i(w_data_r[i/bank_els_lp][j])
        ,.data_o(mem_r[i][j])
      );
    end
  end


  // read ports
  wire [els_p-1:0][width_p-1:0] mem_with_zero;

  if (x0_tied_to_zero_p) begin
    assign mem_with_zero = {mem_r, {width_p{1'b0}}};
  end
  else begin
    assign mem_with_zero = mem_r;
  end


  if (async_read_p) begin: asyncr
    // async read
    wire [num_rs_p-1:0] unused0 = r_v_i;

    for (genvar i = 0; i < num_rs_p; i++) begin
      assign r_data_o[i] = mem_with_zero[r_addr_i[i]];
    end

  end
  else begin: syncr
    // sync read
    logic [num_rs_p-1:0][addr_width_lp-1:0] r_addr_r;

    always_ff @ (posedge clk_i)
      for (integer i = 0; i < num_rs_p; i++)
        if (r_v_i[i]) r_addr_r[i] <= r_addr_i[i];


    for (genvar i = 0; i < num_rs_p; i++) begin
      assign r_data_o[i] = mem_with_zero[r_addr_r[i]];
    end
  end


endmodule


`BSG_ABSTRACT_MODULE(bsg_mem_multiport_latch_write_banked)
