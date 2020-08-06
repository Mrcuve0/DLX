-- This is a 32 bit Linear Feedback Shift Register
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LFSR32 is
    port (
        CLK    : in std_logic;
        RESET  : in std_logic;
        LD     : in std_logic;
        EN     : in std_logic;
        DIN    : in std_logic_vector (31 downto 0);
        PRN    : out std_logic_vector (31 downto 0);
        ZERO_D : out std_logic);
end LFSR32;

architecture RTL of LFSR32 is
    signal t_prn : std_logic_vector(31 downto 0);
begin
    -- Continuous assignments :
    PRN    <= t_prn;
    ZERO_D <= '1' when (t_prn = X"00000000") else
        '0';
    -- LFSR process : 
    process (CLK, RESET)
    begin
        if RESET = '1' then
            t_prn <= X"00000001"; -- load 1 at reset 
        elsif rising_edge (CLK) then
            if (LD = '1') then -- load a new seed when ld is active 
                t_prn <= DIN;
            elsif (EN = '1') then -- shift when enabled 
                t_prn(0)           <= t_prn(18) xor t_prn(7) xor t_prn(1);
                t_prn(31 downto 1) <= t_prn(30 downto 0);
            end if;
        end if;
    end process;
end RTL;