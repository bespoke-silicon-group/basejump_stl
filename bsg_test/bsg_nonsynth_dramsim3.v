/**
 *  bsg_nonsynth_dramsim3.v
 *
 */

`include "bsg_defines.v"

module bsg_nonsynth_dramsim3
  #(parameter channel_addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter num_channels_p="inv"
    , parameter num_columns_p="inv"
    , parameter num_rows_p="inv"
    , parameter num_ba_p="inv"
    , parameter num_bg_p="inv"
    , parameter num_ranks_p="inv"
    , parameter address_mapping_p="inv"
    , parameter size_in_bits_p=0
    , parameter masked_p=0
    , parameter debug_p=0
    , parameter init_mem_p=0 // zero out values in memory at the beginning
    , parameter string config_p="inv"
    , parameter string trace_file_p="bsg_nonsynth_dramsim3_trace.txt"
    , parameter base_id_p=0 // use this for multiple instances of this module
    , parameter mem_addr_width_lp=$clog2(num_channels_p)+channel_addr_width_p
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
    , input [num_channels_p-1:0][data_mask_width_lp-1:0] mask_i
    , output logic [num_channels_p-1:0] data_yumi_o 

    , output logic [num_channels_p-1:0] data_v_o
    , output logic [num_channels_p-1:0][data_width_p-1:0] data_o
    , output logic [num_channels_p-1:0][channel_addr_width_p-1:0] read_done_ch_addr_o

    // this is for debugging/measuring performance.
    // its usage is optional.
    , output logic [num_channels_p-1:0] write_done_o
    , output logic [num_channels_p-1:0][channel_addr_width_p-1:0] write_done_ch_addr_o
  );


  // DPI
  import "DPI-C" context function 
    bit     bsg_dramsim3_init(input int     num_channels,
                              input int     data_width,
                              input longint size,
                              input int     num_columns,
                              string        config_file);
  
  import "DPI-C" context function 
    bit     bsg_dramsim3_send_write_req(input longint addr);
  
  import "DPI-C" context function 
    bit     bsg_dramsim3_send_read_req(input longint addr);
  
  import "DPI-C" context function 
    bit     bsg_dramsim3_get_read_done(int ch);
  
  import "DPI-C" context function 
    longint bsg_dramsim3_get_read_done_addr(int ch);

  import "DPI-C" context function 
    bit     bsg_dramsim3_get_write_done(int ch);
  
  import "DPI-C" context function 
    longint bsg_dramsim3_get_write_done_addr(int ch);
  
  import "DPI-C" context function
    void    bsg_dramsim3_tick();
  
  import "DPI-C" context function 
    void    bsg_dramsim3_exit();
     bit    init;

  initial begin
    init = bsg_dramsim3_init(num_channels_p, data_width_p, size_in_bits_p, num_columns_p, config_p);
  end

  // memory addr
  logic [num_channels_p-1:0][mem_addr_width_lp-1:0] mem_addr;

  for (genvar i = 0; i < num_channels_p; i++) begin
    bsg_nonsynth_dramsim3_map
      #(.channel_addr_width_p(channel_addr_width_p)
        ,.data_width_p(data_width_p)
        ,.num_channels_p(num_channels_p)
        ,.num_columns_p(num_columns_p)
        ,.num_rows_p(num_rows_p)
        ,.num_ba_p(num_ba_p)
        ,.num_bg_p(num_bg_p)
        ,.num_ranks_p(num_ranks_p)
        ,.address_mapping_p(address_mapping_p)
        ,.channel_select_p(i)
        ,.debug_p(debug_p))
    map
      (.ch_addr_i(ch_addr_i[i])
       ,.mem_addr_o(mem_addr[i]));
  end


  // request yumi
  logic [num_channels_p-1:0] yumi_lo;
  for (genvar i = 0; i < num_channels_p; i++)
    assign yumi_o[i] = yumi_lo[i] & v_i[i];
    
  // read channel signal
  logic [num_channels_p-1:0] read_done;
  logic [num_channels_p-1:0][mem_addr_width_lp-1:0] read_done_addr;
  logic [num_channels_p-1:0][channel_addr_width_p-1:0] read_done_ch_addr;

  for (genvar i = 0; i < num_channels_p; i++) begin
    bsg_nonsynth_dramsim3_unmap
     #(.channel_addr_width_p(channel_addr_width_p)
       ,.data_width_p(data_width_p)
       ,.num_channels_p(num_channels_p)
       ,.num_columns_p(num_columns_p)
       ,.num_rows_p(num_rows_p)
       ,.num_ba_p(num_ba_p)
       ,.num_bg_p(num_bg_p)
       ,.num_ranks_p(num_ranks_p)
       ,.address_mapping_p(address_mapping_p)
       ,.channel_select_p(i)
       ,.debug_p(debug_p))
    unmap_read_done_addr
      (.mem_addr_i(read_done_addr[i])
       ,.ch_addr_o(read_done_ch_addr[i]));

  end

  // write channel signal
  logic [num_channels_p-1:0][mem_addr_width_lp-1:0] write_done_addr;

  for (genvar i = 0; i < num_channels_p; i++) begin

    bsg_nonsynth_dramsim3_unmap
     #(.channel_addr_width_p(channel_addr_width_p)
       ,.data_width_p(data_width_p)
       ,.num_channels_p(num_channels_p)
       ,.num_columns_p(num_columns_p)
       ,.num_rows_p(num_rows_p)
       ,.num_ba_p(num_ba_p)
       ,.num_bg_p(num_bg_p)
       ,.num_ranks_p(num_ranks_p)
       ,.address_mapping_p(address_mapping_p)
       ,.channel_select_p(i)
       ,.debug_p(debug_p))
    unmap_write_done_addr
      (.mem_addr_i(write_done_addr[i])
       ,.ch_addr_o(write_done_ch_addr_o[i]));

  end


  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      read_done <= '0;
      read_done_addr <= '0;
      write_done_o <= '0;
      write_done_addr <= '0;
    end
    else begin

      // getting read/write done
      for (integer i = 0; i < num_channels_p; i++) begin
        read_done[i] <= bsg_dramsim3_get_read_done(i);
        if (bsg_dramsim3_get_read_done(i))
          read_done_addr[i] <= bsg_dramsim3_get_read_done_addr(i);

        write_done_o[i] <= bsg_dramsim3_get_write_done(i);
        if (bsg_dramsim3_get_write_done(i))
          write_done_addr[i] <= bsg_dramsim3_get_write_done_addr(i);
      end

      // tick
      bsg_dramsim3_tick();

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
              yumi_lo[i] <= bsg_dramsim3_send_write_req(mem_addr[i]);
            else
              yumi_lo[i] <= 1'b0;
          end
          else begin
            yumi_lo[i] <= bsg_dramsim3_send_read_req(mem_addr[i]);
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
  logic [num_channels_p-1:0][data_mask_width_lp-1:0] mask_li;

  for (genvar i = 0; i < num_channels_p; i++) begin: channels
    bsg_nonsynth_mem_1r1w_sync_mask_write_byte_dma
      #(.width_p(data_width_p)
        ,.els_p((size_in_bits_p/num_channels_p)/data_width_p)
        ,.id_p(base_id_p+i)
        ,.init_mem_p(init_mem_p))
    channel
      (.clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.r_v_i(read_v_li[i])
      ,.r_addr_i(read_addr_li[i][channel_addr_width_p-1:byte_offset_width_lp])

      ,.w_v_i(write_v_li[i])
      ,.w_addr_i(ch_addr_i[i][channel_addr_width_p-1:byte_offset_width_lp])
      ,.w_data_i(data_i[i])
      ,.w_mask_i(mask_li[i])

      ,.data_o(data_o[i])
    );

    assign read_v_li[i] = read_done[i];
    assign read_addr_li[i] = read_done_ch_addr[i];

    assign mask_li[i] = masked_p ? mask_i[i] : '1;
  
    assign write_v_li[i] = data_v_i[i] & v_i[i] & write_not_read_i[i] & yumi_o[i];
    assign data_yumi_o[i] = data_v_i[i] & write_not_read_i[i] & yumi_o[i];
  
  end

  // aligning valid and address with the output data
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      data_v_o <= '0;
      read_done_ch_addr_o <= '0;
    end
    else begin
      data_v_o <= read_v_li;
      read_done_ch_addr_o <= read_done_ch_addr;
    end
  end

  // debugging
   integer file;
   initial begin
      if (debug_p) begin
         file = $fopen(trace_file_p, "w");
         $fwrite(file, "request,time,channel,write_not_read,address\n");
      end
   end

  always_ff @ (posedge clk_i) begin
    if (~reset_i & debug_p) begin
      for (integer i = 0; i < num_channels_p; i++) begin
        if (yumi_o[i])
          begin
             $display("req sent:  t=%012t, channel=%0d, write_not_read=%0b, addr=%010x", $time, i, write_not_read_i[i], ch_addr_i[i]);
             $fwrite(file, "send,%t,%0d,%0b,%08h\n", $time, i, write_not_read_i[i], ch_addr_i[i]);
          end
        if (read_done[i])
          begin
             $display("read done: t=%012t, channel=%0d, addr=%010x", $time, i, read_done_ch_addr[i]);
             $fwrite(file, "recv,%t,%0d,,%08h\n", $time, i, read_done_ch_addr[i]);
          end
        if (write_done_o[i])
          begin
             $display("write done: t=%012t, channel=%0d, addr=%010x", $time, i, write_done_ch_addr_o[i]);
          end
      end
    end
  end

  // final
  final begin
    bsg_dramsim3_exit();
    $fclose(file);
  end

endmodule
