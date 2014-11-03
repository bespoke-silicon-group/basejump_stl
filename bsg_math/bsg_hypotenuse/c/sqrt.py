#!/usr/bin/python
import math;

bits = 12;
a_1       = 1
a_1_shift = 1

b_1       = 1
b_1_shift = 3

a_2       = 53
a_2_shift = 7

b_2       = 37
b_2_shift = 7

y_start = 40

for y in range (y_start,2**bits) :
    for x in range (y, 2**bits) :
        foo = 441*y;
        if (x < (y << 4)) :
            x_mul = 967;
        else:
            x_mul = 1007;

        foo += x_mul*x;
        foo = (foo+512) >> 10;
        #foo_2 = x*.941246 + y*.41;
        exact = math.sqrt(y*y+x*x);
        exact_round = round(math.sqrt(y*y+x*x));
        # print y,x, ( a_1*x + ((b_1*y) >> b_1_shift )),  ((a_2*x) >> a_2_shift) + ((b_2*y) >> b_2_shift),
        error = (foo-exact);
        if (error > 1.5) :
            print y,x,"*", foo, round(exact,0), error
        # 0.41 dx + 0.941246 dy 
