----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/04/2025 11:17:04 PM
-- Design Name: 
-- Module Name: XOR_PE - Behavioral
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

entity XOR_PE is
    generic(
            binary_cache_port2_data_size: integer := 32
    );
    port(   -- control
                clk             : in  std_logic;
                rst             : in  std_logic;
                in_valid        : in  std_logic;
                load_A_nB       : in  std_logic;
                rstB            : in  std_logic;
            -- data I/O
                din             : in  STD_LOGIC_VECTOR (binary_cache_port2_data_size -1 downto 0);
                dout            : out std_logic_vector(binary_cache_port2_data_size-1 downto 0)
        );
end XOR_PE;

architecture Behavioral of XOR_PE is
    signal A,B:     std_logic_vector(binary_cache_port2_data_size-1 downto 0) := (others => '0');
    signal temp:    std_logic_vector(binary_cache_port2_data_size-1 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                A <= (others=> '0');
                B <= (others=> '0');
            elsif in_valid = '1' then
                if load_A_nB = '1' and rstB='0' then
                    A <= din;
                    B <= temp;
                elsif load_A_nB = '0' and rstB='0' then
                    B <= din;
                elsif rstB='1' then -- I found that at this moment we need to reset also A
                    A <= (others=> '0');
                    B <= (others=> '0');
                end if;
            end if;
        end if;
    end process;
                  
    xor_vector: for i in 0 to binary_cache_port2_data_size-1 generate
        temp(i) <= A(i) xor B(i);
    end generate xor_vector;
    dout <= temp;
end Behavioral;
