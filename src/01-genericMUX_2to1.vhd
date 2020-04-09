library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.myTypes.all;

entity genericMUX_2to1 is
    generic(
        nDataBit_mux : integer := nDataBit
    );
    port(
        in1, in2 : in std_logic_vector(nDataBit_mux - 1 downto 0);
        sel : in std_logic;
        out1 : out std_logic_vector(nDataBit_mux - 1 downto 0)
    );
end entity;

--------------------------------------------------------------------------------
-- Behavioral Architecture
--------------------------------------------------------------------------------
architecture beh of genericMUX_2to1 is
begin
    
    mux_proc: process(in1, in2, sel)
    begin
        case sel is
            when '0' =>
                out1 <= in1;
            when '1' =>
                out1 <= in2;
            when others => 
                out1 <= in2;    
        end case;
    end process mux_proc;
    
end architecture beh;