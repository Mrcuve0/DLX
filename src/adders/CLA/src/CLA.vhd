library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CLA is
    generic (
        -- TODO: Update constant value w/ generic constant in work library
        N : integer := 32
    );
    port (
        operand_a : in std_logic_vector(N-1 downto 0);
        operand_b : in std_logic_vector(N-1 downto 0);
        Cin       : in std_logic;
        sum       : out std_logic_vector(N-1 downto 0);
        Cout      : out std_logic
    );
end entity CLA;


--------------------------------------------------------------------------------
-- Structural Architecture
--------------------------------------------------------------------------------

architecture rtl of CLA is

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

    component CarryGen_Array is
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
    end component CarryGen_Array;

    component SumLogic is
        generic (
            -- TODO: Update constant value w/ generic constant in work library
            N : integer := 32
        );
        port (
            Cin : in std_logic_vector(N-1 downto 0);
            prop : in std_logic_vector(N-1 downto 0);
            sum : out std_logic_vector(N-1 downto 0)
        );
    end component SumLogic;

    signal PGLtoCGAprop, PGLtoCGAgen : std_logic_vector(N-1 downto 0);
    signal carries : std_logic_vector(N downto 0);
    
begin
    
    PGLogic_1 : PGLogic port map (
        operand_a => operand_a,
        operand_b => operand_b,
        prop => PGLtoCGAprop,
        gen => PGLtoCGAgen
    );

    CarryGen_Array_1 : CarryGen_Array port map (
        Cin => Cin,
        prop => PGLtoCGAprop,
        gen => PGLtoCGAgen,
        Cout => carries
    );

    SumLogic_1 : SumLogic port map (
        Cin => carries(N-1 downto 0),
        prop => PGLtoCGAprop,
        sum => sum
    );

    Cout <= carries(N);
    
end architecture rtl;