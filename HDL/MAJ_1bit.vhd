----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/13/2023 09:47:35 PM
-- Design Name: 
-- Module Name: MAJ_1bit - Behavioral
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
library xil_defaultlib;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MAJ_1bit is
    generic(
            int_size: integer := 32
    );
    port(   clk           : in  std_logic;
            rst           : in  std_logic;
            in_valid      : in  std_logic;
            T             : in  std_logic_vector(int_size-1 downto 0);
            din           : in  std_logic_vector(int_size-1 downto 0);
            dout          : out std_logic
        );
end MAJ_1bit;

architecture Behavioral of MAJ_1bit is
signal data: std_logic_vector(int_size-1 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                dout <= '0';
            elsif in_valid = '1' and din >= T  then
                dout <= '1';
            elsif in_valid = '1' and din < T  then
                dout <= '0';
            end if;
        end if;
    end process;

end Behavioral;
