--------------------------------------------------------------------------------
-- File: Inference_Top_tb.vhd
-- Author: 
-- Date: November 18, 2025
-- Description: Testbench for Inference_Top module
--              Tests the complete hypervector inference system
-- 
-- Revision History:
-- Date          Version     Description
-- 11/18/2025    1.0         Initial creation
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Inference_Top_tb is
end Inference_Top_tb;

architecture Behavioral of Inference_Top_tb is
    
    -- Component Declaration
    component Inference_Top is
        port(
            clk         : in  STD_LOGIC;
            Master_reset       : in  STD_LOGIC;
            start       : in  STD_LOGIC;
            -- Output
            Guess_out   : out STD_LOGIC_VECTOR(4 downto 0);
            Done        : out STD_LOGIC;
            TestHV_done : out STD_LOGIC;          
            current_class_addr : out std_logic_vector(4 downto 0);
            current_testHV_addr : out std_logic_vector(6 downto 0);
            Current_sum_out : out std_logic_vector(13 downto 0);  -- Current Hamming distance accumulator output
            MAX_sum : out std_logic_vector(13 downto 0);  -- Current Hamming distance accumulator output
            state : out string(1 to 5);
            training_done : out std_logic;  -- Signals when training is done
            inference_done : out std_logic;  -- Signals when inference is done
            classHV_changed : out std_logic  -- Signals when ClassHV has been updated

        );
    end component;
    
    -- Test signals
    signal clk         : STD_LOGIC := '0';
    signal Master_reset       : STD_LOGIC := '0';
    signal start       : STD_LOGIC := '0';
    signal Guess_out   : STD_LOGIC_VECTOR(4 downto 0);
    signal Done        : STD_LOGIC;
    signal ClassHV    : std_logic_vector(4 downto 0);
    signal TestHV     : std_logic_vector(6 downto 0);
    signal TestHV_done : std_logic;
    signal Current_sum_out : std_logic_vector(13 downto 0);
    signal MAX_sum : std_logic_vector(13 downto 0);
    signal state : string(1 to 5);
    signal training_done : std_logic;
    signal inference_done : std_logic;
    signal classHV_changed : std_logic;
    
    -- Test control signals
    signal testHV_count : integer := 0;
    
begin
    
    -- Instantiate the Unit Under Test (UUT)
    UUT: Inference_Top
        port map (
            clk       => clk,
            Master_reset     => Master_reset,
            start     => start,
            Guess_out => Guess_out,
            Done      => Done,
            TestHV_done => TestHV_done,            
            current_class_addr => ClassHV,
            current_testHV_addr => TestHV,
            Current_sum_out => Current_sum_out,
            MAX_sum => MAX_sum,
            state => state,
            training_done => training_done,
            inference_done => inference_done,
            classHV_changed => classHV_changed
        );
    
    -- Clock process
    -- Clock generation (runs indefinitely)
    clk_process : process
    begin
        clk <= '0';
        wait for 20 ns;
        clk <= '1';
        wait for 20 ns;
    end process;
    
    -- Stimulus process runs indefinitely
    stim_proc: process
    begin
        
        
        -- Test 1: Reset Test
        Master_reset <= '1';
        start <= '0';
        wait for 100 ns;
        Master_reset <= '0';
        wait for 100 ns;

        -- Test 2: Start Inference and run indefinitely
       
        start <= '1';
        
        -- Run forever
        wait;
        
    

    end process;

end Behavioral;
