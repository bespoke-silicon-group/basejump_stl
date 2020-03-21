
// Paul Gao   03/2020
//

module bsg_noc_switch_static

 #(parameter width_p    = "inv"
  ,parameter els_p      = "inv"
  ,localparam lg_els_lp = `BSG_SAFE_CLOG2(els_p)
  )

  (input        [lg_els_lp-1:0]          sel_i
  
  ,input        [els_p-1:0]              v_i
  ,input        [els_p-1:0][width_p-1:0] data_i
  ,output logic [els_p-1:0]              ready_o
  
  ,output logic [els_p-1:0]              v_o
  ,output logic [els_p-1:0][width_p-1:0] data_o
  ,input        [els_p-1:0]              ready_i

  ,input                mult_v_i
  ,input  [width_p-1:0] mult_data_i
  ,output               mult_ready_o

  ,output               mult_v_o
  ,output [width_p-1:0] mult_data_o
  ,input                mult_ready_i
  );

  for (genvar i = 0; i < els_p; i++)
    always_comb
        if (sel_i == (lg_els_lp)'(i))
          begin
            v_o    [i] = mult_v_i;
            data_o [i] = mult_data_i;
            ready_o[i] = mult_ready_i;
          end
        else
          begin
            v_o    [i] = 1'b0;
            data_o [i] = '0;
            ready_o[i] = 1'b1;
          end

  assign mult_v_o     = v_i    [sel_i];
  assign mult_data_o  = data_i [sel_i];
  assign mult_ready_o = ready_i[sel_i];

endmodule