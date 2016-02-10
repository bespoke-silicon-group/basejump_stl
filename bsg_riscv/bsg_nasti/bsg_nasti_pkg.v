
/*

  fsb_to_nasti_slave_connector
 
 bsg_fsb encoding of AXI4/NASTI requests

 opcode=0000100 --> read request addr
 opcode=0000101 --> write request addr
 opcode=0000110 --> write request data not last
 opcode=0000111 --> write request data last
 opcode=0001000 --> write response
 opcode=10<id5> --> read response not last
 opcode=11<id5> --> read response last

 */

package bsg_nasti_pkg;
   

typedef struct packed {
   // read address channel
   // or write address channel
   logic        v;
   logic [4:0] 	id;
   logic [2:0] 	size;
   logic [7:0] 	len;
   logic [31:0] addr;
}  bsg_nasti_addr_channel_s;

typedef struct packed {
   logic        v;
   logic [63:0] data;
   logic [7:0] 	strb; 	
   logic 	last;
} bsg_nasti_write_data_channel_s;

typedef struct packed {
   logic        v;
   logic [63:0] data;
   logic [1:0] 	resp;
   logic [4:0] 	id;
   logic 	last;
} bsg_nasti_read_data_channel_s;

typedef struct packed {
   logic       v;
   logic [1:0] resp;
   logic [4:0] id;
} bsg_nasti_write_response_channel_s;

endpackage
