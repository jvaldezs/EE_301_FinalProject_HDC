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
        enable : in STD_LOGIC; -- Enable signal to start the selection process
        --this is controlled by the state when the FSM wants to start reading bits for ClassHV RAM and TestHV RAM
        ClassHV : out std_logic_vector(4 downto 0); -- class output (1-26)
        TestHV : out std_logic_vector(6 downto 0); -- Test Hypervector class address (0-125)
        bit_addr : out std_logic_vector(9 downto 0); -- Bit address (0-1023)
        Done : out std_logic -- Signals when all classes and bits have been output
       
    );
end BIT_SELECT;

architecture Behavioral of BIT_SELECT is
    signal class_counter : integer range 0 to 25 := 0;
    signal bit_counter : integer range 0 to 1023 := 0;
    signal testHV_counter : integer range 0 to 127 := 0;
begin
    process(clk, reset)
    begin
        if reset = '1' then
            class_counter <= 0;--default to class 0
            bit_counter <= 0; --default to bit 0
            testHV_counter <= 0; --default to TestHV 0
            ClassHV <= ("11001"); --default output to class 25>>>>>>>>>>>>>>>
            TestHV <= ("1111101"); --default output to TestHV 125>>>>>>>>>>>>>>>
            bit_addr <= (others => '0'); --default output to bit 0
            Done <= '0'; -- Clear done signal
        elsif rising_edge(clk) then
            if enable = '1' then -- Only run when enabled
            --======================================================
                if bit_counter < 1023 then -- iterate through bits until 1023
                    bit_counter <= bit_counter + 1; --increment bit counter>>>>>>>>>>>>>>
                    Done <= '0'; -- Clear done during iteration
                else --when bit counter reaches 1023
                    bit_counter <= 0; --reset bit counter
                    if class_counter > 0 then--and if class counter less than 25
                        class_counter <= class_counter - 1; --decrement class counter >>>>>>>>>>>>>>>>>>
                        Done <= '0'; -- Clear done, more classes to process
                        bit_counter <= 0; --reset bit counter for next class
                    else -- when class counter reaches 0 and bit counter reaches 1023
                    -- this statement is for when the test hypervector has been compared against all class hypervectors
                        class_counter <= 25; -- wrap around to first class
                        Done <= '1'; -- signal that all classes and bits have been output
                        --and the current inference cycle is complete for the current test HV
                        -- Next test HV can be loaded externally or counter incremented here
                        -- when the test HV has been infered to every class HV
                        testHV_counter <= testHV_counter - 1; --decrement test HV counter>>>>>>>>>>>>>
                        -- the next TestHv is selected for array address and the process can iterate 
                        --through the next TestHV against all ClassHVs
                        bit_counter <= 0; --reset bit counter for next class
                    end if;

                end if;
            else
                Done <= '0'; -- Clear done when not enabled
            end if;
            ClassHV <= std_logic_vector(to_unsigned(class_counter, 5));
            -- Generate class from class counter for RAM access
            TestHV <= std_logic_vector(to_unsigned(testHV_counter, 7));
            -- Generate TestHV from testHV_counter for RAM access
            bit_addr <= std_logic_vector(to_unsigned(bit_counter, 10));
            -- Generate bit address from bit counter for RAM access
        end if;
    end process;
end Behavioral;



