ghdl -a ../src/PGLogic/PGLogic.vhd
ghdl -a ../src/CarryGen/CarryGen_Block.vhd
ghdl -a ../src/CarryGen/CarryGen_Array.vhd
ghdl -a ../src/SumLogic/SumLogic.vhd
ghdl -a ../src/CLA.vhd
ghdl -a ../src/lfsr.vhd
ghdl -a ../src/TB_CLA.vhd

ghdl -e PGLogic
ghdl -e CarryGen_Block
ghdl -e CarryGen_Array
ghdl -e SumLogic
ghdl -e CLA
ghdl -e LFSR32
ghdl -e TB_CLA

./tb_cla --stop-time=40ns --wave=CLA.ghw --vcd=CLA.vcd