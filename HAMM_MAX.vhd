--------------------------------------------------------------------------------
-- File: HAMM_MAX.vhd
-- Author: 
-- Date: November 11, 2025
-- Description: 
-- 
-- Revision History:
-- Date          Version     Description
-- 11/11/2025    1.0         Initial creation
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- This component compares current hamming distance caluclated with
-- The previous maximum hamming distance stored. If the current distance
-- is greater than the stored maximum, it updates the maximum value.
--When ever there is a new Maximum value, This component sends a signal to the controller
-- So the controller can signal the guess module to update its output so that
--the guess in process is reflected bu giving the guess the value
-- The value of the current Class HV being tested. 
--since that is the new best guess so far.
entity Hamm_MAX is
    port
    (
    clk         : in  STD_LOGIC; -- Clock input
    reset       : in  STD_LOGIC; -- Reset input to clear accumulator
    Load        : in  STD_LOGIC; -- Load signal from control same as RAM_EN
    TestHV_Done : in  STD_LOGIC; -- Signal to clear max when starting new TestHV
    --===========Load signal should be active when we want to compare
    --===========the current hamming distance with the stored maximum
    --=========== but only when the hamming_accumulator module is done calculating
    data_in     : in  STD_LOGIC_VECTOR(10 downto 0);-- Input data from HAMM module
    sum_out     : out STD_LOGIC_VECTOR(10 downto 0);  -- Max count is 1024, needs 11 bits
    new_max     : out STD_LOGIC -- Signal to controller indicating a new max found


);
end Hamm_MAX;

architecture Behavioral of Hamm_MAX is
    signal Current_Max : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
    signal prev_TestHV_Done : std_logic := '0';
begin
    process(clk, reset)
    begin
        if(rising_edge(clk)) then
            if(reset = '1') then
                Current_Max <= (others => '0'); -- Clear on reset
                sum_out <= (others => '0'); -- Reset output to 0 for first comparison
                new_max <= '0';
                prev_TestHV_Done <= '0';
            else
                prev_TestHV_Done <= TestHV_Done;
                
                -- Clear max one cycle AFTER TestHV_Done goes high (on falling edge)
                -- this is so the best guess for the testHV doesnt roll over to the next inference iteration
                if prev_TestHV_Done = '1' and TestHV_Done = '0' then
                    Current_Max <= (others => '0'); -- Reset for next TestHV
                    sum_out <= (others => '0');
                    new_max <= '0';
                elsif(Load = '1') then -- Load signal active from controller
                    if(unsigned(data_in) > unsigned(Current_Max)) then --if new max found
                        new_max <= '1'; -- Signal to controller that a new max is found
                        --this is a pulse signal that updates the guess module
                        --to the current class as the current best guess
                        Current_Max <= data_in; -- Update max if new data is greater
                    else
                        new_max <= '0'; -- No new max found
                    end if;
                end if;
                sum_out <= Current_Max; -- Always output the current max
            end if;
        end if;
    end process;
end Behavioral;
--Current_Max is used to store the maximum value encountered so far.
--this value is updated only when the Load signal is active and

--the new input data exceeds the current maximum.
