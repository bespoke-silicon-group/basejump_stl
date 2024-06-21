

`include "bsg_defines.sv"

// From Vivado inference template
// Simple Dual-Port Block RAM with One Clock
// File: simple_dual_one_clock.v

module simple_dual_one_clock #(parameter width_p=1,
								parameter els_p=1,
								parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p))
(clk,ena,enb,wea,addra,addrb,dia,dob);

input clk,ena,enb,wea;
input [addr_width_lp-1:0] addra,addrb;
input [width_p-1:0] dia;
output [width_p-1:0] dob;
reg [width_p-1:0] ram [els_p-1:0];
reg [width_p-1:0] doa,dob;

always @(posedge clk) begin 
 if (ena) begin
    if (wea)
        ram[addra] <= dia;
 end
end

always @(posedge clk) begin 
  if (enb)
    dob <= ram[addrb];
end

endmodule

   module bsg_mem_1r1w_sync
     #(parameter `BSG_INV_PARAM(width_p)
       , parameter `BSG_INV_PARAM(els_p)
       , parameter read_write_same_addr_p=0
       , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
       , parameter harden_p=1
       , parameter latch_last_read_p=0
       , parameter disable_collision_warning_p=0
       , parameter enable_clock_gating_p=0
     )
     (
       input clk_i
       , input reset_i

       , input w_v_i
       , input [addr_width_lp-1:0] w_addr_i
       , input [`BSG_SAFE_MINUS(width_p,1):0] w_data_i

       , input r_v_i
       , input [addr_width_lp-1:0] r_addr_i

       , output logic [`BSG_SAFE_MINUS(width_p,1):0] r_data_o
     );

	simple_dual_one_clock #(
		.width_p(width_p)
		,.els_p(els_p)
	) ram (
		.clk(clk_i)
		,.ena(w_v_i)
		,.enb(r_v_i)
		,.wea(w_v_i)
		,.addra(w_addr_i)
		,.addrb(r_addr_i)
		,.dia(w_data_i)
		,.dob(r_data_o)
	);

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1r1w_sync)

