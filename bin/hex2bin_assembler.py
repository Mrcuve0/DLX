#!/bin/python3

import subprocess
import sys
import os

def main():

    # get filename
    file = sys.argv[1]

    listOp = []
    opMap = [""]
    with open(file, "r") as asmFile:
        for line in asmFile:
            # print(line.rsplit(" ", 1)[0])

            

            listOp.append(line.rsplit(" ", 1)[0].zfill(4))


    # strip extension from filename
    filename = file.rsplit(".", 1)[0]

    # launch assembler.sh
    currPath = str(os.getcwd())
    subprocess.call(str("\"" + currPath + "\"") + "/assembler.sh " + file, shell=True)

    hexFile = filename + "_hex_dump.txt"
    binFile = filename + "_bin_dump.txt"
    # print(currPath)
    # print(filename)
    # print(newFilename)

    index = 0
    # print(listOp)
    with open(hexFile, "r") as hexDumpFile:
        with open(binFile, "w") as binDumpFile:
            for line in hexDumpFile:
                # print(bin(int(str("0x" + line), 16))[2:].zfill(32))
                newLine = bin(int(str("0x" + line), 16))[2:].zfill(32)
                binDumpFile.writelines(newLine + " " + listOp[index] + "\n")
                index = index + 1

    subprocess.call("mv " + str("\"" + currPath) + "/" + binFile + "\" " + str("\"" + currPath) + "/../sim/\"", shell=True)


if __name__ == "__main__":

    if len(sys.argv) != 2:
        print("Error, must specify an ASM file!")
        sys.exit()

    main()