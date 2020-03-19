`include "bsg_defines.v"
`ifndef DATA_WIDTH
  `define DATA_WIDTH 8
`endif
`ifndef ADDR_WIDTH
  `define ADDR_WIDTH 10
`endif

module testbench ();
  
  localparam width_p = `DATA_WIDTH;
  localparam data_width_p = width_p;  
  localparam mask_width_p = width_p>>3;
  localparam els_p=(1<<`ADDR_WIDTH);
  localparam addr_width_p=`ADDR_WIDTH;  

  // Clock generation
  logic clk;
  
  bsg_nonsynth_clock_gen
    #(.cycle_time_p(1000))
  clkgen
    (.o(clk));
  
  // Reset generation
  logic reset;
  bsg_nonsynth_reset_gen
    #(.reset_cycles_lo_p(0)
      ,.reset_cycles_hi_p(20))
  resetgen
    (.clk_i(clk)
     ,.async_reset_o(reset));  
      
  // DMA memory
  logic v_li;
  logic w_li;
  logic [addr_width_p-1:0] addr_li;
  logic [width_p-1:0] data_li;
  logic [mask_width_p-1:0] wmask_li;

  logic [width_p-1:0] data_lo;  
  
  bsg_nonsynth_mem_1rw_sync_mask_write_byte_dma
    #(.width_p(width_p)
      ,.els_p(els_p)
      ,.id_p(0)
      ,.init_mem_p(0))
  DUT
    (.clk_i(clk)
     ,.reset_i(reset)
     ,.v_i(v_li)
     ,.w_i(w_li)
     ,.addr_i(addr_li)
     ,.data_i(data_li)
     ,.w_mask_i(wmask_li)

     ,.data_o(data_lo)
     );

  // trace replay
  typedef struct packed {
    logic write_not_read;
    logic [addr_width_p-1:0] addr;
    logic [data_width_p-1:0] data;
    logic [mask_width_p-1:0] mask;
  } trace_s;
  
  localparam ring_width_p = $bits(trace_s);  
  localparam rom_addr_width_p = 20; // no need to get cute - 1M is plenty
  localparam rom_data_width_p=ring_width_p+4;
  
  logic [rom_addr_width_p-1:0] rom_addr_lo;
  logic [rom_data_width_p-1:0] rom_data_li;

  trace_s trace_lo;
  logic trace_v_lo;
  logic trace_done_lo;
  
  bsg_fsb_node_trace_replay
    #(.ring_width_p(ring_width_p)
      ,.rom_addr_width_p(rom_addr_width_p))
  tr
    (.clk_i(clk)
     ,.reset_i(reset)
     ,.en_i(1'b1)

     ,.v_i(1'b0)
     ,.data_i('0)
     ,.ready_o()

     ,.v_o(trace_v_lo)
     ,.data_o(trace_lo)
     ,.yumi_i(1'b1)
     
     ,.rom_addr_o(rom_addr_lo)
     ,.rom_data_i(rom_data_li)

     ,.done_o(trace_done_lo)
     ,.error_o()
     );  

  // ROM
  bsg_nonsynth_test_rom
    #(.data_width_p(rom_data_width_p)
      ,.addr_width_p(rom_addr_width_p)
      ,.filename_p(`BSG_STRINGIFY(`ROM_FILE)))
  rom
    (.addr_i(rom_addr_lo)
     ,.data_o(rom_data_li)
     );

  assign v_li    = trace_v_lo;
  assign w_li    = trace_lo.write_not_read;
  assign data_li = trace_lo.data;
  assign addr_li = trace_lo.addr;
  assign wmask_li = trace_lo.mask;

  always_ff @(posedge clk) begin
    if (trace_done_lo) $finish;    
  end

  trace_s trace_r;
  logic trace_v_r;
  
  always_ff @(posedge clk) begin
    trace_r <= trace_lo;
    trace_v_r <= trace_v_lo;    
  end
  
  // verify values
  logic [data_width_p-1:0] verify [els_p-1:0];    
  always_ff @(posedge clk) begin
    if (trace_v_lo) begin
      if (trace_lo.write_not_read) begin
        for (int i = 0; i < mask_width_p; i++) begin
          if (trace_lo.mask[i])
             verify[trace_lo.addr][i*8+:8] <= trace_lo.data[i*8+:8];
        end
      end
    end
    else if (reset) begin
      for (int i = 0; i < els_p; i++) begin
        verify[i] <= '0;
      end
    end
  end
  
  
  always_ff @(posedge clk) begin
    assert(reset // reset
           | ~(trace_v_r & ~trace_r.write_not_read) // didn't just read a value
           | (verify[trace_r.addr] == data_lo)) else // assert equal o/w
      $error("Mismatch: address=%08x, got %08x, expected %08x", 
             trace_r.addr, data_lo, verify[trace_r.addr]);
  end  
  
  if (0) begin
    always_ff @(posedge clk) begin
      if (v_li & w_li) begin
        $display("[DEBUG] Writing address = %08x, data = %08x, mask=%08x\n",
                 addr_li, data_li, wmask_li);
      
      end 
    end
  end  
  
endmodule

