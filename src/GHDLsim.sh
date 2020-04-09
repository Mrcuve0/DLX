ghdl -a 000-globals.vhd
ghdl -a 01-genericMUX_2to1.vhd
ghdl -a 01-genericMUX_Nto1.vhd
ghdl -a ./tb/TB_01-genericMUX_Nto1.vhd

ghdl -e genericMUX_Nto1
ghdl -e TB_01_genericMUX_Nto1
./tb_01_genericmux_nto1 --stop-time=40ns --wave=genericMUX_Wave.ghw --vcd=genericMUX_Wave.vcd