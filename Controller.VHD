library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity Controller is
    port(
        clk : in std_logic; -- Clock input
        reset : in std_logic; -- Reset input
        start : in std_logic; -- Start signal to begin processing
              
        RAM_EN : out std_logic; -- Enable signal for ClassHV RAM
               --Vect_Done : in std_logic; -- Input from ClassHV RAM indicating last bit read^^^^^^^^
        --using inference done from BIT_SELECT instead since it indicates the same thing

        inference_done : in std_logic; -- Signal indicating inference process is done from the BIT_SELECT module
        state_out : out string(1 to 5) -- Current state for debugging
    );
end Controller;
architecture Behavioral of Controller is

type state_type is (Sreset, Srun, Sdone);
signal state, next_state : state_type := Sreset;

begin

STATE_UPDATE: process (clk)

begin
    if rising_edge (clk) then--
        if (reset = '1') then
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
            RAM_EN <= '0';
            state_out <= "RESET";
                     
        when Srun =>
            RAM_EN <= '1';
            state_out <= "RUN  ";

        when Sdone =>
            RAM_EN <= '0';
            state_out <= "DONE ";
            
        when others =>
            RAM_EN <= '0';
            state_out <= "ERROR";
            
    end case;
end process;

NEXT_STATE_UPDATE: process (state, inference_done, start)
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
                next_state <= Sdone; -- 
            else
                next_state <= Srun; -- 
            end if;
        when Sdone =>-- 
            next_state <= Sdone;
        when others =>
            next_state <= Sreset; -
    end case;
end process;

end Behavioral;


