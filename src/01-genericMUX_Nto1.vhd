library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

-- use work.myTypes.all;

entity genericMUX_Nto1 is
    generic(
        nDataBit_mux : integer := 32;
        nChannels_mux : integer := 8
    );
    port(
        in1 : in std_logic_vector((nChannels_mux * nDataBit_mux) - 1 downto 0);       -- Input channels must be chained together (MSB In1 corresponds to nChannel)
        sel : in std_logic_vector(integer(ceil(log2(real(nChannels_mux)))) - 1 downto 0);
        out1 : out std_logic_vector(nDataBit_mux - 1 downto 0)
    );
end entity;

--------------------------------------------------------------------------------
-- Structural Architecture
--------------------------------------------------------------------------------
architecture rtl of genericMUX_Nto1 is

    component genericMUX_2to1 is
        generic(
            nDataBit_mux : integer := 32
        );
        port(
            in1, in2 : in std_logic_vector(nDataBit_mux - 1 downto 0);
            sel : in std_logic;
            out1 : out std_logic_vector(nDataBit_mux - 1 downto 0)
        );
    end component;


    constant nSel_mux : integer := integer(ceil(log2(real(nChannels_mux))));

    type signalVector is array (0 to nSel_mux) of std_logic_vector((nDataBit_mux * nChannels_mux) - 1 downto 0);
    signal sigMatrix : signalVector;

    signal sel_s : std_logic_vector(nSel_mux - 1 downto 0);

begin

    sigMatrix(0) <= in1;
    sel_s <= not sel;

    -- Assegnazione segnali alla matrice rigaXriga

    mux_levels: for level in 0 to nSel_mux - 1 generate
        mux_muxes: for i in 0 to (nChannels_mux / (2**(level + 1))) - 1 generate

            -- sigMatrix(level)( (nChannels_mux*nDataBit_mux-1 - i*(2*nDataBit_mux + 2*nDataBit_mux*level)) 
                                        -- downto (nChannels_mux*nDataBit_mux-1 - i*(2*nDataBit_mux + 2*nDataBit_mux*level) - nDataBit_mux-1)

            mux_i : genericMUX_2to1 generic map (nDataBit_mux) 
                    port map    (   in1 => sigMatrix(level)( ((8*32)-1 - i*(2*32 + 2*(32*level))) downto ((8*32)-1 - i*(2*32 + 2*(32*level)) - 32-1) ), 



                                    in2 =>  sigMatrix(level)( ((nChannels_mux*nDataBit_mux)-1 - i*(2*nDataBit_mux + 2*nDataBit_mux*level) - nDataBit_mux*(2**level)) 
                                        downto ((nChannels_mux*nDataBit_mux)-1 - i*(2*nDataBit_mux + 2*nDataBit_mux*level) - nDataBit_mux*(2**level) - nDataBit_mux-1) ),
                                    sel => sel_s(level),
                                    out1 => sigMatrix(level+1)( (nChannels_mux*nDataBit_mux-1 - i*(2*nDataBit_mux + 2*nDataBit_mux*level)) 
                                        downto (nChannels_mux*nDataBit_mux-1 - i*(2*nDataBit_mux + 2*nDataBit_mux*level) - nDataBit_mux-1) ) 
                                );
        end generate mux_muxes;
    end generate mux_levels;
    
end architecture rtl;