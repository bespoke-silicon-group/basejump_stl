// this is a partial packet header, which should always go at the bottom bits of a packet
`define declare_bsg_wormhole_router_header_s(in_cord_width,in_len_width,in_struct_name) \
typedef struct packed {                 \
  logic [in_len_width-1:0]    len;      \
  logic [in_cord_width-1:0 ]  cord;     \
} in_struct_name

module bsg_wormhole_router   
  #(parameter packet_width_p        = "inv"
   ,parameter dims_p                = 2
   ,parameter coord_width_p         = "inv"
   ,parameter actual_cord_widths_p  = { 0, 0}
   ,parameter len_width_p     = "inv"
   ,parameter dirs_lp         = dims_p*2+1;
   )
  
  (input clk_i
  ,input reset_i
  
  // Traffics
  ,input  [dirs_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_i
  ,output [dirs_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_o
  
  // Configuration
   ,input [coord_width_p-1:0] my_cord_i
  );

  localparam input_dirs_lp  = dirs_lp;
  localparam output_dirs_lp = dirs_lp;  

  `declare_bsg_wormhole_router_header_s(len_width_p, x_cord_width_p, y_cord_width_p, bsg_wormhole_router_header_s);
  
  bsg_wormhole_router_header_s hdr;

  //                                                        SNEWP (output)
  localparam [dirs_p-1:0][dirs_p-1:0] matrix_in_out = { 5'b_11111  // P (input)
                                                       ,5'b_11101  // W
                                                       ,5'b_11011  // E
                                                       ,5'b_10001  // N
                                                       ,5'b_01001  // S
                                                      };

  //                                                       SNEWP (input)
  localparam [dirs_p-1:0][dirs_p-1:0] matrix_out_in = { 5'b11111  // P (output)                                                                                                  ,5'b00101  // W 
                                                       ,5'b00011  // E
                                                       ,5'b00111  // N
                                                       ,5'b01111  // S
                                                      };

  ifndef SYNTHESIS
    localparam[dirs_p-1:0][dirs_p-1:0] matrix_out_in_transpose;
  
    bsg_transpose #(.width_p(dirs_lp),.els_p(dirs_lp)) (.i(matrix_out_in)
                                                       ,.o(matrix_out_in_transpose)
                                                       );
                                                      
    initial 
      begin
        #1000;
        assert (matrix_in_out == matrix_out_in_transpose)
          else $error("inconsistent matrixes");
      end
  endif
  
  // we collect the information for each FIFO here
  wire [input_dirs_lp-1:0][width_p-1:0] fifo_data_lo;
  wire [input_dirs_lp-1:0]              fifo_valid_lo;
  
  // one for each input; it broadcasts that it is finished to all of the outputs
  wire [dirs_lp-1:0] releases;

  // from each input to each output
  wire [dirs_lp-1:0][dirs_lp-1:0] reqs,     reqs_transpose;

  // from each output to each input
  wire [dirs_lp-1:0][dirs_lp-1:0] yumis,    yumis_transpose;

  genvar i,j;
  
  for (i = 0; i < input_dirs_lp; i=i+1)
    begin: in_ch
      localparams output_dirs_sparse_lp = `BSG_COUNTONES_SYNTH(matrix_in_out[i]);
      
      bsg_ready_and_link_sif_s link_i_cast, link_o_cast;
      
      // live decoding of output dirs from header
      
      wire [output_dirs_sparse_lp-1:0] decoded_dest_lo;
      wire [output_dirs_sparse_lp-1:0] reqs_lo, yumis_li;
     
      bsg_concentrate_static #(.pattern_els_p(matrix_in_out[i])) conc
      (.i(yumis_transpose[i])
       ,.o(yumis_li)
      );    
      
      wire any_yumi = | yumis_li;
      
      assign link_i_cast = link_i[i];
      assign link_o[i] = link_o_cast;
      
      bsg_two_fifo #(.width_p(width_p))
  		(.clk_i
   		,.reset_i
        ,.ready_o(link_o_cast[i].ready_and_rev)
        ,.data_i (link_i_cast[i].data)
        ,.v_i    (link_i_cast[i].v)
        ,.v_o    (fifo_valid_lo[i])
        ,.data_o (fifo_data_lo [i])
        ,.yumi_i (any_yumi)
  		);
      
      bsg_wormhole_router_header_s hdr;
      
      assign hdr = fifo_data_lo[i][$bits(bsg_wormhole_router_header_s)-1:0];

      bsg_wormhole_decoder_dor #(.dims_p(dims_p)
                                 ,.cord_width_p(cord_width_p)
                                 ,.actual_cord_widths_p(actual_cord_widths_p)
                                 ,.max_cord_width_p="inv", actual_cord_widths_p = { max_cord_width_p, max_cord_width_p },  output_dirs_lp=2*dims_p+1) dor
      (.clk_i
       ,.target_cord_i
       ,.my_cord_i 
       ,.req_o
      );       

      
      // FIXME
      
      bsg_wormhole_decoder_dor #(.dims_p(dims_p), .cord_width_p(dims_p=2, cord_width_p="inv", output_dirs_lp=2*dims_p+1)
  (input clk_i
   , input [dims_p-1][cord_width_p-1:0] target_coord_i
   , input [dims_p-1][cord_width_p-1:0] my_coord_i
   , output [output_dirs_lp-1:0]        req_o 
  );
  
      
      decode_dor #(.input_dir_p(i),.pattern_els_p(matrix_in_out[i])) dor
    	( .clk_i
         ,.x_dirs_i(hdr.x_cord) 
         ,.y_dirs_i(hdr.y_cord) 
         ,.my_x_i
    	 ,.my_y_i
         ,.req_o(decoded_dest_lo) 
        );  
      
      bsg_router_wormhole_input_control #(.output_dirs_p(output_dirs_sparse_lp), .payload_len_bits_p($bits(hdr.len)) 
      (.clk_i
       ,.reset_i
       ,.fifo_v_i           (fifo_valid_lo[i])
       ,.fifo_yumi_i        (any_yumi)
       ,.fifo_decoded_dest_i(decoded_dest_lo)
       ,.fifo_payload_len_i (hdr.len)
       ,.reqs_o             (reqs_lo)
       ,.release_o          (releases[i]) // broadcast to all
      );

       // switch to dense matrix form
      bsg_unconcentrate_static #(.pattern_els_p(matrix_in_out[i])) unc
        (.i (reqs_lo)
         ,.o (reqs[i]) // unicast
       );
    end	
   
   // flip signal wires from input-indexed to output-indexed
   // this is swizzling the wires that connect input ports and output ports
   bsg_transpose #(.width_p(dirs_lp),.els_p(dirs_lp)) reqs_trans
   (.i(reqs)
    ,.o(reqs_transpose)
   );
               
  // iterate through each output channel            
  for (i = 0; i < output_dirs_lp; i=i+1)
    begin: out_ch
      localparam input_dirs_sparse_lp = `BSG_COUNTONES_SYNTH(matrix_out_in[i]);
      wire [input_dirs_sparse_lp-1:0] reqs_li, release_li, valids_li, yumis_lo, data_sel_lo;
      wire [input_dirs_sparse_lp-1:0][width_p-1:0] fifo_data_sparse_lo;

      bsg_ready_and_link_sif_s link_i_cast, link_o_cast;      
      assign link_i_cast = link_i[i];
      assign link_o[i] = link_o_cast;
      
      bsg_concentrate_static #(.pattern_els_p(matrix_out_in[i])) conc
      (.i(reqs_transpose[i]),.o(reqs_li));
      
      bsg_concentrate_static #(.pattern_els_p(matrix_out_in[i])) conc2
      (.i(releases),.o(release_li));
      
      bsg_concentrate_static #(.pattern_els_p(matrix_out_in[i])) conc3
      (.i(fifo_valid),.o(valids_li));
      
      bsg_concentrate_static #(.pattern_els_p(matrix_out_in[i])) conc4
      (.i(fifo_data_lo),.o(fifo_data_sparse_lo));
     
      link_o_cast.v = |valids_li;
  
      bsg_router_wormhole_output_scheduler #(.input_dirs_p(input_dirs_sparse_lp))
  	  (.clk_i
      ,.reset_i
      ,.reqs_i    (reqs_li   )
      ,.release_i (release_li)
      ,.valid_i   (valids_li )
      ,.yumi_o    (yumis_lo  )
      ,.ready_i   (link_i_cast.ready_and_rev)
      ,.valid_o   (link_o_cast.v)
      ,.data_sel_o(data_sel_lo)
      );
      
      bsg_mux_one_hot #(.width_p(width_p)
                       ,.els_p(input_dirs_sparse_lp)
                       ) data_mux
      (.data_i(fifo_data_sparse_lo)
       ,.sel_one_hot_i(data_sel_lo)
       ,.data_o(link_o_cast.data)
      );      
      
      bsg_unconcentrate_static #(.pattern_els_p(matrix_out_in[i])) unc1
      (.i (yumis_lo)
       ,.o (yumis[i])
      );
    end
  
endmodule
