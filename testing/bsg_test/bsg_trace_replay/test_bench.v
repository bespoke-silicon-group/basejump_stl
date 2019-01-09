module test_bench;


logic clk_i, reset_i, reset_async;
//----------------------------------------------
//clock 
localparam cycle_time_lp = 50;
bsg_nonsynth_clock_gen
        #( .cycle_time_p(cycle_time_lp)
         ) clock_gen
        ( .o(clk_i)
        );
//-----------------------------------------------
//reset 
bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                         , .reset_cycles_lo_p(1)
                         , .reset_cycles_hi_p(10)
                         )  reset_gen
                         (  .clk_i        
                          , .async_reset_o(reset_async)
                         );

always_ff@(posedge clk_i) reset_i <= reset_async;

localparam payload_width_lp  =32;
localparam rom_addr_width_lp = 6;

wire [payload_width_lp-1:0]     sti_data_lo, res_data_li;
wire [payload_width_lp + 4 -1:0]sti_rom_data_li, res_rom_data_li;
wire [rom_addr_width_lp-1:0]    sti_rom_addr_lo, res_rom_addr_lo;

bsg_trace_replay
  #( .payload_width_p ( payload_width_lp ) 
    ,.rom_addr_width_p( rom_addr_width_lp)
    ) tr_sti
   ( 
     .*
    ,.en_i ( 1'b1)

    // input channel
    ,.v_i       (1'b0)
    ,.data_i    (0)
    ,.ready_o   (1'b1)

    // output channel
    ,.v_o       (sti_v_lo)
    ,.data_o    (sti_data_lo)
    ,.yumi_i    (sti_yumi_li)

    // connection to rom
    // note: asynchronous reads

    ,.rom_addr_o (sti_rom_addr_lo)
    ,.rom_data_i (sti_rom_data_li)

    // true outputs
    ,.done_o     (sti_done_lo)
    ,.error_o    (sti_error_lo)
    );

stimulus_rom  #( .width_p       ( 32 + 4)
                ,.addr_width_p  ( 6 )
               ) sti_rom
        (  .addr_i (sti_rom_addr_lo )
          ,.data_o (sti_rom_data_li )
        );

bsg_trace_replay
  #( .payload_width_p ( 32 ) 
    ,.rom_addr_width_p( 6  )
    ) tr_res
   ( 
    .en_i ( 1'b1)

    // input channel
    ,.v_i       (res_v_li       )
    ,.data_i    (res_data_li    )
    ,.ready_o   (res_ready_lo   )

    // output channel
    ,.v_o       ()
    ,.data_o    ()
    ,.yumi_i    (1'b0)

    // connection to rom
    // note: asynchronous reads

    ,.rom_addr_o (res_rom_addr_lo)
    ,.rom_data_i (res_rom_data_li)

    // true outputs
    ,.done_o     (res_done_lo)
    ,.error_o    (res_error_lo)
    ,.*
    );

response_rom  #( .width_p       ( 32 + 4)
                ,.addr_width_p  ( 6 )
               ) res_rom
        (  .addr_i (res_rom_addr_lo )
          ,.data_o (res_rom_data_li )
        );

dut #(  .payload_width_p ( 80 ) ) dut_inst 
     (  .v_i     (sti_v_lo       )
       ,.data_i  (sti_data_lo    )
       ,.ready_o (dut_ready_lo   )

       ,.v_o     (res_v_li       )
       ,.data_o  (res_data_li    )
       ,.ready_i (res_ready_lo   )
       ,.*
     );

assign sti_yumi_li = sti_v_lo & dut_ready_lo;

always@(negedge clk_i ) begin
        if( res_done_lo ) $finish;
end

endmodule
