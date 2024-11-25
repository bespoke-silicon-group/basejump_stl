/*
* bsg_mem_1r1w_sync_mask_write_byte.sv
*
* 2-ports byte write mask block ram for xilinx ultrascale or ultrascale plus FPGA
* Write mode: No-change | Read mode: No-change
* Note:
* There are 2 basic BRAM library primitives, RAMB18E2 and RAMB36E2 in Vivado
* There is 1 URAM library primitive, URAM288 in Vivado
* All of them support byte write enable
*
* Refer to Vivado Design Suite User Guide: Synthesis (UG901), Byte Write Enable (Block RAM)
* https://docs.xilinx.com/v/u/2019.1-English/ug901-vivado-synthesis
*
* reads are synchronous
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
* │           │ RAMB18E2 │ 18Kb │  W  │  R  │  Y  │Width narrower than 2 bytes   │
* │ Block RAM ├──────────┼──────┼─────┼─────┼─────┼──────────────────────────────┤
* │           │ RAMB36E2 │ 36Kb │  W  │  R  │  Y  │Width narrower than 4 bytes   │
* ├───────────┼──────────┼──────┼─────┼─────┼─────┼──────────────────────────────┤
* │ Ultra RAM │ URAM288  │288Kb │  W  │  R  │  Y  │Width wider than 4 bytes      │
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

module bsg_mem_1r1w_sync_mask_write_byte #(parameter `BSG_INV_PARAM(width_p)
                                         , parameter `BSG_INV_PARAM(els_p)
                                         // semantics of "1" are write occurs, then read
                                         // the other semantics cannot be simulated on a hardened, non-simultaneous
                                         // 1r1w SRAM without changing timing.
                                         // fixme: change to write_then_read_same_addr_p
                                         , parameter read_write_same_addr_p=0
                                         , parameter latch_last_read_p=0 
                                         , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                                         , parameter harden_p=0
                                         , parameter disable_collision_warning_p=0
                                         , parameter write_mask_width_lp = width_p>>3
                                         , parameter enable_clock_gating_p=0
                                         )
   (input   clk_i
    , input reset_i

    , input                     w_v_i
    // for each bit set in the mask, a byte is written
   ,input [`BSG_SAFE_MINUS(write_mask_width_lp, 1):0] w_mask_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [`BSG_SAFE_MINUS(width_p, 1):0]       w_data_i

    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i

    , output logic [`BSG_SAFE_MINUS(width_p, 1):0] r_data_o
    );


  wire unused = reset_i;

  if (width_p == 0)
  begin: z
    wire unused0 = &{clk_i, w_v_i, w_mask_i, w_addr_i, w_data_i, r_v_i, r_addr_i};
    assign r_data_o = '0;
  end
  else
  begin: nz

  /* WARNING: Vivado will automatically choose between BRAM and URAM.
   *
   * We also can support URAM-only inference
   * (https://github.com/bespoke-silicon-group/basejump_stl/pull/564/files)
   * if we provide a hardened switch file which can choose between
   * BRAM and URAM inference based on depth and width parameterizations.
   */

    logic [width_p-1:0] mem [els_p-1:0];

  /* In order to synthesize into a byte masked BRAM/URAM, follow instruction in
   * Xilinx doc "UG901", Section "Byte Write Enable (Block RAM)"
   *
   * Note: must follow the example code line-to-line, Vivado is very inflexible on this
   */

    for(genvar i = 0; i < write_mask_width_lp; i++)
      begin: write
        always_ff @(posedge clk_i)
            if(w_v_i)
                if(w_mask_i[i])
                    mem[w_addr_i][i*8+:8] <= w_data_i[i*8+:8];
      end

    always_ff @(posedge clk_i)
        if(r_v_i)
            r_data_o <= mem[r_addr_i];

  end

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1r1w_sync_mask_write_byte)
