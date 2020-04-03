#!/bin/python3

import subprocess
import sys
import os

def main():

    # [..]/DLX/sim/CU
    currPath = str("\"" + os.getcwd() + "\"")
    synLib = "--ieee=synopsys"
    subprocess.call("ghdl -a " + currPath + "/../../src/000-globals.vhd", shell=True)
    subprocess.call("ghdl -a " + currPath + "/../../src/a.a-CU_FSM.vhd", shell=True)
    subprocess.call("ghdl -a " + synLib + " " + currPath +  "/../../src/tb/TB_a.a-CU_FSM.vhd", shell=True)
    
    subprocess.call("ghdl -e " + "dlx_cu", shell=True)
    subprocess.call("ghdl -e " + synLib + " " + "TB_CU_FSM", shell=True)

    subprocess.call("./tb_cu_fsm --stop-time=400ns --wave=CU_DLX.ghw --vcd=CU_DLX.vcd", shell=True)

if __name__ == "__main__":
    main()