import sys, math

def bsg_exponential_main_initial(angbitlen, ansbitlen, negprec, posprec, extriter):
    print("""
    module bsg_cordic_exponential #(parameter neg_prec_p=%(n)d, posi_prec_p=%(p)d, extr_iter_p=1, ans_width_p = %(s)d, ang_width_p = %(g)d)
    (
    input clk_i
    ,input signed [ang_width_p-1:0] ang_i
    ,input ready_i
    ,input val_i
    ,output signed [ans_width_p-1:0] expz_o
    ,output ready_o
    ,output val_o
    );
    logic signed [neg_prec_p+posi_prec_p+extr_iter_p+1:0][ans_width_p-1:0] x ;
    logic signed [neg_prec_p+posi_prec_p+extr_iter_p+1:0][ans_width_p-1:0] y ;
    logic signed [neg_prec_p+posi_prec_p+extr_iter_p+1:0][ang_width_p-1:0] ang ;
    logic [neg_prec_p+posi_prec_p+extr_iter_p+1:0] val ;
    logic signed [neg_prec_p+posi_prec_p+extr_iter_p:0][ans_width_p-1:0] x_ans ;
    logic signed [neg_prec_p+posi_prec_p+extr_iter_p:0][ans_width_p-1:0] y_ans ;
    logic signed [neg_prec_p+posi_prec_p+extr_iter_p:0][ang_width_p-1:0] ang_ans ;
    logic [neg_prec_p+posi_prec_p+extr_iter_p:0] val_ans ;
    wire stall_pipe = val_o & (~ready_i);
    """ %{'s':ansbitlen, 'g':angbitlen, 'n':negprec, 'p':posprec, 'e':extriter})
    return
def bsg_lookup_initialization(negprec, posprec, angbitlen,result):
    print("     localparam [neg_prec_p+posi_prec_p:0][ang_width_p-1:0] ang_lookup_lp = {")
    for i in range(posprec+negprec,0,-1):
        print("     %(g)d'h%(r)s," %{'g':angbitlen,'r':result[i] })
    print("     %(g)d'h%(r)s };" %{'g':angbitlen,'r':result[0] })
    return
def constant_compute(negprec, posprec):
    const=1
    for i in range(-negprec,1):
        comp=((1-(1-2**(i-2))**2)**0.5)
        const=const*comp
    for i in range(1,posprec+1):
        comp=((1-2**(-2*i))**0.5)
        const=const*comp
    return 1/const
def lookup_compute(negprec, posprec, precision):
    lookup=[]
    for i in range(-negprec,1):
        m=math.atanh(1-2**(i-2))
        lookup.append(format((int)(m*(2**precision)),'x'))
    for j in range(negprec+1,negprec+posprec+1):
        m=math.atanh(2**(-j+negprec))
        lookup.append(format((int)(m*(2**precision)),'x'))
    return lookup

def bsg_constxy_initialization(constant, ansbitlen):
    print("""    
    localparam x_start = %(s)d'h%(c)s;
    localparam y_start = %(s)d'h%(c)s;
    """ %{'s':ansbitlen, 'c':constant})
    return
def main_body_print():
    print("""
    always_ff @(posedge clk_i) begin
    if(~stall_pipe) begin
        x[0] <= x_start;
        y[0] <= y_start;
        ang[0] <= ang_i;
        val[0] <= val_i;
       end
    end
    genvar i;
    generate
        for(i = 0; i <= neg_prec_p ; i = i+1)
            begin : stage_neg
                bsg_cordic_exponential_stage_negative #(.stage_p(i), .neg_prec_p(neg_prec_p), .ans_width_p(ans_width_p), .ang_width_p(ang_width_p)) cs
                       (.x_i(x[i])
                        ,.y_i(y[i])
                        ,.ang_i(ang[i])
                        ,.ang_lookup_i(ang_lookup_lp[i])
                        ,.val_i(val[i])
                        ,.x_o(x_ans[i])
                        ,.y_o(y_ans[i])
                        ,.ang_o(ang_ans[i])
                        ,.val_o(val_ans[i])
                        );
          
                    always_ff @(posedge clk_i)
                      begin
                      if(~stall_pipe) begin
                         x[i+1] <= x_ans[i];
                         y[i+1] <= y_ans[i];
                         ang[i+1] <= ang_ans[i];
                         val[i+1] <= val_ans[i];
                       end
                      end
                 end
          
            endgenerate
            
    genvar j;
    generate        
        for(j = neg_prec_p+1; j <= neg_prec_p+posi_prec_p ; j = j+1)    
            begin : stage_pos
              if((j==(neg_prec_p+4))||(j==(neg_prec_p+12)))
                begin
                bsg_cordic_exponential_stage_positive #(.stage_p(j), .neg_prec_p(neg_prec_p), .ans_width_p(ans_width_p), .ang_width_p(ang_width_p)) cs
                       (.x_i(x[j])
                        ,.y_i(y[j])
                        ,.ang_i(ang[j])
                        ,.ang_lookup_i(ang_lookup_lp[j])
                        ,.val_i(val[j])
                        ,.x_o(x_ans[j])
                        ,.y_o(y_ans[j])
                        ,.ang_o(ang_ans[j])
                        ,.val_o(val_ans[j])
                        );
                        
                    always_ff @(posedge clk_i)
                      begin
                        if(~stall_pipe) begin
                         x[j+1] <= x_ans[j];
                         y[j+1] <= y_ans[j];
                         ang[j+1] <= ang_ans[j];
                         val[j+1] <= val_ans[j];
                       end
                      end
                      
                bsg_cordic_exponential_stage_positive #(.stage_p(j), .neg_prec_p(neg_prec_p), .ans_width_p(ans_width_p), .ang_width_p(ang_width_p)) csrep
                       (.x_i(x[j+1])
                       ,.y_i(y[j+1])
                       ,.ang_i(ang[j+1])
                       ,.ang_lookup_i(ang_lookup_lp[j])
                       ,.val_i(val[j+1])
                       ,.x_o(x_ans[j+1])
                       ,.y_o(y_ans[j+1])
                       ,.ang_o(ang_ans[j+1])
                       ,.val_o(val_ans[j+1])
                       );
                    always_ff @(posedge clk_i)
                    begin
                    if(~stall_pipe) begin
                    x[j+2] <= x_ans[j+1];
                    y[j+2] <= y_ans[j+1];
                    ang[j+2] <= ang_ans[j+1];
                    val[j+2] <= val_ans[j+1];
                    end
                    end
                end
                
              else if(j>(neg_prec_p+4))
                  begin
                	bsg_cordic_exponential_stage_positive #(.stage_p(j), .neg_prec_p(neg_prec_p), .ans_width_p(ans_width_p), .ang_width_p(ang_width_p)) cs
                       	(.x_i(x[j+1])
                         ,.y_i(y[j+1])
                         ,.ang_i(ang[j+1])
                         ,.ang_lookup_i(ang_lookup_lp[j])
                         ,.val_i(val[j+1])
                         ,.x_o(x_ans[j+1])
                         ,.y_o(y_ans[j+1])
                         ,.ang_o(ang_ans[j+1])
                         ,.val_o(val_ans[j+1])
                        );
                        
                    always_ff @(posedge clk_i)
                      begin
                        if(~stall_pipe) begin
                        x[j+2] <= x_ans[j+1];
                        y[j+2] <= y_ans[j+1];
                        ang[j+2] <= ang_ans[j+1];
                        val[j+2] <= val_ans[j+1];
                      end
                      end
                  end
              else if(j<(neg_prec_p+4)) 
                begin
                  bsg_cordic_exponential_stage_positive #(.stage_p(j), .neg_prec_p(neg_prec_p), .ans_width_p(ans_width_p), .ang_width_p(ang_width_p)) cs
                       	(.x_i(x[j])
                         ,.y_i(y[j])
                         ,.ang_i(ang[j])
                         ,.ang_lookup_i(ang_lookup_lp[j])
                         ,.val_i(val[j])
                         ,.x_o(x_ans[j])
                         ,.y_o(y_ans[j])
                         ,.ang_o(ang_ans[j])
                         ,.val_o(val_ans[j])
                        );
                        
                    always_ff @(posedge clk_i)
                      begin
                        if(~stall_pipe) begin
                        x[j+1] <= x_ans[j];
                        y[j+1] <= y_ans[j];
                        ang[j+1] <= ang_ans[j];
                        val[j+1] <= val_ans[j];
                      end
                      end
                  end
            end
                                   
    endgenerate   
    
    assign val_o = val[neg_prec_p+posi_prec_p+2];
    assign expz_o = x[neg_prec_p+posi_prec_p+2];
    assign ready_o = ~stall_pipe;
endmodule""")
    return
    
angbitlen = (int)(sys.argv[1])
# ^^ Defines the bit-length of the angular ('z' in CORDIC naming) datapath. 
# Has a precision of 'precision' bits and is input to the module.
ansbitlen = (int)(sys.argv[2])
# ^^ Defines the bit-length of the answer ('x' and 'y' in CORDIC naming) datapath.
# Also has a precision of 'precision' bits and is output of the module defined by
# exp(ang_i) 
negprec = (int)(sys.argv[3])
# ^^ Determines the number of iterations in negative direction. These iterations
# increase the domain of input that can be converged by the module.
posprec = (int)(sys.argv[4])
#^^ The number of iterations in positive direction. Advised and
# observed mathematically to have n-iterations to have a precision of n-bits.
precision = (int)(sys.argv[5])
startquant_pow = (int)(sys.argv[6])
#^^ Determines the bit position to start the input of testing from. If experiencing
# high error in the lower range of quantities, try increasing this quantity.
extriter = 1
# Increase extriter when you want to go beyond 13 iterations in the positive direction.
# This script and the verilog module is limited upto 13 iterations only. Apart from changing
#'extriter' changes would be needed to the verilog code as well. It's added for the convenience
# of expansion later on, if needed. 
bsg_exponential_main_initial(angbitlen, ansbitlen, negprec, posprec, extriter)
lookup=lookup_compute(negprec, posprec, precision)
bsg_lookup_initialization(negprec, posprec, angbitlen,lookup)
constant=constant_compute(negprec, posprec)*(2**precision)
constant=format(round(constant),'x')
bsg_constxy_initialization(constant, ansbitlen)
main_body_print()
length=len(constant)


# This file object is used to create a header file facilitating the passing of parameters of the module to
# Verilator for testing purposes. 
f_params = open("params_def.h","w+")
f_params.write('#ifndef PARAMS_DEF\n')
f_params.write('#define PARAMS_DEF\n')
f_params.write('int anglen = %(g)d;\n'%{'g':angbitlen})
f_params.write('int anslen = %(s)d;\n'%{'s':ansbitlen})
f_params.write('int startquant_pow = %(s)d;\n'%{'s':startquant_pow})
f_params.write('int posiprec = %(p)d;\n'%{'p':posprec})
f_params.write('int negprec = %(n)d;\n'%{'n':negprec})
f_params.write('int precision = %(p)d;\n'%{'p':precision})
f_params.write('#endif')
f_params.close()
