/**
 *    bsg_alloc_wavefront_cell.sv
 */


module bsg_alloc_wavefront_cell
  (
    input x_i
    , input y_i
    , input priority_i
    , input req_i
    , output logic y_o
    , output logic x_o
    , output logic grant_o
  );

  wire yp = y_i | priority_i;
  wire xp = x_i | priority_i;
   
  wire grant = yp & xp & req_i;
  assign grant_o = grant;

  assign x_o = xp & ~grant;
  assign y_o = yp & ~grant;

endmodule


`BSG_ABSTRACT_MODULE(bsg_alloc_wavefront_cell)
