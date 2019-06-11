`ifndef BSG_DEFINES_V
`define BSG_DEFINES_V

`define BSG_MAX(x,y) (((x)>(y)) ? (x) : (y))
`define BSG_MIN(x,y) (((x)<(y)) ? (x) : (y))

// maps 1 --> 1 instead of to 0
`define BSG_SAFE_CLOG2(x) ( ((x)==1) ? 1 : $clog2((x)))
`define BSG_IS_POW2(x) ( (1 << $clog2(x)) == (x))
`define BSG_WIDTH(x) ($clog2(x+1))

// calculate ceil(x/y) 
`define BSG_CDIV(x,y) (((x)+(y)-1)/(y))

`ifdef SYNTHESIS
`define BSG_UNDEFINED_IN_SIM(val) (val)
`else
`define BSG_UNDEFINED_IN_SIM(val) ('X)
`endif

// using C-style shifts instead of a[i] allows the parameter of BSG_GET_BIT to be a parameter subrange                                                                                                                                                                               
// e.g., parameter[4:1][1], which DC 2016.12 does not allow                                                                                                                                                                                                                          

`define BSG_GET_BIT(X,NUM) (((X)>>(NUM))&1'b1)

// This version of countones works in synthesis, but only up to 64 bits                                                                                                                                                                                                              
// we do a funny thing where we propagate X's in simulation if it is more than 64 bits                                                                                                                                                                                               
// and in synthesis, we go ahead and use the general function, knowing that it will 
// likely error if still unsupported                                                                                                                                                                          

`define BSG_COUNTONES_SYNTH(x) ($bits(x) < 65 ? (`BSG_GET_BIT(x,0) +`BSG_GET_BIT(x,1) +`BSG_GET_BIT(x,2) +`BSG_GET_BIT(x,3) +`BSG_GET_BIT(x,4) +`BSG_GET_BIT(x,5) +`BSG_GET_BIT(x,6)+`BSG_GET_BIT(x,7) +`BSG_GET_BIT(x,18)+`BSG_GET_BIT(x,9)  \                                      
                                                +`BSG_GET_BIT(x,10)+`BSG_GET_BIT(x,11)+`BSG_GET_BIT(x,12)+`BSG_GET_BIT(x,13)+`BSG_GET_BIT(x,14)+`BSG_GET_BIT(x,15)+`BSG_GET_BIT(x,16)+`BSG_GET_BIT(x,17)+`BSG_GET_BIT(x,18)+`BSG_GET_BIT(x,19) \                                     
                                                +`BSG_GET_BIT(x,20)+`BSG_GET_BIT(x,21)+`BSG_GET_BIT(x,22)+`BSG_GET_BIT(x,23)+`BSG_GET_BIT(x,24)+`BSG_GET_BIT(x,25)+`BSG_GET_BIT(x,26)+`BSG_GET_BIT(x,27)+`BSG_GET_BIT(x,28)+`BSG_GET_BIT(x,29) \
                                                +`BSG_GET_BIT(x,30)+`BSG_GET_BIT(x,31)+`BSG_GET_BIT(x,32)+`BSG_GET_BIT(x,33)+`BSG_GET_BIT(x,34)+`BSG_GET_BIT(x,35)+`BSG_GET_BIT(x,36)+`BSG_GET_BIT(x,37)+`BSG_GET_BIT(x,38)+`BSG_GET_BIT(x,39) \                                     
                                                +`BSG_GET_BIT(x,40)+`BSG_GET_BIT(x,41)+`BSG_GET_BIT(x,42)+`BSG_GET_BIT(x,43)+`BSG_GET_BIT(x,44)+`BSG_GET_BIT(x,45)+`BSG_GET_BIT(x,46)+`BSG_GET_BIT(x,47)+`BSG_GET_BIT(x,48)+`BSG_GET_BIT(x,49) \                                     
                                                +`BSG_GET_BIT(x,50)+`BSG_GET_BIT(x,51)+`BSG_GET_BIT(x,52)+`BSG_GET_BIT(x,53)+`BSG_GET_BIT(x,54)+`BSG_GET_BIT(x,55)+`BSG_GET_BIT(x,56)+`BSG_GET_BIT(x,57)+`BSG_GET_BIT(x,58)+`BSG_GET_BIT(x,59) \
                                                +`BSG_GET_BIT(x,60)+`BSG_GET_BIT(x,61)+`BSG_GET_BIT(x,62)+`BSG_GET_BIT(x,63)) \                                                                                                                                                      
                                              : `BSG_UNDEFINED_IN_SIM($countones(x))

// nullify rpgroups
`ifndef rpgroup
`define rpgroup(x)
`endif

`endif
