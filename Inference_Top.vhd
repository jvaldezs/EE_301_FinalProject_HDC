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

-- Package for shared types
package TrainingHV_types is
    type Class_RAM_ARRAY is array (0 to 25) of STD_LOGIC_VECTOR(1023 downto 0);
end package TrainingHV_types;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TrainingHV_types.all;

entity Inference_Top is
    port(
        clk         : in  STD_LOGIC; -- System clock
        Master_reset       : in  STD_LOGIC; -- System reset
        start       : in  STD_LOGIC; -- Start inference process
        
        -- Output
        Guess_out   : out STD_LOGIC_VECTOR(4 downto 0); -- Final classification (0-25)
        Done        : out STD_LOGIC;  -- Inference complete signal
        TestHV_done : out STD_LOGIC;  -- Signals when all TestHVs have been processed       
        current_class_addr : out std_logic_vector(4 downto 0);  -- Current class address being processed
        current_testHV_addr : out std_logic_vector(6 downto 0);  -- Current TestHV address being processed
        Current_sum_out : out std_logic_vector(13 downto 0);  -- Current Hamming distance accumulator output
        MAX_sum : out std_logic_vector(13 downto 0);  -- Current Hamming distance accumulator output
        state : out string(1 to 5);  -- Current state from Controller for debugging
        training_done : out std_logic;  -- Signals when training is done
        inference_done : out std_logic;  -- Signals when inference is done
        classHV_changed : out std_logic  -- Signals when ClassHV has been updated

    );
end Inference_Top;

architecture Structural of Inference_Top is
    
    -- Component Declarations
    component BIT_SELECT is
        port(
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            enable   : in  STD_LOGIC;
            Class0_ready : in STD_LOGIC;
            ClassHV  : out std_logic_vector(4 downto 0);
            TestHV   : out std_logic_vector(6 downto 0);         
            Done     : out std_logic; -- Signals when all classes processed for one TestHV
            inference_done : out std_logic; -- Signals when ALL TestHVs processed
            class_array_change : in std_logic;
            Train_EN : in STD_LOGIC
        );
    end component;
    
    component DATAFLOW is
        port(
            clk                 : in  STD_LOGIC;
            Master_reset               : in  STD_LOGIC;
            start               : in  STD_LOGIC;
            inference_done      : in  STD_LOGIC;
            ClassHV_addr        : in  STD_LOGIC_VECTOR(4 downto 0);
            TestHV_addr         : in  STD_LOGIC_VECTOR(6 downto 0);
            TestHV_Done         : in  STD_LOGIC;
            Guess_out           : out STD_LOGIC_VECTOR(4 downto 0);
            Current_sum         : out STD_LOGIC_VECTOR(13 downto 0);
            MAX_sum             : out STD_LOGIC_VECTOR(13 downto 0);
            Class0_processed    : out STD_LOGIC;
            training_done       : out STD_LOGIC;
            RAM_EN              : out STD_LOGIC;
            Train_EN            : out STD_LOGIC;
            state_out           : out string(1 to 5);
            reset               : out STD_LOGIC;
            class_array_changed : out STD_LOGIC
            

        );
    end component;
    
    -- Internal Signals
    
    -- BIT_SELECT outputs
    signal ClassHV_addr         : std_logic_vector(4 downto 0);
    signal TestHV_addr_sig      : std_logic_vector(6 downto 0);
    signal INF_Done_sig         : std_logic;
    signal ClassHV_Done_sig     : std_logic;
    
    -- DATAFLOW outputs
    signal guess_out_sig        : std_logic_vector(4 downto 0);
    signal max_sum_sig          : std_logic_vector(13 downto 0);
    signal current_sum_sig      : std_logic_vector(13 downto 0);
    signal class0_processed_sig : std_logic;
    signal training_done_sig    : std_logic;
    
    -- Controller signals 
    signal RAM_EN_sig           : std_logic;
    signal Train_EN_sig         : std_logic;
    signal state_out_sig        : string(1 to 5);
    signal reset_sig            : std_logic;

    -- ClassHV change signal
    signal Class_corrected_sig  : std_logic;

    
begin
    
    -- Instantiate BIT_SELECT
    U_BIT_SELECT: BIT_SELECT
        port map(
            clk      => clk,
            reset    => reset_sig,
            enable   => RAM_EN_sig,
            Class0_ready => class0_processed_sig,
            ClassHV  => ClassHV_addr,
            TestHV   => TestHV_addr_sig,            
            Done     => ClassHV_Done_sig, -- Signals when one TestHV is done (all classes checked)
            inference_done => INF_Done_sig, -- Signals when ALL TestHVs are done
            class_array_change => Class_corrected_sig,
            Train_EN => Train_EN_sig
        );
    
    -- Instantiate DATAFLOW (encapsulates RAMs, HAMM, Training, and Controller)
    U_DATAFLOW: DATAFLOW
        port map(
            clk              => clk,
            Master_reset            => Master_reset,
            start            => start,
            inference_done   => INF_Done_sig,
            ClassHV_addr     => ClassHV_addr,
            TestHV_addr      => TestHV_addr_sig,
            TestHV_Done      => ClassHV_Done_sig,
            Guess_out        => guess_out_sig,
            Current_sum      => current_sum_sig,
            MAX_sum          => max_sum_sig,
            Class0_processed => class0_processed_sig,
            training_done    => training_done_sig,
            RAM_EN           => RAM_EN_sig,
            Train_EN         => Train_EN_sig,
            state_out        => state_out_sig,
            reset            => reset_sig,
            class_array_changed => Class_corrected_sig
        );
    
    -- Output assignments
    Done               <= INF_Done_sig;
    Guess_out          <= guess_out_sig;
    TestHV_done        <= ClassHV_Done_sig;
    current_class_addr <= ClassHV_addr;
    current_testHV_addr<= TestHV_addr_sig;
    MAX_sum            <= max_sum_sig;
    Current_sum_out    <= current_sum_sig;
    state              <= state_out_sig;
    inference_done    <= INF_Done_sig;
    training_done     <= training_done_sig;
    classHV_changed   <= Class_corrected_sig;

end Structural;
