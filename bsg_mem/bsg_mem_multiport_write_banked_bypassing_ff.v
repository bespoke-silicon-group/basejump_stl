/**
 *    bsg_mem_multiport_write_banked_bypassing_ff.v
 *
 *    @author Tommy J
 *    FPGA-friendly version to emulate the behavior of  bsg_mem_multiport_write_banked_bypassing_latch without the latch
 *    The main difference is that bypass data will be available at the output after the posedge of clk_i.
 *
 */


`include "bsg_defines.v"


module bsg_mem_multiport_write_banked_bypassing_ff
  #(`BSG_INV_PARAM(els_p)
    , `BSG_INV_PARAM(width_p)
    , `BSG_INV_PARAM(num_rs_p)
    , `BSG_INV_PARAM(num_banks_p)
    
    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
    , parameter bank_addr_width_lp=`BSG_SAFE_CLOG2(els_p/num_banks_p)
  )
  ( 
    input clk_i
    , input reset_i

    , input [num_banks_p-1:0] w_v_i
    , input [num_banks_p-1:0][bank_addr_width_lp-1:0] w_addr_i
    , input [num_banks_p-1:0][width_p-1:0] w_data_i

    // async read
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

  // local param
  localparam bank_els_lp = (els_p/num_banks_p);
  localparam lg_num_banks_lp = `BSG_SAFE_CLOG2(num_banks_p);

  // Write ports

  logic [num_banks_p-1:0][bank_els_lp-1:0] w_v_onehot;

  for (genvar i = 0; i < num_banks_p; i++) begin: ba
    // write enable decoder
    bsg_decode_with_v #(
      .num_out_p(bank_els_lp)
    ) dv0 (
      .i(w_addr_i[i])
      ,.v_i(w_v_i[i])
      ,.o(w_v_onehot[i])
    );
  end


  // Register file
  logic [els_p-1:0][width_p-1:0] mem_r; 
  logic [num_banks_p-1:0][bank_els_lp-1:0][width_p-1:0] banked_mem;

  for (genvar i = 0; i < els_p; i++) begin: x
    // address is striped with banks.
    localparam bank_id_lp = (i%num_banks_p);
    localparam bank_addr_lp = (i/num_banks_p);

    bsg_dff_en #(
      .width_p(width_p)
    ) dff0 (
      .clk_i(clk_i)
      ,.en_i(w_v_onehot[bank_id_lp][bank_addr_lp])
      ,.data_i(w_data_i[bank_id_lp])
      ,.data_o(mem_r[i])
    );

    // mem_r sorted into banks
    assign banked_mem[i%num_banks_p][i/num_banks_p] = mem_r[i];
  end


  // Read ports
  logic [num_rs_p-1:0][num_banks_p-1:0][width_p-1:0] bank_r_data;
  logic [num_rs_p-1:0][num_banks_p-1:0][width_p-1:0] bank_r_data_bypass;

  for (genvar i = 0; i < num_rs_p; i++) begin: rs
    wire [bank_addr_width_lp-1:0] r_bank_addr = (bank_addr_width_lp)'(r_addr_i[i] / num_banks_p);
    wire [lg_num_banks_lp-1:0] r_bank_id = (lg_num_banks_lp)'(r_addr_i[i] % num_banks_p); 

    for (genvar j = 0; j < num_banks_p; j++) begin: ba
      bsg_mux #(
        .width_p(width_p)
        ,.els_p(bank_els_lp)
      ) rmux0 (
        .data_i(banked_mem[j])
        ,.sel_i(r_bank_addr)
        ,.data_o(bank_r_data[i][j])
      );

      // bank bypass mux
      bsg_mux #(
        .width_p(width_p)
        ,.els_p(2)
      ) bypass_mux (
        .data_i({w_data_i[j], bank_r_data[i][j]})
        ,.sel_i(w_v_i[j] & (w_addr_i[j] == r_bank_addr))
        ,.data_o(bank_r_data_bypass[i][j])
      );
    end

    // read mux output (selects bank)
    bsg_mux #(
      .width_p(width_p)
      ,.els_p(num_banks_p)
    ) output_mux (
      .data_i(bank_r_data_bypass[i])
      ,.sel_i(r_bank_id)
      ,.data_o(r_data_o[i])
    );   
  end


endmodule


`BSG_ABSTRACT_MODULE(bsg_mem_multiport_write_banked_bypassing_ff)
