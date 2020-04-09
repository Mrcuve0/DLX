library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.myTypes.all;

entity genericRegister is
    generic(
        nDataBit_reg : integer := nDataBit
    );
    port(
        clk, rst_n, enable : in std_logic;
        input : in std_logic_vector(nDataBit_reg - 1 downto 0);
        output : out std_logic_vector(nDataBit_reg - 1 downto 0)
    );
end entity;


--------------------------------------------------------------------------------
-- Behavioral Architecture
--------------------------------------------------------------------------------
architecture beh of genericRegister is
begin
    reg: process(clk, rst_n)
    begin
        if rst_n = '0' then
            output <= (others => '0');
        else
            if rising_edge(clk) and enable = '1' then
                output <= input;
            end if;
        end if;
    end process reg;
end architecture;