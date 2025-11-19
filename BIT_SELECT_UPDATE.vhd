--------------------------------------------------------------------------------
-- File: BIT_SELECT.vhd
-- Author: 
-- Date: November 11, 2025
-- Description: 
-- 
-- Revision History:
-- Date          Version     Description
-- 11/11/2025    1.0         Initial creation
-- 11/13/2025                Debugging 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- This component generates the class selection and bit address signals
-- for reading from the Class Hypervector RAM.
-- this is done by using a outerloop that iterates through the classes (0-25)
-- and an inner loop that iterates through the bits (0-1023) for each class

entity BIT_SELECT is
    port(
        clk : in STD_LOGIC; -- Clock input
        reset : in STD_LOGIC; -- Reset input
        enable : in STD_LOGIC; -- Enable signal to start the selection process FROM THE CONTROLER/STATE MACHINE SAME SIGNAL AS RAM_EN
        --this is controlled by the state when the FSM wants to start reading bits for ClassHV RAM and TestHV RAM
        ClassHV : out std_logic_vector(4 downto 0); -- class output (1-26)
        TestHV : out std_logic_vector(6 downto 0); -- Test Hypervector class address (0-127)>>>>>>>>>>>>>>>>>>>>>>
        bit_addr : out std_logic_vector(7 downto 0); -- Hex digit address (0-255)
        TestHV_Done : out std_logic; -- Signals when all classes and bits have been compared to a single TestHV
        Done : out std_logic -- when all TestHVs have been processed 
       
    );
end BIT_SELECT;

architecture Behavioral of BIT_SELECT is
    signal class_counter : integer range 0 to 25 := 0;
    signal bit_counter : integer range 0 to 255 := 0;
    signal testHV_counter : integer range 0 to 127 := 0;
    signal iteration_done : std_logic := '0'; -- Flag to indicate completion of all iterations
begin
    process(clk, reset)
    begin
        if reset = '1' then
            class_counter <= 0;--default to class 0
            bit_counter <= 0; --default to bit 0
            testHV_counter <= 0; --default to TestHV 0
            ClassHV <= ("11001"); --default output to class 25
            TestHV <= ("1111111"); --default output to TestHV 127>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            bit_addr <= (others => '0'); --default output to bit 0
            TestHV_Done <= '0'; -- Clear done signal
        elsif rising_edge(clk) then
            if enable = '1' then -- Only run when enabled
            --======================================================
                if (Class_counter = 0) and (TestHV_counter = 0) and (bit_counter = 255) then
                    -- Special case when the iteration has ended its cycle since every
                    -- testHV has been compared against every classHV and every hex digit
                    iteration_done <= '1'; -- Set iteration done flag**********************************
                else
                    iteration_done <= '0'; -- TestHV/ClassHV/bit_addr cycle not complete
                end if;
                if iteration_done = '0' then
                    if bit_counter < 255 then -- iterate through hex digits until 255
                    bit_counter <= bit_counter + 1; --increment bit counter
                    TestHV_Done <= '0'; -- Clear done during iteration
                    else --when bit counter reaches 255
                    bit_counter <= 0; --reset bit counter
                        if class_counter > 0 then--and if class counter less than 25
                        class_counter <= class_counter - 1; --decrement class counter************************** 
                        TestHV_Done <= '0'; -- Clear done, more classes to process
                        bit_counter <= 0; --reset bit counter for next class
                        else -- when class counter reaches 0 and bit counter reaches 255
                    -- this statement is for when the test hypervector has been compared against all class hypervectors
                        class_counter <= 25; -- wrap around to first class
                        TestHV_Done <= '1'; -- signal that all classes and bits have been output
                        --and the current inference cycle is complete for the current test HV
                        -- Next test HV can be loaded externally or counter incremented here
                        -- when the test HV has been infered to every class HV
                        testHV_counter <= testHV_counter - 1; --decrement test HV counter
                        -- the next TestHv is selected for array address and the process can iterate 
                        --through the next TestHV against all ClassHVs
                        bit_counter <= 0; --reset bit counter for next class
                        end if;

                    end if;
                end if;
            else
                TestHV_Done <= '0'; -- Clear done when not enabled
            end if;
            Done <= iteration_done; -- Output done signal
            ClassHV <= std_logic_vector(to_unsigned(class_counter, 5));
            -- Generate class from class counter for RAM access
            TestHV <= std_logic_vector(to_unsigned(testHV_counter, 7));
            -- Generate TestHV from testHV_counter for RAM access
            bit_addr <= std_logic_vector(to_unsigned(bit_counter, 8));
            -- Generate hex digit address from bit counter for RAM access
        end if;
    end process;
end Behavioral;



