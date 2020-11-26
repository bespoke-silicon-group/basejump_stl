
module bsg_mem_3r1w_sync #( parameter width_p = -1
                          , parameter els_p = -1
                          , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                          , parameter harden_p = 1
                          )
  ( input clk_i
  , input reset_i
  
  , input                     w_v_i
  , input [addr_width_lp-1:0] w_addr_i
  , input [width_p-1:0]       w_data_i
  
  , input                      r0_v_i
  , input [addr_width_lp-1:0]  r0_addr_i
  , output logic [width_p-1:0] r0_data_o
  
  , input                      r1_v_i
  , input [addr_width_lp-1:0]  r1_addr_i
  , output logic [width_p-1:0] r1_data_o
  
  , input                      r2_v_i
  , input [addr_width_lp-1:0]  r2_addr_i
  , output logic [width_p-1:0] r2_data_o
  );

  bsg_mem_1r1w_sync #(.width_p(width_p), .els_p(els_p), .harden_p(harden_p)) mem0
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.w_v_i(w_v_i)
     ,.w_addr_i(w_addr_i)
     ,.w_data_i(w_data_i)

     ,.r_v_i(r0_v_i)
     ,.r_addr_i(r0_addr_i)
     ,.r_data_o(r0_data_o)
     );

  bsg_mem_1r1w_sync #(.width_p(width_p), .els_p(els_p), .harden_p(harden_p)) mem1
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.w_v_i(w_v_i)
     ,.w_addr_i(w_addr_i)
     ,.w_data_i(w_data_i)

     ,.r_v_i(r1_v_i)
     ,.r_addr_i(r1_addr_i)
     ,.r_data_o(r1_data_o)
     );

  bsg_mem_1r1w_sync #(.width_p(width_p), .els_p(els_p), .harden_p(harden_p)) mem2
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.w_v_i(w_v_i)
     ,.w_addr_i(w_addr_i)
     ,.w_data_i(w_data_i)

     ,.r_v_i(r2_v_i)
     ,.r_addr_i(r2_addr_i)
     ,.r_data_o(r2_data_o)
     );

  //synopsys translate_off
  always_ff @(posedge clk_i)
    if (w_v_i)
    begin
      assert (w_addr_i < els_p)
        else $error("Invalid address %x to %m of size %x\n", w_addr_i, els_p);

      assert (~(r0_addr_i == w_addr_i && w_v_i && r0_v_i))
        else $error("%m: port 0 Attempt to read and write same address");

      assert (~(r1_addr_i == w_addr_i && w_v_i && r1_v_i))
        else $error("%m: port 1 Attempt to read and write same address");
      
      assert (~(r2_addr_i == w_addr_i && w_v_i && r2_v_i))
        else $error("%m: port 2 Attempt to read and write same address");
    end

  initial
    begin
      $display("## %L: instantiating width_p=%d, els_p=%d, harden_p=%d (%m)",width_p,els_p,harden_p);
    end
  //synopsys translate_on

endmodule
