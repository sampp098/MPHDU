----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/27/2025 09:27:47 AM
-- Design Name: 
-- Module Name: LFSR - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LFSR is
    port (
        clk   : in  std_logic;
        state : out std_logic_vector(47 downto 0)
    );
end entity LFSR;

architecture rtl of LFSR is

    -- Non-zero initial seed (same as your C++ example)
    signal lfsr_reg : std_logic_vector(47 downto 0) :=
        x"159A55E5AED3";

begin

    process(clk)
        variable feedback : std_logic;
    begin
        if rising_edge(clk) then
            -- XOR taps: bit 47, 4, 3, 2
            feedback := lfsr_reg(47) xor
                        lfsr_reg(4)  xor
                        lfsr_reg(3)  xor
                        lfsr_reg(2);

            -- Shift left and insert feedback into bit 0
            lfsr_reg <= lfsr_reg(46 downto 0) & feedback;
        end if;
    end process;

    state <= lfsr_reg;

end architecture rtl;
