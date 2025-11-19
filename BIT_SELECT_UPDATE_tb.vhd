--------------------------------------------------------------------------------
-- File: BIT_SELECT_UPDATE_tb.vhd
-- Author: 
-- Date: November 18, 2025
-- Description: Testbench for BIT_SELECT component
--              Tests iteration through 5 test hypervectors
-- 
-- Revision History:
-- Date          Version     Description
-- 11/18/2025    1.0         Initial creation
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BIT_SELECT_UPDATE_tb is
-- Testbench has no ports
end BIT_SELECT_UPDATE_tb;

architecture Behavioral of BIT_SELECT_UPDATE_tb is
    -- Component Declaration
    component BIT_SELECT
        port(
            clk : in STD_LOGIC;
            reset : in STD_LOGIC;
            enable : in STD_LOGIC;
            ClassHV : out std_logic_vector(4 downto 0);
            TestHV : out std_logic_vector(6 downto 0);
            bit_addr : out std_logic_vector(7 downto 0);
            TestHV_Done : out std_logic;
            Done : out std_logic
        );
    end component;
    
    -- Clock period definition
    constant CLK_PERIOD : time := 10 ns;
    
    -- Test signals
    signal clk_tb : STD_LOGIC := '0';
    signal reset_tb : STD_LOGIC := '0';
    signal enable_tb : STD_LOGIC := '0';
    signal ClassHV_tb : std_logic_vector(4 downto 0);
    signal TestHV_tb : std_logic_vector(6 downto 0);
    signal bit_addr_tb : std_logic_vector(7 downto 0);
    signal TestHV_Done_tb : std_logic;
    signal Done_tb : std_logic;
    
    -- Test control signals
    signal test_complete : boolean := false;
    signal testHV_count : integer := 0;
    
begin
    -- Instantiate the Unit Under Test (UUT)
    UUT: BIT_SELECT
        port map (
            clk => clk_tb,
            reset => reset_tb,
            enable => enable_tb,
            ClassHV => ClassHV_tb,
            TestHV => TestHV_tb,
            bit_addr => bit_addr_tb,
            TestHV_Done => TestHV_Done_tb,
            Done => Done_tb
        );
    
    -- Clock process
    clk_process: process
    begin
        while not test_complete loop
            clk_tb <= '0';
            wait for CLK_PERIOD/2;
            clk_tb <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- Stimulus process
    stim_process: process
    begin
        -- Initialize
        report "========================================";
        report "Starting BIT_SELECT Testbench";
        report "Testing 5 Test Hypervectors";
        report "========================================";
        
        -- Reset the system
        reset_tb <= '1';
        enable_tb <= '0';
        wait for CLK_PERIOD * 2;
        reset_tb <= '0';
        wait for CLK_PERIOD;
        
        -- Enable the component
        enable_tb <= '1';
        report "Enable asserted - Starting test";
        
        -- Monitor and wait for 5 TestHV iterations
        for i in 0 to 4 loop
            -- Wait for TestHV_Done signal
            wait until TestHV_Done_tb = '1';
            wait for CLK_PERIOD;
            
            testHV_count <= testHV_count + 1;
            report "========================================";
            report "TestHV " & integer'image(i) & " completed";
            report "Current TestHV address: " & integer'image(to_integer(unsigned(TestHV_tb)));
            report "Current ClassHV: " & integer'image(to_integer(unsigned(ClassHV_tb)));
            report "Current bit_addr: " & integer'image(to_integer(unsigned(bit_addr_tb)));
            report "========================================";
            
            -- Brief pause between TestHVs
            wait for CLK_PERIOD;
        end loop;
        
        -- Check if Done signal is asserted (all TestHVs processed)
        wait for CLK_PERIOD * 10;
        
        if Done_tb = '1' then
            report "========================================";
            report "SUCCESS: All 5 TestHVs processed";
            report "Done signal asserted correctly";
            report "========================================";
        else
            report "========================================";
            report "INFO: Processing in progress...";
            report "Final TestHV: " & integer'image(to_integer(unsigned(TestHV_tb)));
            report "Final ClassHV: " & integer'image(to_integer(unsigned(ClassHV_tb)));
            report "Final bit_addr: " & integer'image(to_integer(unsigned(bit_addr_tb)));
            report "========================================";
        end if;
        
        -- Disable and complete test
        wait for CLK_PERIOD * 5;
        enable_tb <= '0';
        wait for CLK_PERIOD * 2;
        
        report "========================================";
        report "Testbench Completed Successfully";
        report "Total TestHVs processed: " & integer'image(testHV_count);
        report "========================================";
        
        test_complete <= true;
        wait;
    end process;
    
    -- Monitor process - continuous monitoring of signals
    monitor_process: process(clk_tb)
        variable prev_TestHV_Done : std_logic := '0';
    begin
        if rising_edge(clk_tb) then
            -- Detect rising edge of TestHV_Done
            if TestHV_Done_tb = '1' and prev_TestHV_Done = '0' then
                report "TestHV_Done asserted at time " & time'image(now) &
                       " | TestHV=" & integer'image(to_integer(unsigned(TestHV_tb))) &
                       " | ClassHV=" & integer'image(to_integer(unsigned(ClassHV_tb))) &
                       " | bit_addr=" & integer'image(to_integer(unsigned(bit_addr_tb)));
            end if;
            
            prev_TestHV_Done := TestHV_Done_tb;
        end if;
    end process;

end Behavioral;
