module fs_pattern_gen #( parameter width_p = -1
                         , counter_bits_p = -1)
    (
        input clk
        ,input reset
        ,input enable

        ,output logic [width_p-1:0] pattern_o
    );

    logic [counter_bits_p-1:0] out_ctr_r, out_ctr_n;
    wire [counter_bits_p-1:0] out_ctr_r_p1 = out_ctr_r + 1'b1;

    always_ff @ (posedge clk)
    begin
      if (reset) begin
             out_ctr_r <= '0;
      end else if (enable) begin
             out_ctr_r <= out_ctr_n;
      end else begin
          out_ctr_r <= out_ctr_r;
      end
    end

    always_comb
    begin
        out_ctr_n = out_ctr_r_p1;
        pattern_o = out_ctr_r[0]
                    ? out_ctr_r[(1+(width_p+1))+:(width_p+1)]
                    : out_ctr_r[1+:(width_p+1)];
   end
endmodule
