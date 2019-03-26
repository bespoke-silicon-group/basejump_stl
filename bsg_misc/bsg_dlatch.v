module bsg_dlatch #(parameter width_p="inv")
  (input               en_i
  ,input [width_p-1:0] data_i
  ,output logic [width_p-1:0] data_o
  );

  always_ff @ (en_i or data_i)
    begin
      if (en_i)
        data_o <= data_i;
    end

endmodule

