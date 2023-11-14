task ui_write;
  input [ui_mask_width_lp*ui_burst_length_p-1:0] wmask;
  input  [ui_data_width_p*ui_burst_length_p-1:0] wdata;
  integer i;
  begin
    app_wdf_wren <= 1'b1;
    for(i=0;i<ui_burst_length_p;i++) begin
      app_wdf_data <= wdata >> (ui_data_width_p * i);
      app_wdf_mask <= wmask >> (ui_mask_width_lp * i);
      if(i==ui_burst_length_p-1) app_wdf_end <= 1'b1;
      do @(posedge ui_clk); while(!app_wdf_rdy);
    end
    app_wdf_wren <= 1'b0;
    app_wdf_end <= 1'b0;
  end
endtask

task ui_cmd;
  input app_cmd_e             cmd;
  input [ui_addr_width_p-1:0] addr;
  begin
    app_en <= 1'b1;
    app_addr <= addr;
    app_cmd <= cmd;
    do @(posedge ui_clk); while(!app_rdy);
    app_en <= 1'b0;
  end
endtask
