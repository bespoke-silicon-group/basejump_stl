package bsg_tag_pkg;
   typedef struct packed {
      logic clk;
                   //  op param
      logic op;    //   1   D   shift D
      logic param; //   0   0   nop (also "send", immediately after shift operation)
                   //   0   1   reset
} bsg_tag_s;


endpackage // bsg_tag_pkg


