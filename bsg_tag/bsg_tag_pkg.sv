package bsg_tag_pkg;
   typedef struct packed {
      logic clk;
                   //  op param
      logic op;    //   1   D   shift D
      logic param; //   0   0   nop (also "send", immediately after shift operation)
                   //   0   1   reset

      logic en;    // this signal disables thru-transmit of new values
  } bsg_tag_s;

  typedef bsg_tag_s bsg_tag_lines_s;
  localparam bsg_tag_local_els_gp = $bits(bsg_tag_lines_s) / $bits(bsg_tag_s);

endpackage // bsg_tag_pkg


