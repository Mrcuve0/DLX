library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CarryGen_Array is
    generic (
        -- TODO: Update constant value w/ generic constant in work library
        N : integer := 32
    );
    port (
        Cin : in std_logic;
        prop: in std_logic_vector(N-1 downto 0);
        gen : in std_logic_vector(N-1 downto 0);
        Cout : out std_logic_vector(N downto 0)
    );
end entity CarryGen_Array;


--------------------------------------------------------------------------------
-- Behavioral Architecture
--------------------------------------------------------------------------------

architecture beh of CarryGen_Array is

    signal C0 : std_logic;
    signal Cout_s : std_logic_vector(N downto 1);

    component CarryGen_Block is
        port (
            Cin: in std_logic;
            prop: in std_logic;
            gen : in std_logic;
            Cout: out std_logic
        );
    end component CarryGen_Block;
    
begin

    Cout(0) <= Cin;
    Cout(N downto 1) <= Cout_s;
    
    CGA_gen: for i in 0 to N-1 generate
            firstBlock: if i = 0 generate
                block_0: CarryGen_Block port map(
                    Cin => Cin,
                    prop => prop(i),
                    gen => gen(i),
                    Cout => Cout_s(i+1)
                );
            end generate firstBlock;
            remainingBlocks: if i > 0 generate
                block_i: CarryGen_Block port map(
                    Cin => Cout_s(i),
                    prop => prop(i),
                    gen => gen(i),
                    Cout => Cout_s(i+1)
                );
            end generate remainingBlocks;
        
    end generate CGA_gen;
    
end architecture beh;


