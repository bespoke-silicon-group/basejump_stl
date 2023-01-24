
package bsg_axi_pkg;

 typedef enum logic [1:0]
  {
    e_axi_resp_okay    = 2'b00
    ,e_axi_resp_exokay = 2'b01
    ,e_axi_resp_slverr = 2'b10
    ,e_axi_resp_decerr = 2'b11
  } axi_resp_type_e;

  //   bit   :   0    /     1
  // prot[2] : data   / instruction
  // prot[1] : secure / non-secure
  // prot[0] : normal / privileged
  typedef enum logic [2:0]
  {
    // Normal / Non-Secure / Data
    e_axi_prot_dsn  = 3'b000
    ,e_axi_prot_dsp = 3'b001
    ,e_axi_prot_dnn = 3'b010
    ,e_axi_prot_dnp = 3'b011
    ,e_axi_prot_isn = 3'b100
    ,e_axi_prot_isp = 3'b101
    ,e_axi_prot_inn = 3'b110
    ,e_axi_prot_inp = 3'b111
  } axi_prot_type_e;

  //   bit     :          0        /     1
  // cache[3]  : write no-allocate / write allocate
  // cache[2]  : read no-allocate  / read allocate
  // cache[1]  : non-modifiable    / modifiable
  // cache[0]  : non-bufferable    / bufferable
  typedef enum logic [3:0]
  {
    e_axi_cache_wnarnanmnb  = 4'b0000
    ,e_axi_cache_wnarnanmb  = 4'b0001
    ,e_axi_cache_wnarnamnb  = 4'b0010
    ,e_axi_cache_wnarnamb   = 4'b0011
    ,e_axi_cache_wnaramnb   = 4'b0110
    ,e_axi_cache_wnaramb    = 4'b0111
    ,e_axi_cache_waramnb    = 4'b1110
    ,e_axi_cache_warnamnb   = 4'b1010
    ,e_axi_cache_warnamb    = 4'b1011
    ,e_axi_cache_waramb     = 4'b1111
  } axi_cache_type_e;

  typedef enum logic [1:0]
  {
    e_axi_burst_fixed     = 2'b00
    ,e_axi_burst_incr     = 2'b01
    ,e_axi_burst_wrap     = 2'b10
    ,e_axi_burst_reserved = 2'b11
  } axi_burst_type_e;

  typedef enum logic [3:0]
  {
    e_axi_qos_none = 4'b0000
    // The AXI spec does not provide any official definitions of qos
  } axi_qos_type_e;

  typedef enum logic [2:0]
  {
    e_axi_size_1B    = 3'b000
    ,e_axi_size_2B   = 3'b001
    ,e_axi_size_4B   = 3'b010
    ,e_axi_size_8B   = 3'b011
    ,e_axi_size_16B  = 3'b100
    ,e_axi_size_32B  = 3'b101
    ,e_axi_size_64B  = 3'b110
    ,e_axi_size_128B = 3'b111
  } axi_size_e;

  // AXI defines burst lengths of 1-16 for bursts not incr
  //   and 1-256 for bursts that are incr
  typedef enum logic [3:0]
  {
    e_axi_len_1   = 4'b0000
    ,e_axi_len_2  = 4'b0001
    ,e_axi_len_3  = 4'b0010
    ,e_axi_len_4  = 4'b0011
    ,e_axi_len_5  = 4'b0100
    ,e_axi_len_6  = 4'b0101
    ,e_axi_len_7  = 4'b0110
    ,e_axi_len_8  = 4'b0111
    ,e_axi_len_9  = 4'b1000
    ,e_axi_len_10 = 4'b1001
    ,e_axi_len_11 = 4'b1010
    ,e_axi_len_12 = 4'b1011
    ,e_axi_len_13 = 4'b1100
    ,e_axi_len_14 = 4'b1101
    ,e_axi_len_15 = 4'b1110
    ,e_axi_len_16 = 4'b1111
  } axi_len_e;

endpackage

