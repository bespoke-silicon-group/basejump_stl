// 1 read-port, 1 write-port ram with a onehot address scheme
// write mask bits
// reads are asynchronous
//

`include "bsg_defines.v"

module bsg_mem_1r1w_one_hot_mask_write_bit #(parameter `BSG_INV_PARAM(width_p)
                                           , parameter `BSG_INV_PARAM(els_p)

                                           , parameter safe_els_lp=`BSG_MAX(els_p,1)
                                           )
   (input   w_clk_i
    // Currently unused
    , input w_reset_i

    // one or zero-hot
    , input [safe_els_lp-1:0] w_v_i
    , input [width_p-1:0] w_data_i

    , input [width_p-1:0] w_mask_i

    // one or zero-hot
    , input [safe_els_lp-1:0] r_v_i
    , output logic [width_p-1:0] r_data_o
    );

  wire unused0 = w_reset_i;

  logic [safe_els_lp-1:0][width_p-1:0] data_r;

  logic [`BSG_SAFE_CLOG2(safe_els_lp)-1:0] w_addr_lo;

  logic [safe_els_lp-1:0][width_p-1:0] data_n;

  for (genvar i = 0; i < els_p; i++)
    begin : mem_array
      for (genvar j = 0; j < width_p; j++)
        begin : write_mask_bits
          assign data_n[i][j] = w_mask_i[j] ? w_data_i[j] : data_r[i][j];
        end
      bsg_dff_en #(
        .width_p(width_p)
      ) mem_reg (
        .clk_i(w_clk_i)
        ,.en_i(w_v_i[i])
        ,.data_i(data_n[i])
        ,.data_o(data_r[i])
      );
    end

  bsg_mux_one_hot #(
    .width_p(width_p)
    ,.els_p(safe_els_lp)
  ) one_hot_sel (
    .data_i(data_r)
    ,.sel_one_hot_i(r_v_i)
    ,.data_o(r_data_o)
  );

   //synopsys translate_off

   initial
     begin
	if (width_p*els_p >= 64)
          $display("## %L: instantiating width_p=%d, els_p=%d (%m)"
                   ,width_p,els_p);
     end

   always_ff @(negedge w_clk_i)
     begin
       assert ((w_reset_i === 'X) || (w_reset_i === 1'b1) || $countones(w_v_i) <= 1)
         else $error("Invalid write address %b to %m is not onehot (w_reset_i=%b)\n", w_v_i, w_reset_i);
       assert ((w_reset_i === 'X) || (w_reset_i === 1'b1) || $countones(r_v_i) <= 1)
         else $error("Invalid read address %b to %m is not onehot (w_reset_i=%b)\n", r_v_i, w_reset_i);
     end

   //synopsys translate_on

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1r1w_one_hot)
