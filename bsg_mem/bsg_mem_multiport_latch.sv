/**
 *    bsg_mem_multiport_latch.sv
 *
 *    @author tommy
 *
 *    Multiport synth memory.
 *    it can be used as RISC-V Latch-based regfile.
 *
 *    width_p = data width.
 *    els_p = # of words in regfile.
 *    num_rs_p = # of read ports.
 *    If x0_tied_to_zero_p = 1, then x0 becomes constant zero (can't be written).
 *    If async_read_p = 1, then read is asynchronous.
 *  
 *    Schematic:
 *    https://docs.google.com/presentation/d/1cM7tNi4jdQBDbLKx9V26n9nimqWHOmu6k8G7NUmvctY/edit#slide=id.ge3e59a77fd_0_47
 */


`include "bsg_defines.sv"


module bsg_mem_multiport_latch
  #(`BSG_INV_PARAM(width_p)
    , `BSG_INV_PARAM(els_p)
    , `BSG_INV_PARAM(num_rs_p)

    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)

    , parameter x0_tied_to_zero_p = 0
    , parameter start_idx_lp = (x0_tied_to_zero_p ? 1 : 0)
    
    , parameter async_read_p = 0
  )
  (
    input clk_i
    , input reset_i

    , input w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0] w_data_i

    , input [num_rs_p-1:0] r_v_i
    , input [num_rs_p-1:0][addr_width_lp-1:0] r_addr_i
    , output logic [num_rs_p-1:0][width_p-1:0] r_data_o
  );


  wire unused =  reset_i;


  // write enable
  logic [els_p-1:0] w_v_onehot;
  logic [els_p-1:start_idx_lp] mem_we_clk;

  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) dv0 (
    .i(w_addr_i)
    ,.v_i(w_v_i)
    ,.o(w_v_onehot)
  ); 
  
  for (genvar i = start_idx_lp; i < els_p; i++) begin: we_icg
    bsg_icg_pos icg0 (
      .clk_i(clk_i)
      ,.en_i(w_v_onehot[i])
      ,.clk_o(mem_we_clk[i])
    );
  end


  // write data latch 
  logic [width_p-1:0] w_data_r;
  for (genvar i = 0; i < width_p; i++) begin:wl
    bsg_latch wlat0 (
      .clk_i(~clk_i)
      ,.data_i(w_data_i[i])
      ,.data_o(w_data_r[i])
    );
  end


  // latch file
  logic [els_p-1:start_idx_lp][width_p-1:0] mem_r;

  for (genvar i = start_idx_lp; i < els_p; i++) begin: x
    for (genvar j = 0; j < width_p; j++) begin: b
      bsg_latch lat0 (
        .clk_i(mem_we_clk[i])
        ,.data_i(w_data_r[j])
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


`BSG_ABSTRACT_MODULE(bsg_mem_multiport_latch)
