// Bitwise extension for mux operation

module bsg_mux_bitwise #(parameter width_p = -1)
                        ( input        [width_p-1:0] select
                        , input        [width_p-1:0] A
                        , input        [width_p-1:0] B
                        , output logic [width_p-1:0] out
                        );

integer i;

always_comb
  for (i = 0; i < width_p; i = i + 1)
    if (select[i])
      out[i] = A[i];
    else
      out[i] = B[i];
 
endmodule
