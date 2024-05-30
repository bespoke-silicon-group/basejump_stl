
module bsg_serial_in_parallel_out_wrapper #(parameter width_p = 16
                                    , parameter els_p = 4
                                    , parameter out_els_p = els_p
                            )
    ( input                 clk_i
    , input               reset_i
    , input               valid_i
    , input [width_p-1:0] data_i
    , output              ready_and_o

    , output logic [out_els_p-1:0]                valid_o
    , output logic [out_els_p-1:0][width_p-1:0]   data_o

    , input  [$clog2(out_els_p+1)-1:0]            yumi_cnt_i
    );

    // Instantiate DUT
    bsg_serial_in_parallel_out #(.width_p(width_p)
                                  ,.els_p(els_p)
                                  ,.out_els_p(out_els_p)
                                  ) sipo
    (.*);

    // Bind Covergroups
    bind bsg_serial_in_parallel_out bsg_serial_in_parallel_out_cov
   #(.width_p(width_p)
    ,.els_p(els_p)
    ,.out_els_p(out_els_p)
    ) pc_cov
    (.*
    );

    // Dump Waveforms
    initial begin
        $fsdbDumpvars;
    end

endmodule
