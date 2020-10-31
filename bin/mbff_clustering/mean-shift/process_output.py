'''
    File name      : process_output.py
    Author         : Jinwook Jung (jinwookjung@ibm.com)
    Created on     : Fri 08 May 2020 01:28:20 PM EDT
    Last modified  : 2020-06-08 17:12:55
    Description    : 
'''

import argparse

class Inst:
    def __init__(self, name, x, y, label):
        self.name = name
        self.x, self.y = x, y
        self.label = label


def write_output_tcl(output_dir):
    with open("{}/output.txt".format(output_dir)) as f:
        lines = [l for l in (_.strip() for _ in f) if l]

    lines = lines[2:]

    insts = list()
    for l in lines:
        tokens = l.split()
        insts.append(Inst(tokens[0], tokens[1], tokens[2], tokens[3]))

    with open("{}/output.tcl".format(output_dir), 'w') as f:
        for i in insts:
            f.write("placeInstance {} [list {} {}] -softFixed\n".format(i.name, i.x, i.y))


def main():
    """The main function.
    """

    parser = argparse.ArgumentParser()
    parser.add_argument('-o', '--output-directory', action="store", required=True)
    args = parser.parse_args()

    write_output_tcl(args.output_directory)


if __name__ == "__main__":
    main()
