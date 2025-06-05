`ifndef CMD_GAP_CYCLES
    `define CMD_GAP_CYCLES 0
`endif

`ifndef WRITE_GAP_CYCLES
    `define WRITE_GAP_CYCLES 0
`endif

`ifndef RANDOM_THRESHOLD
    `define RANDOM_THRESHOLD 0
`endif

task ui_write;
  input [ui_mask_width_lp*ui_burst_length_lp-1:0] wmask;
  input  [ui_data_width_p*ui_burst_length_lp-1:0] wdata;
  integer i;
  begin
    for(i=0;i<ui_burst_length_lp;i++) begin
      while(($urandom_range(0,99) < `RANDOM_THRESHOLD)) @(posedge ui_clk);
      app_wdf_wren <= 1;
      app_wdf_data <= wdata >> (ui_data_width_p * i);
      app_wdf_mask <= wmask >> (ui_mask_width_lp * i);
      
      if(i== ui_burst_length_lp-1) app_wdf_end <= 1'b1;

      do @(posedge ui_clk); while(!app_wdf_rdy);

      app_wdf_wren <= 1'b0;
      app_wdf_end <= 1'b0;
      repeat(`WRITE_GAP_CYCLES) @(posedge ui_clk);
    end
  end

endtask

task ui_cmd;
  input app_cmd_e             cmd;
  input [ui_addr_width_p-1:0] addr;
  begin
      while(($urandom_range(0,99) < `RANDOM_THRESHOLD)) repeat(ui_burst_length_lp) @(posedge ui_clk);
      app_en <= 1'b1;
      app_addr <= addr;
      app_cmd <= cmd;
      do @(posedge ui_clk); while(!app_rdy);
      app_en <= 1'b0;

      repeat(`CMD_GAP_CYCLES) @(posedge ui_clk);
  end
endtask
