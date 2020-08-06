library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CarryGen_Block is
    port (
        Cin: in std_logic;
        prop: in std_logic;
        gen : in std_logic;
        Cout: out std_logic
    );
end entity CarryGen_Block;

--------------------------------------------------------------------------------
-- Behavioral Architecture
--------------------------------------------------------------------------------

architecture beh of CarryGen_Block is
    
    signal and_out : std_logic;

begin
    
    and_out <= Cin and prop;
    Cout <= and_out or gen;
    
end architecture beh;