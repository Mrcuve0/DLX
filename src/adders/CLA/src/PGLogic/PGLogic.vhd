library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- TODO: Uncomment constant work library inclusion
-- use work.myTypes.all;

entity PGLogic is
    generic (
        -- TODO: Update constant value w/ generic constant in work library
        N: integer := 32
    );
    port (
        operand_a : in std_logic_vector(N-1 downto 0);
        operand_b : in std_logic_vector(N-1 downto 0);
        prop      : out std_logic_vector(N-1 downto 0);
        gen       : out std_logic_vector(N-1 downto 0)
    );
end entity PGLogic;

--------------------------------------------------------------------------------
-- Behavioral Architecture
--------------------------------------------------------------------------------

architecture beh of PGLogic is
    
begin

    -- prop(N-1 downto 0) <= operand_a(N-1 downto 0) xor operand_b(N-1 downto 0);
    -- gen(N-1 downto 0) <= operand_a(N-1 downto 0) and operand_b(N-1 downto 0);
    prop <= operand_a xor operand_b;
    gen <= operand_a and operand_b;
    
end architecture beh;