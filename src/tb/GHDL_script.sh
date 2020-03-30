ghdl -a ./../000-globals.vhd 
ghdl -a ./../a.a-CU_FSM.vhd
ghdl -a --ieee=synopsys TB_a.a-CU_FSM.vhd

#ghdl -e myTypes
ghdl -e dlx_cu
ghdl -e --ieee=synopsys TB_CU_FSM

./tb_cu_fsm --stop-time=140ns --wave=CU_DLX.ghw --vcd=CU_DLX.vcd
