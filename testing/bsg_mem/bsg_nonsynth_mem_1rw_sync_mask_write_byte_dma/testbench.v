`include "bsg_defines.v"
module testbench ();


  localparam width_p = 8;
  localparam data_width_p = width_p;  
  localparam mask_width_p = width_p>>3;
  localparam els_p=1024;
  localparam addr_width_p=`BSG_SAFE_CLOG2(els_p);

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

  logic data_v_lo;  
  logic [width_p-1:0] data_lo;  
  
  bsg_nonsynth_mem_1rw_sync_mask_write_byte_dma
    #(.width_p(width_p)
      ,.els_p(els_p)
      ,.id_p(0))
  DUT
    (.clk_i(clk)
     ,.reset_i(reset)
     ,.v_i(v_li)
     ,.w_i(w_li)
     ,.addr_i(addr_li)
     ,.data_i(data_li)
     ,.w_mask_i(wmask_li)

     ,.data_v_o(data_v_lo)
     ,.data_o(data_lo)
     );

  // Assoc array mmemory
  logic assoc_v_li;
  logic assoc_w_li;
  logic [addr_width_p-1:0] assoc_addr_li;
  logic [data_width_p-1:0] assoc_data_li;
  logic [mask_width_p-1:0] assoc_mask_li;
  logic [data_width_p-1:0] assoc_data_lo;

  bsg_nonsynth_mem_1rw_sync_mask_write_byte_assoc
    #(.data_width_p(data_width_p)
      ,.addr_width_p(addr_width_p))
  assoc
    (.clk_i(clk)
     ,.reset_i(reset)
     ,.v_i(assoc_v_li)
     ,.w_i(assoc_w_li)
     ,.addr_i(assoc_addr_li)
     ,.data_i(assoc_data_li)
     ,.write_mask_i(assoc_mask_li)
     ,.data_o(assoc_data_lo));
  
  // trace replay
  typedef struct packed {
    logic write_not_read;
    logic [addr_width_p-1:0] addr;
    logic [data_width_p-1:0] data;
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
      ,.filename_p("test.tr"))
  rom
    (.addr_i(rom_addr_lo)
     ,.data_o(rom_data_li)
     );

  assign v_li    = trace_v_lo;
  assign w_li    = trace_lo.write_not_read;
  assign data_li = trace_lo.data;
  assign addr_li = trace_lo.addr;
  assign wmask_li = '1;

  always_ff @(posedge clk) begin
    if (trace_done_lo) $finish;    
  end
  
  // verify that semantics match associative array memory
  assign assoc_v_li = trace_v_lo;
  assign assoc_w_li = trace_lo.write_not_read;
  assign assoc_data_li = trace_lo.data;
  assign assoc_addr_li = trace_lo.addr;
  assign assoc_mask_li = '1;  

  logic v_r;
  logic w_r;

  always_ff @(posedge clk) begin
    v_r <= trace_v_lo;
    w_r <= trace_lo.write_not_read;
  end  
    
  always_ff @(negedge clk) begin
    if (v_r)
      assert(assoc_data_lo == data_lo) else $error("Mismatch");
  end  
  
endmodule

