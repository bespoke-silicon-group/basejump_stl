
module bsg_imul_iterative_wrapper #(parameter width_p = 32)
    ( input                clk_i
    , input                reset_i

    , input                v_i
    , output               ready_and_o
    , input [width_p-1:0]  opA_i
    , input                signed_opA_i
    , input [width_p-1:0]  opB_i
    , input                signed_opB_i

    , input                gets_high_part_i

    , output               v_o
    , output [width_p-1:0] result_o
    , input                yumi_i
    );

    // Instantiate DUT
    bsg_imul_iterative #(.width_p(width_p)) mul
    (.*);

    // Bind Covergroups
    bind bsg_imul_iterative bsg_imul_iterative_cov
    #(.width_p(width_p))
    pc_cov
    (.*
    );

    // Dump Waveforms
    initial begin
        $fsdbDumpvars;
    end

endmodule
