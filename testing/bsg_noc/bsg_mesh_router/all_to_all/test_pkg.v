
package test_pkg;


  
  `include "bsg_noc_links.vh"


  `define test_packet_width(data_width_mp,x_cord_width_mp,y_cord_width_mp) \
      (data_width_mp+x_cord_width_mp+y_cord_width_mp)

  `define test_link_sif_width(data_width_mp,x_cord_width_mp,y_cord_width_mp) \
      `bsg_ready_and_link_sif_width(`test_packet_width(data_width_mp,x_cord_width_mp,y_cord_width_mp))


  `define declare_test_link_sif_s(data_width_mp,x_cord_width_mp,y_cord_width_mp) \
    typedef struct packed {                                   \
      logic [data_width_mp-1:0] data;                          \
      logic [y_cord_width_mp-1:0] y_cord;                      \
      logic [x_cord_width_mp-1:0] x_cord;                      \
    } test_packet_s;                                          \
                                                                                \
    `declare_bsg_ready_and_link_sif_s(`test_packet_width(data_width_mp,x_cord_width_mp,y_cord_width_mp), test_link_sif_s)





endpackage



