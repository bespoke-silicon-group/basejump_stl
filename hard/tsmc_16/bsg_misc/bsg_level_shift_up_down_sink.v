// bsg_level_shift_up_down_sink
//
// An up-down level shifter can transform a signal to a higher or lower
// voltage. A sink level shifter is designed to be in the same power
// domain as the signals destination.
//
// Author: Scott Davidson
// Date:   4-4-17
//
module bsg_level_shift_up_down_sink #(parameter width_p = "inv")
(
  input        [width_p-1:0] A,
  output logic [width_p-1:0] Y
);

genvar i;

for (i = 0; i < width_p; i++)
  begin : n

    LVLU_X2N_A7P5PP96PTS_C18 level_shift_sink (
      .A(A[i]),
      .Y(Y[i])
    );

  end : n

endmodule
