// DGS 3/2/2018
//
// Synchronous 1 read-port and 1 write port ram.
//

module bsg_mem_1r1w_sync #(parameter width_p=-1
                         ,parameter els_p=-1
                         ,parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                         ,parameter harden_p = 1
                         )
  (input   clk_i
    , input reset_i
    , input                     w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0]       w_data_i
    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i
    , output logic [width_p-1:0] r_data_o
  );

  logic [els_p-1:0] v_r;
  logic mem_r;
  always_ff @(posedge clk_i)
    if (reset_i)
      v_r <= '0;
    else if (w_v_i)
      v_r[w_addr_i] <= ~v_r[w_addr_i];

  bsg_dff
    #(.width_p(1))
    mem_reg
    (.clk_i(clk_i)
    ,.data_i(v_r[r_addr_i])
    ,.data_o(mem_r)
    );

  wire [1:0] v_li    = {r_v_i | w_v_i, r_v_i | w_v_i};
  wire [1:0] w_li    = {w_v_i & ~v_r[w_addr_i], w_v_i & v_r[w_addr_i]};
  wire [1:0][addr_width_lp-1:0]
             addr_li = {w_li[1] ? w_addr_i : r_addr_i, w_li[0] ? w_addr_i : r_addr_i};
  logic [1:0][width_p-1:0] data_lo;
  assign r_data_o    = mem_r ? data_lo[1] : data_lo[0];

   bsg_mem_1rw_sync_mask_write_bit
    #(.width_p(width_p)
     ,.els_p(els_p)
     ,.harden_p(harden_p)
     ) 
    mem0
     (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.v_i(v_li[0])
     ,.w_i(w_li[0])
     ,.addr_i(addr_li[0])
     ,.data_i(w_data_i)
     ,.w_mask_i('1)
     ,.data_o(data_lo[0])
     );

   bsg_mem_1rw_sync_mask_write_bit
    #(.width_p(width_p)
     ,.els_p(els_p)
     ,.harden_p(harden_p)
     )
    mem1
     (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.v_i(v_li[1])
     ,.w_i(w_li[1])
     ,.addr_i(addr_li[1])
     ,.data_i(w_data_i)
     ,.w_mask_i('1)
     ,.data_o(data_lo[1])
     );

endmodule

