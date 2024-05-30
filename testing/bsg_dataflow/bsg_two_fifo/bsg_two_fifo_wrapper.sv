
module bsg_two_fifo_wrapper #(parameter width_p = 16
                            , parameter allow_enq_deq_on_full_p = 1 // Makes it harder to test
                            )
    ( input clk_i
    , input reset_i

    // input side
    , output              ready_param_o // early
    , input [width_p-1:0] data_i  // late
    , input               v_i     // late

    // output side
    , output              v_o     // early
    , output[width_p-1:0] data_o  // early
    , input               yumi_i  // late
    );

    // Instantiate DUT
    bsg_two_fifo #(.width_p(width_p)
                  ,.allow_enq_deq_on_full_p(allow_enq_deq_on_full_p)
                ) fifo
    (.*);

    // Bind Covergroups
    bind bsg_two_fifo bsg_two_fifo_cov 
    #(
        .allow_enq_deq_on_full_p(allow_enq_deq_on_full_p)
    )
        pc_cov
    (.*);

    // Dump Waveforms
    initial begin
        $fsdbDumpvars;
    end

endmodule
