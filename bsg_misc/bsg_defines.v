`ifndef BSG_DEFINES_V
`define BSG_DEFINES_V

`define BSG_MAX(x,y) (((x)>(y)) ? (x) : (y))
`define BSG_MIN(x,y) (((x)<(y)) ? (x) : (y))

// maps 1 --> 1 instead of to 0
`define BSG_SAFE_CLOG2(x) ( ((x)==1) ? 1 : $clog2((x)))
`define BSG_IS_POW2(x) ( (1 << $clog2(x)) == (x))
`define BSG_WIDTH(x) ($clog2(x+1))

// nullify rpgroups
`ifndef rpgroup
`define rpgroup(x)
`endif

`endif
