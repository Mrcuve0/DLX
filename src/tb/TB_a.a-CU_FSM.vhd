library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.myTypes.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity TB_CU_FSM is
end entity;

architecture TB_arch of TB_CU_FSM is

    constant period : time := 2 ns;

    -- Input
    signal IR_IN_s : std_logic_vector(IR_SIZE - 1 downto 0);
    signal clk_s, rst_n_s : std_logic;

    -- Output
    -- Rst-PipeRegisters Control Signals
    signal Rst_IF_ID_s   : std_logic;
    signal Rst_ID_EXE_s  : std_logic;
    signal Rst_EXE_MEM_s : std_logic;
    signal Rst_MEM_WB_s  : std_logic;

    -- IF-Stage Control Signals
    signal PC_LATCH_EN_s  : std_logic;       -- Program Counter Latch Enable
    signal NPC_LATCH_EN_s : std_logic;       -- NextProgramCounter Latch Enable
    signal IR_LATCH_EN_s  : std_logic;       -- Instruction Register Latch Enable

    -- ID-Stage Control Signals
    signal BRANCH_SEL_s         : std_logic;
    signal JUMP_EN_s            : std_logic;
    signal JUMP_SEL_s           : std_logic;
    signal NPC_LATCH_EN_ID_s    : std_logic;
    signal RegA_LATCH_EN_ID_s   : std_logic;  -- Register A Latch Enable
    signal RegB_LATCH_EN_ID_s   : std_logic;  -- Register B Latch Enable
    signal RegImm_LATCH_EN_ID_s : std_logic;  -- Immediate Register Latch Enable
    signal Rd_LATCH_EN_ID_s     : std_logic;
    signal RegMux_SEL_s         : std_logic_vector(1 downto 0);
    signal Sign_SEL_s           : std_logic;

    -- EX-Stage Control Signals
    signal MuxB_SEL_s          : std_logic;  -- MUX-B Sel
    -- Alu Operation Code
    signal ALU_OPCODE_s        : std_logic_vector(ALU_OPC_SIZE - 1 downto 0);  -- choose between implicit or explicit coding, like std_logic_vector(ALU_OPC_SIZE -1 downto 0);
    signal NPC_LATCH_EN_EXE_s  : std_logic;
    signal ALU_OUTREG_EN_EXE_s : std_logic;  -- ALU Output Register Enable
    signal RegB_LATCH_EN_EXE_s : std_logic;
    signal RD_LATCH_EN_EXE_s   : std_logic;

    -- MEM-Stage Control Signals
    signal DRAM_WE_s           : std_logic;  -- Data RAM Write Enable
    signal NPC_LATCH_EN_MEM_s  : std_logic;
    signal LMD_LATCH_EN_s      : std_logic;  -- LMD Register Latch Enable
    signal ALU_OUTREG_EN_MEM_s : std_logic;
    signal RD_LATCH_EN_MEM_s   : std_logic;

    -- WB Control signals
    signal WB_MUX_SEL_s : std_logic_vector(1 downto 0);  -- Write Back MUX Sel
    signal RF_WE_s      : std_logic;         -- Register File Write Enable
    
--------------------------------------------------------------------------------
-- Simulation Signals
--------------------------------------------------------------------------------
    signal opName_s            : string(1 to 5);
    signal expectedCW_s : std_logic_vector(CW_SIZE - 1 downto 0);
--------------------------------------------------------------------------------
-- Memory Stub
--------------------------------------------------------------------------------
    type mem_array_s is array (integer range 0 to MICROCODE_MEM_SIZE - 1) of std_logic_vector(CW_SIZE - 1 downto 0);
    type alu_mem_array_s is array (integer range 0 to ALU_OPC_MEM_SIZE - 1) of std_logic_vector(ALU_OPC_SIZE - 1 downto 0);
  
    signal cw_mem_s : mem_array_s := (
    "1010010110101001010010100011101",  -- R type: (DA cambiare, ho riordinato i control signals per stage di appartenenza)
    "0000000000000000000000000000000",
    "1110110000011101010000000000110",  -- J (0X02) instruction encoding corresponds to the address to this ROM
    "1110111000110101010100101001001",  -- JAL to be filled
    "1110000000011101010000000000110",  -- BEQZ to be filled
    "1111000000011101010000000000110",  -- BNEZ
    "0000000000000000000000000000000",  -- BFPT
    "0000000000000000000000000000000",  -- BFPF
    "1010010101100110010010100011101",  -- ADDI
    "0000000000000000000000000000000",  -- ADDUI
    "1010010101100110011010100011101",  -- SUBI
    "0000000000000000000000000000000",
    "1010010101100010100010100011101",  -- ANDI
    "1010010101100010101010100011101",  -- ORI
    "1010010101100010110010100011101",  -- XORI
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "1010010101100010000010100011101",  -- SLLI
    "0000000000000000000000000000000",  -- NOP!!
    "1010010101100010001010100011101",  -- SRLI
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "1010010101100110111010100011101",  -- SNEI
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "1010010101100111000010100011101",  -- SLEI
    "1010010101100111001010100011101",  -- SGEI
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "1010010101100110010010100101011",  -- LW
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "1010010111000110010011010000110",  -- SW
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "0000000000000000000000000000000",
    "0000000000000000000000000000000"
    );

    signal aluOpcode_mem_s : alu_mem_array := (  -- Indirizzata da FUNC
    "0000",
    "0000",
    "0000",
    "0000",
    "0000",                                -- SLL
    "0001",                                -- SRL
    "0000",
    "0010",                                -- ADD
    "0000",
    "0011",                                -- SUB
    "0000",
    "0100",                                -- AND
    "0101",                                -- OR
    "0110",                                -- XOR
    "0000",
    "0111",                                -- NE
    "0000",
    "0000",
    "1000",                                -- LE
    "1001"                                 -- GE
    );

    component dlx_cu is
        generic (
          MICROCODE_MEM_SIZE : integer := 47;   -- Microcode Memory Size (27 base)
          ALU_OPC_MEM_SIZE   : integer := 20;   -- AluOpcode Memory Size (9 per ora)
          IR_SIZE            : integer := 32;   -- Instruction Register Size
          OPCODE_SIZE        : integer := 6;    -- Op Code Size
          FUNC_SIZE          : integer := 11;   -- Func Field Size for R-Type Ops
          ALU_OPC_SIZE       : integer := 4;    -- ALU Op Code Word Size
          CW_SIZE            : integer := 31);  -- Control Word Size (CWs + ALUOPCODE)
      
        port (
					IR_IN : in std_logic_vector(IR_SIZE - 1 downto 0);

          Clk   : in std_logic;               -- Clock
          Rst_n : in std_logic;               -- Reset:Active-Low
      
          -- Rst-PipeRegisters Control Signals
          Rst_IF_ID   : out std_logic;
          Rst_ID_EXE  : out std_logic;
          Rst_EXE_MEM : out std_logic;
          Rst_MEM_WB  : out std_logic;
      
          -- IF-Stage Control Signals
          PC_LATCH_EN  : out std_logic;       -- Program Counter Latch Enable
          NPC_LATCH_EN : out std_logic;       -- NextProgramCounter Latch Enable
          IR_LATCH_EN  : out std_logic;       -- Instruction Register Latch Enable
      
          -- ID-Stage Control Signals
          BRANCH_SEL         : out std_logic;
          JUMP_EN            : out std_logic;
          JUMP_SEL           : out std_logic;
          NPC_LATCH_EN_ID    : out std_logic;
          RegA_LATCH_EN_ID   : out std_logic;  -- Register A Latch Enable
          RegB_LATCH_EN_ID   : out std_logic;  -- Register B Latch Enable
          RegImm_LATCH_EN_ID : out std_logic;  -- Immediate Register Latch Enable
          Rd_LATCH_EN_ID     : out std_logic;
          RegMux_SEL         : out std_logic_vector(1 downto 0);
          Sign_SEL           : out std_logic;
      
          -- EX-Stage Control Signals
          MuxB_SEL          : out std_logic;  -- MUX-B Sel
          -- Alu Operation Code
          ALU_OPCODE        : out std_logic_vector(ALU_OPC_SIZE - 1 downto 0);  -- choose between implicit or explicit coding, like std_logic_vector(ALU_OPC_SIZE -1 downto 0);
          NPC_LATCH_EN_EXE  : out std_logic;
          ALU_OUTREG_EN_EXE : out std_logic;  -- ALU Output Register Enable
          RegB_LATCH_EN_EXE : out std_logic;
          RD_LATCH_EN_EXE   : out std_logic;
      
          -- MEM-Stage Control Signals
          DRAM_WE           : out std_logic;  -- Data RAM Write Enable
          NPC_LATCH_EN_MEM  : out std_logic;
          LMD_LATCH_EN      : out std_logic;  -- LMD Register Latch Enable
          ALU_OUTREG_EN_MEM : out std_logic;
          RD_LATCH_EN_MEM   : out std_logic;
      
          -- WB Control signals
          WB_MUX_SEL : out std_logic_vector(1 downto 0);  -- Write Back MUX Sel
          RF_WE      : out std_logic         -- Register File Write Enable
          );
      
    end component;

begin

    dlx_cu_1: dlx_cu port map(
        IR_IN_s              ,
        clk_s, rst_n_s       ,
        Rst_IF_ID_s          ,
        Rst_ID_EXE_s         ,
        Rst_EXE_MEM_s        ,
        Rst_MEM_WB_s         ,
        PC_LATCH_EN_s        ,
        NPC_LATCH_EN_s       ,
        IR_LATCH_EN_s        ,
        BRANCH_SEL_s         ,             
        JUMP_EN_s            ,
        JUMP_SEL_s           ,
        NPC_LATCH_EN_ID_s    ,
        RegA_LATCH_EN_ID_s   ,
        RegB_LATCH_EN_ID_s   ,
        RegImm_LATCH_EN_ID_s ,
        Rd_LATCH_EN_ID_s     ,
        RegMux_SEL_s         ,
        Sign_SEL_s           ,
        MuxB_SEL_s           ,
        ALU_OPCODE_s         ,
        NPC_LATCH_EN_EXE_s   ,
        ALU_OUTREG_EN_EXE_s  ,
        RegB_LATCH_EN_EXE_s  ,
        RD_LATCH_EN_EXE_s    ,
        DRAM_WE_s            ,
        NPC_LATCH_EN_MEM_s   ,
        LMD_LATCH_EN_s       ,
        ALU_OUTREG_EN_MEM_s  ,
        RD_LATCH_EN_MEM_s    ,
        WB_MUX_SEL_s         ,
        RF_WE_s              
    );

    clk_stimuli: process
    begin

        clk_s <= '0';
        wait for period/2;
        clk_s <= '1';
        wait for period/2;

    end process clk_stimuli;

    input_stimuli: process
				variable inputLine : line;
				variable ok : boolean;
				-- variable instructionReg : IR_IN_s'subtype;
        variable instructionReg : std_logic_vector(IR_SIZE - 1 downto 0);
        variable opName : string(1 to 5);
        variable expectedCW : std_logic_vector(CW_SIZE - 1 downto 0);
        file vectorFile : text;

    begin
        file_open(vectorFile, "./../all_base_bin_dump.txt", read_mode);

        rst_n_s <= '0';
        wait for 3 ns;
        rst_n_s <= '1';

        while not endfile(vectorFile) loop
            readline(vectorFile, inputLine);

            read(inputLine, instructionReg, ok);
            assert ok
                report "Read 'IR_IN_s' failed for line: " & inputLine.all
                severity failure;

            read(inputLine, opName, ok);
            assert ok
              report "Read 'opName' failed for line: " & inputLine.all
              severity failure;

            IR_IN_s <= instructionReg;
            opName_s <= opName;

            -- if RTYPE
              -- Usiamo il campo FUNC dall'IR per indirizzare l'aluOpcode giusto dalla memoria (ottenendo expectedAluCopcode)
              -- fatto questo, compariamo expectedAluCopcode con ALU_OPCODE_s (segnale reale). Se sono uguali allora controlliamo
              -- il resto della control word (eliminando ALU_OPCODE_s o inserendola)
              -- Se invece sono diverse allora errore (specifichiamo che riguarda l'aluOpcode)
            -- else
              -- controlliamo direttamente la expectedCW_s con quella ottenuta dalla concatenazione dei segnali di uscita


            obtainedCW_s <= PC_LATCH_EN_s & NPC_LATCH_EN_s & IR_LATCH_EN_s & BRANCH_SEL_s & JUMP_EN_s &
              JUMP_SEL_s & NPC_LATCH_EN_ID_s & RegA_LATCH_EN_ID_s & RegB_LATCH_EN_ID_s & RegImm_LATCH_EN_ID_s &
              Rd_LATCH_EN_ID_s & RegMux_SEL_s & Sign_SEL_s & MuxB_SEL_s & ALU_OPCODE_s & NPC_LATCH_EN_EXE_s &
              ALU_OUTREG_EN_EXE_s & RegB_LATCH_EN_EXE_s & RD_LATCH_EN_EXE_s & DRAM_WE_s & NPC_LATCH_EN_MEM_s &
              LMD_LATCH_EN_s & ALU_OUTREG_EN_MEM_s & RD_LATCH_EN_MEM_s & WB_MUX_SEL_s & RF_WE_s;


            -- Se R-TYPE
            if IR_IN_s(IR_SIZE - 1 downto IR_SIZE - OPCODE_SIZE) = "000000" then
              -- Estraiamo func
              func_var <= IR_IN_s(IR_SIZE - OPCODE_SIZE - 1 downto IR_SIZE - OPCODE_SIZE - FUNC_SIZE);
              expectedAluOpcode <= alu_mem_array_s(to_integer(unsigned(func_var)));
              if expectedAluOpcode /= 
            end if;



            if (expectedCW_s /= cw_mem_s(to_integer(unsigned(IR_IN_s(IR_SIZE - 1 downto IR_SIZE - OPCODE_SIZE))))) then
              report "ExpectedCW DIFFERS!!!"
              severity failure;
            end if;

            wait until rising_edge(clk_s);
        end loop;

				file_close(vectorFile);
			wait;
    end process input_stimuli;

end architecture;