ghdl -a PG_Logic.vhd
ghdl -a TB_PG_Logic.vhd

ghdl -e PG_Logic
ghdl -e TB_PG_Logic

./tb_pg_logic --stop-time=140ns --wave=PG_Logic.ghw --vcd=PG_Logic.vcd