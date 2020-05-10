
import argparse
import random


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('num', type=int)
    parser.add_argument('bits', type=int)

    args = parser.parse_args()

    for i in range(args.num):
        a = format(random.getrandbits(args.bits), 'x')
        b = format(random.getrandbits(args.bits), 'x')
        print("{} {}".format(a, b))

