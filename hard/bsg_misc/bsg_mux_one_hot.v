`define bsg_mux_one_hot_gen_macro(words,bits)                   \
if (harden_p && els_p == words && width_p == bits)              \
begin: macro                                                    \
   bsg_rp_tsmc_250_mux_w``words``_b``bits w``words``_b``bits    \
     (.*                                                        \
      );                                                        \
end

module bsg_mux_one_hot #(parameter width_p="inv"
                         , els_p=1
			 , harden_p=1
                         )
   (
    input [els_p-1:0][width_p-1:0] data_i
    ,input [els_p-1:0] sel_one_hot_i
    ,output [width_p-1:0] data_o
    );

   wire [els_p-1:0][width_p-1:0]   data_masked;

   genvar                          i,j;

   `bsg_mux_one_hot_gen_macro(3,14)
else
  `bsg_mux_one_hot_gen_macro(3,4)
else
  begin : notmacro
     for (i = 0; i < els_p; i++)
       begin : mask
          assign data_masked[i] = data_i[i] & { width_p { sel_one_hot_i[i] } };
       end

     for (i = 0; i < width_p; i++)
       begin: reduce
          wire [els_p-1:0] gather;

          for (j = 0; j < els_p; j++)
            assign gather[j] = data_masked[j][i];

          assign data_o[i] = | gather;
       end
  end
endmodule // bsg_mux_one_hot


