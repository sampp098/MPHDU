----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/04/2025 11:17:04 PM
-- Design Name: 
-- Module Name: ROT_thread - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ROT_PE is
    generic(
            binary_cache_port2_data_size: integer := 32;
            ROT_amount_clog2:             integer := 3;
            ROT_amount_num  :             integer := 8 -- 2^ ROT_amount_clog2
    );
    port(   -- control
                clk             : in  std_logic;
                rst             : in  std_logic;
                in_valid        : in  std_logic;
                reload_carry_in : in  std_logic;
            -- data I/O
                rot_amount      : in  std_logic_vector(ROT_amount_clog2-1 downto 0);
                din             : in  STD_LOGIC_VECTOR (binary_cache_port2_data_size -1 downto 0);
                dout            : out std_logic_vector(binary_cache_port2_data_size-1 downto 0)
        );
end ROT_PE;

architecture Behavioral of ROT_PE is

component shift is
      generic(
        binary_cache_port2_data_size: integer := 32;
        ROT_amount_num  :             integer := 8; -- 2^ ROT_amount_clog2
        amount: integer := 1
      );
      Port (
        carry_in      : in  std_logic_vector(ROT_amount_num-1 downto 0);
        din           : in  std_logic_vector(binary_cache_port2_data_size-1 downto 0);
        dout          : out std_logic_vector(binary_cache_port2_data_size-1 downto 0);
        carry_out     : out std_logic_vector(ROT_amount_num-1 downto 0)
      );
end component;
constant shit_num : integer := ROT_amount_num;
signal carry_out_tmp: std_logic_vector(ROT_amount_num-1 downto 0) := (others => '0');
signal carry_in_tmp:  std_logic_vector(ROT_amount_num-1 downto 0) := (others => '0');
signal input_tmp:     std_logic_vector(binary_cache_port2_data_size-1 downto 0) := (others => '0');

type shift_out_list_t is array(shit_num-1 downto 0) of std_logic_vector(binary_cache_port2_data_size-1 downto 0);
type carry_out_list_t is array(shit_num-1 downto 0) of std_logic_vector(ROT_amount_num-1 downto 0);

signal shift_out_list : shift_out_list_t := (others =>(others => '0'));
signal carry_out_list : carry_out_list_t := (others =>(others => '0'));

signal carry_out : std_logic_vector(ROT_amount_num-1 downto 0);

begin
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                input_tmp <= (others=> '0');
                carry_in_tmp <= (others => '0');
            elsif in_valid = '1' then
                if reload_carry_in = '1' then
                    input_tmp <= din;
                    carry_in_tmp <= (others => '0');
                else
                    carry_in_tmp <= carry_out;
                    input_tmp <= din;
                end if;
            end if;
        end if;
    end process;

    
    shifter_list: for i in 0 to shit_num-1 generate
        u_shift: shift
        generic map(
                    binary_cache_port2_data_size => binary_cache_port2_data_size,
                    ROT_amount_num => ROT_amount_num,
                    amount => i+1
            )
        port map(   
                    carry_in => carry_in_tmp,
                    din      => input_tmp,
                    dout     =>shift_out_list(i),
                    carry_out=>carry_out_list(i)
                );
    
    end generate shifter_list;
    
    dout    <= shift_out_list(to_integer(unsigned(rot_amount)));
    carry_out <= carry_out_list(to_integer(unsigned(rot_amount)));
    
end Behavioral;