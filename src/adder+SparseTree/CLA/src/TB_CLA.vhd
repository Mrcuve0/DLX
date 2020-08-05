library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TB_CLA is
end entity TB_CLA;

architecture beh of TB_CLA is

    component LFSR32 is
        port (
            CLK    : in std_logic;
            RESET  : in std_logic;
            LD     : in std_logic;
            EN     : in std_logic;
            DIN    : in std_logic_vector (31 downto 0);
            PRN    : out std_logic_vector (31 downto 0);
            ZERO_D : out std_logic);
    end component LFSR32;

    component CLA is
        generic (
            -- TODO: Update constant value w/ generic constant in work library
            N : integer := 32
        );
        port (
            operand_a : in std_logic_vector(N - 1 downto 0);
            operand_b : in std_logic_vector(N - 1 downto 0);
            Cin       : in std_logic;
            sum       : out std_logic_vector(N - 1 downto 0);
            Cout      : out std_logic
        );
    end component CLA;

    constant N : integer := 32;

    constant period                      : time      := 1 ns;
    signal clk_s                         : std_logic := '0';
    signal reset_s, ld_s, en_s, zero_d_s : std_logic;
    signal din_s, prn_s                  : std_logic_vector(31 downto 0);

    signal operand_a_s, operand_b_s : std_logic_vector(N - 1 downto 0);
    signal sum_s                    : std_logic_vector(N - 1 downto 0);
    signal Cout_s, Cin_s            : std_logic;

begin

    LFSR_1 : LFSR32 port map(
        clk    => clk_s,
        reset  => reset_s,
        ld     => ld_s,
        en     => en_s,
        din    => din_s,
        prn    => prn_s,
        zero_d => zero_d_s
    );

    CLA_1 : CLA port map(
        operand_a => operand_a_s,
        operand_b => operand_b_s,
        Cin       => Cin_s,
        sum       => sum_s,
        Cout      => Cout_s
    );

    clk_s   <= not clk_s after period/2;
    reset_s <= '1', '0' after period;

    stimuli : process
    begin

        Cin_s       <= '0';
        operand_a_s <= X"0000FFFF";
        operand_b_s <= X"000000FF";
        wait for 2 ns;

        operand_a_s <= X"FFFFFFFF";
        operand_b_s <= X"FFFFFFFF";
        wait for 2 ns;

        operand_a_s <= X"FFFF0000";
        operand_b_s <= X"0001FFFF";
        wait for 2 ns;

        operand_a_s <= X"FFFFFFFF";
        operand_b_s <= X"00000001";
        wait for 2 ns;

        Cin_s       <= '1';
        operand_a_s <= X"0000FFFF";
        operand_b_s <= X"000000FF";
        wait for 2 ns;

        operand_a_s <= X"FFFFFFFF";
        operand_b_s <= X"FFFFFFFF";
        wait for 2 ns;

        operand_a_s <= X"FFFF0000";
        operand_b_s <= X"0001FFFF";
        wait for 2 ns;

        operand_a_s <= X"FFFFFFFF";
        operand_b_s <= X"00000001";
        wait for 2 ns;

        wait;
    end process stimuli;

    -----------------------------------------------------------------------------
    -- Comment/Uncomment for LFSR input
    -----------------------------------------------------------------------------
    --Cin_s <= '0';      -- Test ADDER functionalities
    --Cin_s  <= '1';     -- Test SUBTRACTOR functionalities
    --operand_a_s(0) <= prn_s(0);
    --operand_a_s(5) <= prn_s(2);
    --operand_a_s(3) <= prn_s(4);
    --operand_a_s(1) <= prn_s(6);
    --operand_a_s(4) <= prn_s(8);
    --operand_a_s(2) <= prn_s(10);
    --operand_a_s(6) <= prn_s(12);
    --operand_a_s(7) <= prn_s(14);

    --operand_b_s(0) <= prn_s(15);
    --operand_b_s(5) <= prn_s(13);
    --operand_b_s(3) <= prn_s(11);
    --operand_b_s(1) <= prn_s(9);
    --operand_b_s(4) <= prn_s(7);
    --operand_b_s(2) <= prn_s(5);
    --operand_b_s(6) <= prn_s(3);
    --operand_b_s(7) <= prn_s(1);

    LFSR_stimuli : process
    begin
        din_s <= X"00000001";
        en_s  <= '1';
        ld_s  <= '1';
        wait for 2 * period;
        ld_s <= '0';
        wait for (65600 * period);
    end process LFSR_stimuli;

end architecture beh;