--------------------------------------------------------------------------------
-- File: Controller.VHD
-- Author: 
-- Date: November 11, 2025
-- Description: State machine controller for HDC inference system
--              Manages inference and training phases with state transitions
--              Controls RAM enable and training enable signals
-- 
-- Revision History:
-- Date          Version     Description
-- 11/11/2025    1.0         Initial creation
-- 12/11/2025    1.1         Added training state and Train_EN output
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Controller is
    port(
        clk : in std_logic; -- Clock input
        Master_reset : in std_logic; -- Reset input
        start : in std_logic; -- Start signal to begin processing
        class_array_corrected : in std_logic; --pulse signal when the class HV as been overwritten
        inference_done : in std_logic; -- Signal indicating inference process is done from the BIT_SELECT module

        RAM_EN : out std_logic; -- Enable signal for ClassHV RAM
        Train_EN: out std_logic ;        
        state_out : out string(1 to 5); -- Current state for debugging
        reset : out std_logic
    );
end Controller;
architecture Behavioral of Controller is

type state_type is (Sreset, Srun, Strain, Sdone);
signal state, next_state : state_type := Sreset;

begin

STATE_UPDATE: process (clk)

begin
    if rising_edge (clk) then--
        if (Master_reset = '1') then
            state <= Sreset;
        else
            state <= next_state;
        end if;
    end if;
end process;

OUTPUT_DECODE: process (state)
begin
    case (state) is
        when Sreset =>
            reset <= '1';
            RAM_EN <= '0';
            Train_EN <= '0';
            state_out <= "RESET";
                     
        when Srun =>
            reset <= '0';
            RAM_EN <= '1';
            Train_EN <= '0';         
            state_out <= "RUN  ";
        when Strain =>
            reset <= '0';
            RAM_EN <= '0'; 
            Train_EN <= '1';
            state_out <= "TRAIN";
        when Sdone =>
            reset <= '0';
            RAM_EN <= '0';
            state_out <= "DONE ";
            
        when others =>
            RAM_EN <= '0';
            state_out <= "ERROR";
            
    end case;
end process;

NEXT_STATE_UPDATE: process (state, inference_done, class_array_corrected, start)
begin
    case (state) is 
        when Sreset => -- 
            if(start = '1') then --
                next_state <= Srun; -- 
            else
                next_state <= Sreset; -- 
            end if;
        when Srun =>
            if (inference_done = '1') then -- 
                next_state <= STrain; -- 
            else
                next_state <= Srun; -- 
            end if;
        when Strain =>
            if (class_array_corrected = '1') then
                if inference_done = '1' then -- inference done should be low 
                     next_state <= Sreset;-- should we reset to clear registers or go back to run and just make a argument to reset the counters
                --for class and test
                end if;
            else
                next_state <= Strain;
            end if;
        when others =>
            next_state <= Sreset; --
    end case;
end process;

end Behavioral;


