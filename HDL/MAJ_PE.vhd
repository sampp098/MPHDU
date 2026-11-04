----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/22/2023 07:25:04 AM
-- Design Name: 
-- Module Name: ROT_PE - Behavioral
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

entity MAJ_PE is
    generic(
            binary_cache_port2_data_size: integer := 32;
            int_size: integer := 2
    );
    port(   -- control
                clk           : in  std_logic;
                rst           : in  std_logic;
                in_valid      : in  std_logic;
                load_T        : in  std_logic;
            -- data I/O
                T             : in  std_logic_vector(int_size-1 downto 0);
                din           : in  std_logic_vector((binary_cache_port2_data_size * int_size) - 1 downto 0); --int_vector
                dout          : out std_logic_vector(binary_cache_port2_data_size-1 downto 0)
    );
end MAJ_PE;

architecture Behavioral of MAJ_PE is

component MAJ_1bit is
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
end component;

signal T_dff :  std_logic_vector(int_size-1 downto 0) := (others => '0');
begin
   
   process(clk)
   begin
        if rising_edge(clk) then
            if (rst = '1') then
                T_dff <= (others => '0');
            elsif load_T = '1' then
                T_dff <= T;
            end if;
        end if;
   end process;
   
   maj_1bit_vector: for i in 0 to binary_cache_port2_data_size-1 generate
        uMAJ_1bit: MAJ_1bit
            generic map(
                int_size => int_size
            )
            port map( 
                      clk      => clk,
                      rst      => rst,
                      in_valid => in_valid,
                      T        => T_dff,
                      din      => din(((i+1)*int_size)-1 downto i*int_size), --input(i)
                      dout     => dout(i)
                     );
    end generate maj_1bit_vector;


end Behavioral;
