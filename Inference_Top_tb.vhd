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
            reset       : in  STD_LOGIC;
            start       : in  STD_LOGIC;
            Guess_out   : out STD_LOGIC_VECTOR(4 downto 0);
            Done        : out STD_LOGIC;
            TestHV_done : out STD_LOGIC;
            Current_bit_addr : out std_logic_vector(7 downto 0);
            current_class_addr : out std_logic_vector(4 downto 0);
            current_testHV_addr : out std_logic_vector(6 downto 0);
            Current_sum_out : out std_logic_vector(13 downto 0);  -- Current Hamming distance accumulator output
            MAX_sum : out std_logic_vector(13 downto 0);  -- Current Hamming distance accumulator output
            state : out string(1 to 5)
        );
    end component;
    
    -- Test signals
    signal clk         : STD_LOGIC := '0';
    signal reset       : STD_LOGIC := '0';
    signal start       : STD_LOGIC := '0';
    signal Guess_out   : STD_LOGIC_VECTOR(4 downto 0);
    signal Done        : STD_LOGIC;
    signal ClassHV    : std_logic_vector(4 downto 0);
    signal TestHV     : std_logic_vector(6 downto 0);
    signal bit_addr   : std_logic_vector(7 downto 0);
    signal TestHV_done : std_logic;
    signal Current_sum_out : std_logic_vector(13 downto 0);
    signal MAX_sum : std_logic_vector(13 downto 0);
    signal state : string(1 to 5);
    
    -- Test control signals
    signal testHV_count : integer := 0;
    
begin
    
    -- Instantiate the Unit Under Test (UUT)
    UUT: Inference_Top
        port map (
            clk       => clk,
            reset     => reset,
            start     => start,
            Guess_out => Guess_out,
            Done      => Done,
            TestHV_done => TestHV_done,
            Current_bit_addr => bit_addr,
            current_class_addr => ClassHV,
            current_testHV_addr => TestHV,
            Current_sum_out => Current_sum_out,
            MAX_sum => MAX_sum,
            state => state
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
    
    -- Stimulus process (runs indefinitely)
    stim_proc: process
    begin
        reset <= '1';
        start <= '0';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        start <= '1';
        
        -- Run forever
        wait;
        
    end process;

    -- Monitor process - continuous monitoring of signals
    monitor_process: process(clk)
        variable prev_TestHV_Done : std_logic := '0';
        variable prev_Done : std_logic := '0';
    begin
        if rising_edge(clk) then
            if TestHV_done = '1' and prev_TestHV_Done = '0' then
                report "TestHV_Done asserted at time " & time'image(now) &
                       " | TestHV=" & integer'image(to_integer(unsigned(TestHV))) &
                       " | Guess=" & integer'image(to_integer(unsigned(Guess_out))) &
                       " | Hamm_Sum=" & integer'image(to_integer(unsigned(Current_sum_out)));
            end if;
            if Done = '1' and prev_Done = '0' then
                report "Done signal asserted at time " & time'image(now) &
                       " | Final Guess=" & integer'image(to_integer(unsigned(Guess_out)));
            end if;
            
            prev_TestHV_Done := TestHV_done;
            prev_Done := Done;
        end if;
    end process;

end Behavioral;

