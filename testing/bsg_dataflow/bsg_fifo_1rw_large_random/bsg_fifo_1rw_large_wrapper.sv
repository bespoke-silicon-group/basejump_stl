
module bsg_fifo_1rw_large_wrapper #(parameter width_p = 16
                            , parameter els_p = 8
                            )
    ( input                clk_i
    , input                reset_i

    , input                v_i
    , input [width_p-1:0]  data_i
    , input                enq_not_deq_i

    , output               full_o
    , output               empty_o
    , output [width_p-1:0] data_o
    );

    // Instantiate DUT
    bsg_fifo_1rw_large #(.width_p(width_p)
                                  ,.els_p(els_p)
                                  ) fifo
    (.*);

    // Bind Covergroups
    bind bsg_fifo_1rw_large bsg_fifo_1rw_large_cov
   #(.els_p(els_p)
    ) pc_cov
    (.*
    );

    // Dump Waveforms
    initial begin
        $fsdbDumpvars;
    end

endmodule
