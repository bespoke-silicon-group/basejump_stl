from __future__ import print_function

from math import ceil

from random import randint
from random import getrandbits

hdr_width = 16
cord_width = 5
len_width = 3
link_width = 8
pr_data_width = 16

wh_hdr_width = cord_width + len_width
pr_hdr_width = hdr_width - wh_hdr_width
hdr_flits = hdr_width / link_width
data_width = link_width*(2**len_width-hdr_flits+1)
data_flits = data_width / link_width
beats_per_flit = pr_data_width / link_width

# First bit is header or data for send
ring_width = 1+max(hdr_width, max(data_width, link_width))

OP_WAIT = "0000_"
OP_SEND = "0001_"
OP_RECV = "0010_"
OP_FNSH = "0100_"

# We use 128 as the formatter just so it's larger than all packets
def getrandbitstring(width):
    return format(getrandbits(width), "0128b")[128-width:128]

def getintstring(i, width):
    return format(i, "0128b")[128-width:128]

def pad_string(string, width):
    return format(int(string, 2), "0128b")[128-width:128]

def send_wait(n=0):
    for _ in range(n):
        print(OP_WAIT + pad_string("0", ring_width))

def send_finish():
    print(OP_FNSH + pad_string("0", ring_width))

def send_packet(packet):
    packet = packet[2:]
    packet_width = len(packet)
    header = packet[packet_width-hdr_width:packet_width]
    cord = int(packet[packet_width-cord_width:packet_width], 2)
    length = int(packet[packet_width-cord_width-len_width:packet_width-cord_width], 2)
    data_flits = length - hdr_flits + 1
    data_width = data_flits * link_width
    data = packet[packet_width-hdr_width-data_width:packet_width-hdr_width]
    pr_beats = int(ceil(1.0 * data_width / pr_data_width))

    #print("-------------------")
    #print("PACKET: {}".format(packet))
    #print("CORD: {}".format(bin(cord)))
    #print("LEN: {}".format(bin(length)))
    #print("HDR: {}".format(header))
    #print("DATA: {}".format(data))
    #print("DATA FLITS: {}".format(data_flits))
    #print("PR DATA WIDTH: {}".format(pr_data_width))
    #print("SENDING HEADER")
    print(OP_SEND + "0" + pad_string(header, ring_width-1))
    #print("SENDING {} BEATS".format(pr_beats))
    for i in range(pr_beats):
        #print("X: {} Y: {}".format(data_width-(i+1)*pr_data_width, data_width-(i)*pr_data_width))
        beat = data[data_width-(i+1)*pr_data_width:data_width-(i)*pr_data_width]
        print(OP_SEND + "1" + pad_string(beat, ring_width-1))
    #print("FINISH SEND")

def recv_packet(packet):
    packet = packet[2:]
    packet_width = len(packet)
    cord = int(packet[packet_width-cord_width:packet_width], 2)
    length = int(packet[packet_width-cord_width-len_width:packet_width-cord_width], 2)
    data_flits = length - hdr_flits + 1
    for i in range(hdr_flits):
        flit = packet[packet_width-(i+1)*link_width:packet_width-(i)*link_width]
        print(OP_RECV + pad_string(flit, ring_width))
    for i in range(data_flits):
        flit = packet[packet_width-(hdr_flits+(i+1))*link_width:packet_width-(hdr_flits+(i))*link_width]
        print(OP_RECV + pad_string(flit, ring_width))

def gen_packet():
    cord = getrandbitstring(cord_width)
    data_len = randint(0, data_flits) // beats_per_flit * beats_per_flit
    length = pad_string(bin(data_len + hdr_flits-1), len_width)
    #print("--------------")
    #print("GEN")
    #print("CORD: {}".format(cord))
    #print("HDR LENGTH: {}".format(hdr_flits))
    #print("DATA LENGTH: {}".format(data_len))
    #print("LENGTH: {}".format(length))
    pr_hdr = getrandbitstring(pr_hdr_width)
    if data_len == 0:
        data = getintstring(0, data_width)
    else:
        data = getintstring(randint(0, 2**data_len), data_width)
    #print("DATA: {}".format(data))

    return "0b" + "".join([data, pr_hdr, length, cord])
 


if __name__ == "__main__":
    send_wait(10)
    # Stream in stream out test
    for _ in range(30):
        packet = gen_packet()
        send_packet(packet)
        recv_packet(packet)

    send_finish();

