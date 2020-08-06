library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TB_PGLogic is
end entity TB_PGLogic;

architecture beh of TB_PGLogic is

    constant N: integer := 32;

    component PGLogic is
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
    end component PGLogic;

    signal operand_a_s, operand_b_s: std_logic_vector(N-1 downto 0);
    signal prop_s, gen_s: std_logic_vector(N-1 downto 0);
    
begin

    PGLogic_1: PGLogic port map(
        operand_a => operand_a_s, 
        operand_b => operand_b_s, 
        prop => prop_s, 
        gen => gen_s);
    
    stimuli: process
    begin
        operand_a_s <= X"00000000";
        operand_b_s <= X"FFFFFFFF";
        wait for 2 ns;

        operand_a_s <= X"55555555";
        operand_b_s <= X"55555555";
        wait for 2 ns;

        operand_a_s <= X"AAAAAAAA";
        operand_b_s <= X"00000000";
        wait for 2 ns;

        operand_a_s <= X"AAAAAAAA";
        operand_b_s <= X"55555555";
        wait for 2 ns;

        operand_a_s <= X"AAAAAAAA";
        operand_b_s <= X"AAAAAAAA";
        wait for 2 ns;


        wait;        
    end process stimuli;
    
    
end architecture beh;