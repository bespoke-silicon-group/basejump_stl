
`include "bsg_defines.sv"

// From Vivado inference template
// Single-Port Block RAM Write-First Mode (recommended template)
// File: rams_sp_wf.v
module rams_sp_wf #(parameter width_p=1,
                    parameter els_p=1,
                    parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p))
(clk, we, en, addr, di, dout);
input clk; 
input we; 
input en;
input [addr_width_lp-1:0] addr; 
input [width_p-1:0] di; 
output [width_p-1:0] dout;
reg [width_p-1:0] RAM [els_p-1:0];
reg [width_p-1:0] dout;

always @(posedge clk)
begin
  if (en)
  begin
    if (we)
      begin
        RAM[addr] <= di;
        dout <= di;
      end
   else
    dout <= RAM[addr];
  end
end
endmodule

 module bsg_mem_1rw_sync #(parameter `BSG_INV_PARAM(width_p)
                           , parameter `BSG_INV_PARAM(els_p)
                           , parameter latch_last_read_p=0
                           , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                           , parameter verbose_if_synth_p=0
                           , parameter enable_clock_gating_p=0
                           , parameter harden_p=1
                           )
    (input   clk_i
     , input reset_i
     , input [`BSG_SAFE_MINUS(width_p,1):0] data_i
     , input [addr_width_lp-1:0] addr_i
     , input v_i
     , input w_i
     , output logic [`BSG_SAFE_MINUS(width_p,1):0]  data_o
     );

     rams_sp_wf #(
         .width_p(width_p)
         ,.els_p(els_p)
     ) ram (
         .clk(clk_i)
         ,.we(w_i)
         ,.en(v_i)
         ,.addr(addr_i)
         ,.di(data_i)
         ,.dout(data_o)
     );

 endmodule

 `BSG_ABSTRACT_MODULE(bsg_mem_1rw_sync)

