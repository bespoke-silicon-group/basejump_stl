
/*
* bsg_mem_1rw_sync_mask_write_byte.sv
*
* 1-port byte write mask block ram for xilinx ultrascale or ultrascale plus FPGA
* Write mode: No-change | Read mode: No-change
* Note:
* There are 2 basic BRAM library primitives, RAMB18E2 and RAMB36E2 in Vivado
* There is 1 URAM library primitive, URAM288 in Vivado
* All of them support byte write enable
*
* Refer to Vivado Design Suite User Guide: Synthesis (UG901), Byte Write Enable (Block RAM)
* https://docs.xilinx.com/v/u/2019.1-English/ug901-vivado-synthesis
*
*
* By default, the tool selects which type of RAM to infer based upon heuristics
* that give the best results for most designs. Possible RAM mappings are:
*
* ┌───────────┬──────────┬──────┬─────┬─────┬─────┬──────────────────────────────┐
* │ RAM Type  │Primitives│ Size │PortA│PortB│wb_en│           Mapping            │
* ├───────────┼──────────┼──────┼─────┼─────┼─────┼──────────────────────────────┤
* │Distributed│  LUTRAM  │ N/A  │ N/A │ N/A │ N/A │Memory with small depth       │
* ├───────────┼──────────┼──────┼─────┼─────┼─────┼──────────────────────────────┤
* │           │ RAMB18E2 │ 18Kb │ W R │  -  │  Y  │Width narrower than 2 bytes   │
* │ Block RAM ├──────────┼──────┼─────┼─────┼─────┼──────────────────────────────┤
* │           │ RAMB36E2 │ 36Kb │ W R │  -  │  Y  │Width narrower than 4 bytes   │
* ├───────────┼──────────┼──────┼─────┼─────┼─────┼──────────────────────────────┤
* │ Ultra RAM │ URAM288  │288Kb │ W R │  -  │  Y  │Width wider than 4 bytes      │
* └───────────┴──────────┴──────┴─────┴─────┴─────┴──────────────────────────────┘
*
* To force the RAM into a specific type, use the RAM_STYLE attribute to tell
* Vivado synthesis to infer the target primitives:
*
* (* ram_style = "x" *) logic [data_size-1:0] mem [2**addr_size-1:0];
* Where x = [block, distributed, registers, ultra]
*
*/

`include "bsg_defines.sv"

// From vivado template
// Single-Port BRAM with Byte-wide Write Enable
// Read-First mode
// Single-process description
// Compact description of the write with a generate-for 
//   statement
// Column width and number of columns easily configurable
//
// bytewrite_ram_1b.v
//

module bytewrite_ram_1b (clk, ena, enb, we, addr, di, dout);

parameter SIZE = 1024; 
parameter ADDR_WIDTH = 10; 
parameter COL_WIDTH = 8; 
parameter NB_COL = 4;

input clk;
input ena;
input enb;
input [NB_COL-1:0] we;
input [ADDR_WIDTH-1:0] addr;
input [NB_COL*COL_WIDTH-1:0] di;
output reg [NB_COL*COL_WIDTH-1:0] dout;

reg [NB_COL*COL_WIDTH-1:0] RAM [SIZE-1:0];

always @(posedge clk)
begin
    if (ena)
        dout <= RAM[addr];
end

generate genvar i;
for (i = 0; i < NB_COL; i = i+1)
begin
always @(posedge clk)
begin
    if (enb & we[i])
        RAM[addr][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= di[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
    end 
end
endgenerate

endmodule

 module bsg_mem_1rw_sync_mask_write_byte #(parameter `BSG_INV_PARAM(data_width_p)
                           , parameter `BSG_INV_PARAM(els_p)
                           , parameter latch_last_read_p=0
                           , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                           , parameter write_mask_width_lp = data_width_p>>3
                           , parameter enable_clock_gating_p=0
                           , parameter harden_p=1
                           )
   ( input clk_i
    ,input reset_i

    ,input v_i
    ,input w_i

    ,input [addr_width_lp-1:0]       addr_i
    ,input [`BSG_SAFE_MINUS(data_width_p, 1):0]        data_i
     // for each bit set in the mask, a byte is written
    ,input [`BSG_SAFE_MINUS(write_mask_width_lp, 1):0] write_mask_i

    ,output logic [`BSG_SAFE_MINUS(data_width_p, 1):0] data_o
   );

     bytewrite_ram_1b #(
         .COL_WIDTH(8)
		 ,.NB_COL(write_mask_width_lp)
         ,.SIZE(els_p)
		 ,.ADDR_WIDTH(addr_width_lp)
     ) ram (
		.clk(clk_i)
        ,.ena(v_i & ~w_i)
        ,.enb(v_i &  w_i)
		,.we(write_mask_i)
		,.addr(addr_i)
        ,.di(data_i)
        ,.dout(data_o)
     );

 endmodule

 `BSG_ABSTRACT_MODULE(bsg_mem_1rw_sync_mask_write_byte)

