--------------------------------------------------------------------------------
-- File: Inference_Top.vhd
-- Author: 
-- Date: November 11, 2025
-- Description: Top-level module for hypervector inference system
--              Connects all components: BIT_SELECT, RAMs, HAMM modules, 
--              Controller, and Guess output
-- 
-- Revision History:
-- Date          Version     Description
-- 11/11/2025    1.0         Initial creation
-- 11/29/2025    1.1         Updated for Single Cycle Inference & Combined HAMM_MAX_GUESS
-- 11/29/2025    1.2         Added pipeline registers for timing alignment
-- 11/29/2025    1.3         Integrated HAMM_COMPLETE (1-cycle latency), removed pipeline registers
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Inference_Top is
    port(
        clk         : in  STD_LOGIC; -- System clock
        reset       : in  STD_LOGIC; -- System reset
        start       : in  STD_LOGIC; -- Start inference process
        
        -- Output
        Guess_out   : out STD_LOGIC_VECTOR(4 downto 0); -- Final classification (0-25)
        Done        : out STD_LOGIC;  -- Inference complete signal
        TestHV_done : out STD_LOGIC;  -- Signals when all TestHVs have been processed
        Current_bit_addr : out std_logic_vector(7 downto 0);  -- Current bit address (UNUSED in single cycle)
        current_class_addr : out std_logic_vector(4 downto 0);  -- Current class address being processed
        current_testHV_addr : out std_logic_vector(6 downto 0);  -- Current TestHV address being processed
        Current_sum_out : out std_logic_vector(13 downto 0);  -- Current Hamming distance accumulator output
        MAX_sum : out std_logic_vector(13 downto 0);  -- Current Hamming distance accumulator output
        state : out string(1 to 5)  -- Current state from Controller for debugging
    );
end Inference_Top;

architecture Structural of Inference_Top is
    
    -- Component Declarations
    component BIT_SELECT is
        port(
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            enable   : in  STD_LOGIC;
            ClassHV  : out std_logic_vector(4 downto 0);
            TestHV   : out std_logic_vector(6 downto 0);
            -- bit_addr : out std_logic_vector(7 downto 0); -- REMOVED
            Done     : out std_logic; -- Signals when all classes processed for one TestHV
            inference_done : out std_logic -- Signals when ALL TestHVs processed
        );
    end component;
    
    component ClassHV_RAM is
        port(
            class_select : in  std_logic_vector(4 downto 0);
            bit_addr     : in  std_logic_vector(7 downto 0);
            RAM_CLOCK    : in  std_logic;
            RAM_EN       : in  std_logic;
            reset        : in  std_logic;
            RAM_DATA_OUT : out std_logic_vector(1023 downto 0);
            CLASS_OUT    : out std_logic_vector(4 downto 0)
            
        );
    end component;
    
    component TestHV_RAM is
        port(
            clk          : in  std_logic;
            reset        : in  std_logic;
            TestHV_addr  : in  std_logic_vector(6 downto 0);
            bit_addr     : in  std_logic_vector(7 downto 0);           
            Read_en      : in  std_logic;
            data_out     : out std_logic_vector(1023 downto 0)
            
        );
    end component;
    
    component HAMM_COMPLETE is
        port(
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            Load     : in  STD_LOGIC;
            TestHV_Done : in  STD_LOGIC;
            A_data_in : in  STD_LOGIC_VECTOR(1023 downto 0);
            B_data_in : in  STD_LOGIC_VECTOR(1023 downto 0);
            Class_in : in  STD_LOGIC_VECTOR(4 downto 0);
            Current_sum : out STD_LOGIC_VECTOR(13 downto 0); -- Current Hamming Distance
            MAX_sum_out : out STD_LOGIC_VECTOR(13 downto 0); -- Current Max Hamming Distance
            Guess_out: out STD_LOGIC_VECTOR(4 downto 0);
            new_max  : out STD_LOGIC
        );
    end component;
    
    component Controller is
        port(
            clk                       : in  std_logic;
            reset                     : in  std_logic;
            start                     : in  std_logic;           
            RAM_EN                    : out std_logic;
            inference_done            : in  std_logic;
            state_out                 : out string(1 to 5)
        );
    end component;
    
    -- Internal Signals
    
    -- BIT_SELECT outputs
    signal ClassHV_addr  : std_logic_vector(4 downto 0);
    signal TestHV_addr_sig   : std_logic_vector(6 downto 0);
    signal bit_addr_sig      : std_logic_vector(7 downto 0) := (others => '0'); -- Default to 0
    signal INF_Done_sig  : std_logic;
    signal ClassHV_Done_sig : std_logic; -- Used as "Done" from BIT_SELECT (One TestHV done)
    
    -- RAM outputs
    signal ClassHV_bit   : std_logic_vector(1023 downto 0);
    signal TestHV_bit    : std_logic_vector(1023 downto 0);
    signal class_out_sig : std_logic_vector(4 downto 0);
    
    
    -- HAMM accumulator signals
    signal hamm_sum      : std_logic_vector(13 downto 0);
    
    -- HAMM MAX signals
    signal max_sum_sig       : std_logic_vector(13 downto 0);
    signal new_max_sig   : std_logic;
    signal current_sum_sig : std_logic_vector(13 downto 0);
    
    -- Controller signals

    signal RAM_EN_sig             : std_logic;
    signal state_out_sig          : string(1 to 5);
    
    --Guess signal
    signal guess_out_sig : std_logic_vector(4 downto 0) ;
  
    
begin
    
    -- Instantiate BIT_SELECT
    U_BIT_SELECT: BIT_SELECT
        port map(
            clk      => clk,
            reset    => reset,
            enable   => RAM_EN_sig,
            ClassHV  => ClassHV_addr,
            TestHV   => TestHV_addr_sig,
            -- bit_addr => bit_addr_sig, -- REMOVED
            Done     => ClassHV_Done_sig, -- Signals when one TestHV is done (all classes checked)
            inference_done => INF_Done_sig -- Signals when ALL TestHVs are done
        );
    
    -- Instantiate ClassHV_RAM
    U_ClassHV_RAM: ClassHV_RAM
        port map(
            class_select => ClassHV_addr,
            bit_addr     => bit_addr_sig, -- Tied to 0
            RAM_CLOCK    => clk,
            reset        => reset,
            RAM_EN       => RAM_EN_sig,
            RAM_DATA_OUT => ClassHV_bit,
            CLASS_OUT    => class_out_sig
        );
    
    -- Instantiate TestHV_RAM
    U_TestHV_RAM: TestHV_RAM
        port map(
            clk          => clk,
            reset        => reset,
            read_en      => RAM_EN_sig,
            TestHV_addr  => TestHV_addr_sig,
            bit_addr     => bit_addr_sig, -- Tied to 0
            data_out     => TestHV_bit
            );
    
    -- Instantiate HAMM_COMPLETE (Combined Module)
    U_HAMM_COMPLETE: HAMM_COMPLETE
        port map(
            clk      => clk,
            reset    => reset,
            Load     => RAM_EN_sig,
            TestHV_Done => ClassHV_Done_sig, -- Use DIRECT signal (no delay needed)
            A_data_in => ClassHV_bit,
            B_data_in => TestHV_bit,
            Class_in => class_out_sig,       -- Use DIRECT signal (no delay needed)
            
            Guess_out => guess_out_sig,
            new_max  => new_max_sig,
            MAX_sum_out => max_sum_sig ,
            Current_sum => current_sum_sig
        );
    
    -- Instantiate Controller
    U_Controller: Controller
        port map(
            clk                        => clk,
            reset                      => reset,
            start                      => start,
            inference_done             => INF_Done_sig,
            RAM_EN                     => RAM_EN_sig,
            state_out                  => state_out_sig
        );
    
    -- Output assignments
    Done <= INF_Done_sig;
    Guess_out <= guess_out_sig;
    Current_bit_addr <= bit_addr_sig; -- Will be 0
    TestHV_done <= ClassHV_Done_sig; -- Output the direct Done signal
    current_class_addr <= ClassHV_addr;
    current_testHV_addr <= TestHV_addr_sig;
    MAX_sum <= max_sum_sig; -- Outputting max_sum here as hamm_sum is internal to HAMM_COMPLETE now
    Current_sum_out <= current_sum_sig; -- Output the current sum from HAMM_COMPLETE
    state <= state_out_sig; -- Output the current state from Controller for debugging
end Structural;
--MAX_sum_out