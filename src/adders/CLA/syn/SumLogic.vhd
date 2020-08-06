library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SumLogic is
    generic (
        -- TODO: Update constant value w/ generic constant in work library
        N : integer := 32
    );
    port (
        Cin : in std_logic_vector(N-1 downto 0);
        prop : in std_logic_vector(N-1 downto 0);
        sum : out std_logic_vector(N-1 downto 0)
    );
end entity SumLogic;


--------------------------------------------------------------------------------
-- Behavioral Architecture
--------------------------------------------------------------------------------

architecture beh of SumLogic is
    
begin
    
    sum <= Cin xor prop;
    
end architecture beh;