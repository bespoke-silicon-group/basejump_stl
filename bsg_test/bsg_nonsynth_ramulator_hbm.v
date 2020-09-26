/**
 *  bsg_nonsynth_ramulator_hbm.v
 *
 */


`include "bsg_defines.v"

module bsg_nonsynth_ramulator_hbm
  #(parameter channel_addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter num_channels_p="inv"

    , parameter debug_p=0
    , parameter init_mem_p=0 // zero out values in memory at the beginning

    , parameter lg_num_channels_lp=`BSG_SAFE_CLOG2(num_channels_p)
    , parameter data_mask_width_lp=(data_width_p>>3)
    , parameter byte_offset_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)
  )
  (
    input clk_i
    , input reset_i

    , input [num_channels_p-1:0] v_i
    , input [num_channels_p-1:0] write_not_read_i
    , input [num_channels_p-1:0][channel_addr_width_p-1:0] ch_addr_i
    , output logic [num_channels_p-1:0] yumi_o

    , input [num_channels_p-1:0] data_v_i
    , input [num_channels_p-1:0][data_width_p-1:0] data_i
    , output logic [num_channels_p-1:0] data_yumi_o 

    , output logic [num_channels_p-1:0] data_v_o
    , output logic [num_channels_p-1:0][data_width_p-1:0] data_o
    , output logic [num_channels_p-1:0][channel_addr_width_p-1:0] ch_addr_o
  );


  // DPI
  import "DPI-C" context function void init_hbm();
  import "DPI-C" context function bit send_write_req(input longint addr);
  import "DPI-C" context function bit send_read_req(input longint addr);
  import "DPI-C" context function bit get_read_done(int ch);
  import "DPI-C" context function longint get_read_done_addr(int ch);
  import "DPI-C" context function void tick();
  import "DPI-C" context function void finish_hbm();

  initial begin
    init_hbm();
  end

  // memory addr
  logic [num_channels_p-1:0][lg_num_channels_lp+channel_addr_width_p-1:0] mem_addr;

  for (genvar i = 0; i < num_channels_p; i++) begin
    assign mem_addr[i] = {
      ch_addr_i[i][channel_addr_width_p-1:byte_offset_width_lp],
      (lg_num_channels_lp)'(i),
      {byte_offset_width_lp{1'b0}}
    };
  end
  
  // request yumi
  logic [num_channels_p-1:0] yumi_lo;
  for (genvar i = 0; i < num_channels_p; i++)
    assign yumi_o[i] = yumi_lo[i] & v_i[i];
    
  // read channel signal
  logic [num_channels_p-1:0] read_done;
  logic [num_channels_p-1:0][lg_num_channels_lp+channel_addr_width_p-1:0] read_done_addr;
  logic [num_channels_p-1:0][channel_addr_width_p-1:0] read_done_ch_addr;

  for (genvar i = 0; i < num_channels_p; i++) begin
    assign read_done_ch_addr[i] = {
      read_done_addr[i][channel_addr_width_p+lg_num_channels_lp-1:byte_offset_width_lp+lg_num_channels_lp],
      {byte_offset_width_lp{1'b0}}
    };
  end
  
  assign ch_addr_o = read_done_ch_addr;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      read_done <= '0;
      read_done_addr <= '0;
    end
    else begin

      // getting read done
      for (integer i = 0; i < num_channels_p; i++) begin
        read_done[i] = get_read_done(i);
        if (read_done[i])
          read_done_addr[i] = get_read_done_addr(i);
      end

      // tick
      tick();

    end
  end
  
  always_ff @ (negedge clk_i) begin
    if (reset_i) begin
      yumi_lo <= '0;
    end
    else begin
      // sending requests
      for (integer i = 0; i < num_channels_p; i++) begin
        if (v_i[i]) begin
          if (write_not_read_i[i]) begin
            if (data_v_i[i])
              yumi_lo[i] <= send_write_req(mem_addr[i]);
            else
              yumi_lo[i] <= 1'b0;
          end
          else begin
            yumi_lo[i] <= send_read_req(mem_addr[i]);
          end
        end
        else begin
          yumi_lo[i] <= 1'b0;
        end
      end
    end
  end

  // channels
  logic [num_channels_p-1:0] read_v_li;
  logic [num_channels_p-1:0][channel_addr_width_p-1:0] read_addr_li;
  logic [num_channels_p-1:0] write_v_li;

  for (genvar i = 0; i < num_channels_p; i++) begin

    bsg_nonsynth_test_dram_channel #(
      .channel_addr_width_p(channel_addr_width_p)
      ,.data_width_p(data_width_p)
      ,.init_mem_p(init_mem_p)
    ) channel (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
     
      ,.read_v_i(read_v_li[i])
      ,.read_addr_i(read_addr_li[i])
      ,.write_v_i(write_v_li[i])    
      ,.write_addr_i(ch_addr_i[i])
 
      ,.data_v_i(data_v_i[i])
      ,.data_i(data_i[i])
      ,.data_yumi_o(data_yumi_o[i])

      ,.data_v_o(data_v_o[i])
      ,.data_o(data_o[i])
    );

    assign read_v_li[i] = read_done[i];
    assign read_addr_li[i] = read_done_ch_addr[i];
  
    assign write_v_li[i] = v_i[i] & write_not_read_i[i] & yumi_o[i];

  end


  // debugging
   integer file;
   initial begin
      if (debug_p) begin
         file = $fopen("ramulator_access_trace.txt");
         $fwrite(file, "request,time,channel,write_not_read,address\n");
      end
   end

  always_ff @ (posedge clk_i) begin
    if (~reset_i & debug_p) begin
      for (integer i = 0; i < num_channels_p; i++) begin
        if (yumi_o[i])
          begin
             $display("req sent:  t=%012t, channel=%0d, write_not_read=%0b, addr=%032b", $time, i, write_not_read_i[i], ch_addr_i[i]);
             $fwrite(file, "send,%t,%0d,%0b,%08h\n", $time, i, write_not_read_i[i], ch_addr_i[i]);
          end
        if (read_done[i])
          begin
             $display("read done: t=%012t, channel=%0d, addr=%32b", $time, i, read_done_ch_addr[i]);
             $fwrite(file, "recv,%t,%0d,,%08h\n", $time, i, read_done_ch_addr[i]);
          end
      end
    end
  end



  // final
  final begin
    finish_hbm();
    $fclose(file);
  end

endmodule
