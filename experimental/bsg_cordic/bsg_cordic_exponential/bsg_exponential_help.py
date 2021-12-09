import math

def constant_compute(negprec, posprec):
    const=1
    for i in range(-negprec,1):
        comp=((1-(1-2**(i-2))**2)**0.5)
        const=const*comp
    for i in range(1,posprec+1):
        comp=((1-2**(-2*i))**0.5)
        const=const*comp
    return 1/const
    
print("Please input the maximum input number that needs to be computed.")

maxnum = input()
maxnum = round(float(maxnum))

print("We now need to decide the number of pipeline stages in positive as well as negative direction.")
print("The number of pipeline stages in positive direction determines the accuracy of output" )
print("The script can generate output Verilog code for a maximum of 12-13 stages. It's advised to use at least 5-6 pipeline stages in positive dierction.")
print("Works and tested extensively for 9-12 stages.")

posprec = input("Please enter the positive pipeline stages needed: ")

print("It's suggested to use at least 4 bits for precision.")
print("If 4 bits are used then the resulting representation would be in fixed point in which first 4 least significant bits signify the the digits to the right of the decimal.")
precision = input("Precision bits in a sense are indicative of the minimum number that can be computed with correct results. Please enter the number of precision bits needed for your design: ")

posprec = (int)(posprec)
precision = (int)(precision)

if maxnum < 8.217603730491943:
    negprec = 0
    ansbitlen = 1 + precision + len(format(8,'b'))
    
elif (maxnum >= 8.217603730491943) and (maxnum < 31.37988526850316):
    negprec = 1
    ansbitlen = 1 + precision + len(format(31,'b'))
    
elif (maxnum>=31.37988526850316) and (maxnum<174.54504137919244):
    negprec = 2
    ansbitlen = 1 + precision + len(format(175,'b'))
    
elif (maxnum>=174.54504137919244) and (maxnum<1385.3533619330747):
    negprec = 3
    ansbitlen = 1 + precision + len(format(1385,'b'))
    
elif (maxnum>=1385.3533619330747) and (maxnum<15612.232242751299):
    negprec = 4
    ansbitlen = 1 + precision + len(format(15612,'b'))
    
elif (maxnum>=15612.232242751299) and (maxnum<249306.91331061107):
    negprec = 5
    ansbitlen = 1 + precision + len(format(249307,'b'))
    
elif (maxnum>=249306.91331061107) and (maxnum<5635632.815285727):
    negprec = 6
    ansbitlen = 1 + precision + len(format(5635633,'b'))
    
elif (maxnum>=5635632.815285727) and (maxnum<180252643.5425726):
    negprec = 7
    ansbitlen = 1 + precision + len(format(180252644,'b'))
    
elif (maxnum>=180252643.5425726) and (maxnum<8155350077.040721):
    negprec = 8
    ansbitlen = 1 + precision + len(format(8155350077,'b'))
    
elif (maxnum>=8155350077.040721) and (maxnum<521878166459.27527):
    negprec = 9
    ansbitlen = 1 + precision + len(format(521878166459,'b'))
    
elif (maxnum>=521878166459.27527) and (maxnum<47231870352751.54):
    negprec = 10
    ansbitlen = 1 + precision + len(format(47231870352751,'b'))
    
else:
    negprec = 11
    ansbitlen = 1 + precision + 52
    
print("The number of pipeline stages in negative direction is determined by the maximum quantity that can be accumulated in the angle register")
print("In this case we compare the value ln(maximum_input_by_user) to the max angle table given in the readme and then find the minimum 'M' value needed")

print("The negative precision depending on the maximum result output needed is %(s)d" %{'s':negprec})
constant=constant_compute(negprec, posprec)*(2**precision)

print("The minimum length of output should be %(s)d bits." % {'s':ansbitlen})

lnmaxnum = math.log(maxnum)
binlnmaxnum = format(round(lnmaxnum), 'b')
angbitlen = len(binlnmaxnum)+1

print("The minimum length of input should be %(s)d bits. " % {'s':angbitlen+(int)(precision)})
print("The precision of the input as well as the output is: %(p)f"% {'p':2**(-precision)})
