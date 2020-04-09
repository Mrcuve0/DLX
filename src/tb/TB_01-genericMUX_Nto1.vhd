library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

-- use work.myTypes.all;

entity TB_01_genericMUX_Nto1 is
end entity TB_01_genericMUX_Nto1;

architecture tb_arch of TB_01_genericMUX_Nto1 is

    constant nChannels_mux : integer := 8;
    constant nDataBit_mux : integer := 32;

    component genericMUX_Nto1 is
        generic(
            nDataBit_mux : integer := 32;
            nChannels_mux : integer := 8
        );
        port(
            in1 : in std_logic_vector((nChannels_mux * nDataBit_mux) - 1 downto 0);       -- Input channels must be chained together (MSB In1 corresponds to nChannel)
            sel : in std_logic_vector(integer(ceil(log2(real(nChannels_mux)))) - 1 downto 0);
            out1 : out std_logic_vector(nDataBit_mux - 1 downto 0)
        );
    end component;

    signal in1_s : std_logic_vector((nChannels_mux * nDataBit_mux) - 1 downto 0);
    signal sel_s : std_logic_vector(integer(ceil(log2(real(nChannels_mux)))) - 1 downto 0);
    signal out1_s : std_logic_vector(nDataBit_mux - 1 downto 0);
    
begin

    genericMUX_Nto1_1 : genericMUX_Nto1 generic map(nDataBit_mux, nChannels_mux) 
                                        port map (in1 => in1_s, sel => sel_s, out1 => out1_s);

    input_stimuli: process
    begin
        in1_s <= X"88888888" & X"77777777" & X"66666666" & X"55555555" & X"44444444" & X"33333333" & X"22222222" & X"11111111";
        sel_s <= "111";
        wait for 2 ns;

        sel_s <= "110";
        wait for 2 ns;

        sel_s <= "101";
        wait for 2 ns;

        sel_s <= "100";
        wait for 2 ns;

        sel_s <= "011";
        wait for 2 ns;

        sel_s <= "010";
        wait for 2 ns;

        sel_s <= "001";
        wait for 2 ns;

        sel_s <= "000";
        wait for 2 ns;
        
        wait;
    end process input_stimuli; 
    
end architecture tb_arch;