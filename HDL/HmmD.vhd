----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/05/2026 11:52:45 AM
-- Design Name: 
-- Module Name: HmmD - Behavioral
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

entity HmmD is
    generic(
        VECTOR_WIDTH : natural := 1024;
        SLICE_WIDTH  : natural := 32; -- Doit être une puissance de 2

        -- Precomputed widths (avoid log2c() in entity/component port decls)
        G_LOG2_VECTOR_WIDTH : natural := 10; -- = log2c(VECTOR_WIDTH)
        G_LOG2_SLICE_WIDTH  : natural := 5; -- = log2c(SLICE_WIDTH)
        Model_NUM           : natural := 7  -- Class number or action model number
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           acc_clear : in STD_LOGIC; -- one for all PE_acc_clear_input
           read_en : in STD_LOGIC; -- one for all PE_acc_enable_inputs
           QHV : in STD_LOGIC_VECTOR (SLICE_WIDTH-1 downto 0);
           MHV : in STD_LOGIC_VECTOR ((Model_NUM*SLICE_WIDTH)-1 downto 0);
           HamDist_outputs: out STD_LOGIC_VECTOR ((Model_NUM*G_LOG2_VECTOR_WIDTH)-1 downto 0);
           argMin         : out std_logic_vector(15 downto 0)
           );
end HmmD;

architecture Behavioral of HmmD is
component HD_PE is
    generic(
        VECTOR_WIDTH : natural := 1024;
        SLICE_WIDTH  : natural := 32; -- Doit être une puissance de 2

        -- Precomputed widths (avoid log2c() in entity/component port decls)
        G_LOG2_VECTOR_WIDTH : natural := 10; -- = log2c(VECTOR_WIDTH)
        G_LOG2_SLICE_WIDTH  : natural := 5 -- = log2c(SLICE_WIDTH)
    );
    port(
        clk                 : in  std_logic;
        rstn                : in  std_logic;
        PE_acc_clear_input  : in  std_logic;
        PE_acc_enable_input : in  std_logic;
        PE_slice_input_BHV  : in  std_logic_vector(SLICE_WIDTH - 1 downto 0);
        PE_slice_input_QHV  : in  std_logic_vector(SLICE_WIDTH - 1 downto 0);
        PE_HamDist_output   : out std_logic_vector(G_LOG2_VECTOR_WIDTH - 1 downto 0)
    );
end component;

component findMin is
    generic (
        NBR_CLASS_NEXT_POW2 : natural := 8;       --7 classes fit in 3 bit so next POW2 is 8
        NBR_CLASS_NEXT_POW2_CLOG2 : natural := 3; --7 classes fit in 3 bit so next POW2 is clog2(8)=3 
        NBR_CLASS_CLOG2 : natural := 3;           --7 classes fit in 3 bit so next POW2 is clog2(7)=3 
        ACC_WIDTH        : natural := 11          --bits of the accumulator
    );
    port (
        findmin_active_input  : in  std_logic_vector(NBR_CLASS_NEXT_POW2 - 1 downto 0);
        findmin_data_input    : in  std_logic_vector(NBR_CLASS_NEXT_POW2 * ACC_WIDTH - 1 downto 0);

        findmin_minIdx_output : out std_logic_vector(NBR_CLASS_CLOG2 - 1 downto 0)
    );
end component;

signal not_rst: std_logic:= '0';

signal ACC_en: std_logic:= '0';

signal PE_HamDist_output_t   : std_logic_vector(Model_NUM *G_LOG2_VECTOR_WIDTH - 1 downto 0) := (others => '0');


----------------------------------------------------------------
-- Utility functions
----------------------------------------------------------------
function clogb(value : natural) return natural is
    variable temp   : natural;
    variable result : natural := 0;
begin
    if value <= 1 then
        return 0;
    end if;

    temp := value - 1;

    while temp > 0 loop
        result := result + 1;
        temp   := temp / 2;
    end loop;

    return result;
end function;

function pow2next(value : natural) return natural is
    variable p : natural := 1;
begin
    while p < value loop
        p := p * 2;
    end loop;

    return p;
end function;


constant PADDED_MODEL_NUM : natural := pow2next(Model_NUM);
constant PADDED_MODEL_NUM_CLOG2 : natural := clogb(PADDED_MODEL_NUM);
-- Inputs to the padded findMin reduction tree.
signal findmin_active_t : std_logic_vector( PADDED_MODEL_NUM - 1 downto 0 );
signal findmin_data_t : std_logic_vector((PADDED_MODEL_NUM * G_LOG2_VECTOR_WIDTH) - 1 downto 0 );
signal findmin_minIdx_t : std_logic_vector(clogb(Model_NUM) - 1 downto 0);
constant ZERO_PAD : std_logic_vector(16 - clogb(Model_NUM) - 1 downto 0) := (others => '0');
begin

--process(clk)
--begin
--    if rising_edge(clk) then
--       -- ACC_en needs one cycle delay to have the combination circuit finish the job
--       ACC_en <= read_en;    
--    end if;
--end process;    

--generic map and port map here
gen_pe : for i in 0 to Model_NUM-1 generate  -- generate syntax [web:109]
  begin

    u_pe : HD_PE
      generic map (
        VECTOR_WIDTH         => VECTOR_WIDTH,
        SLICE_WIDTH          => SLICE_WIDTH,
        G_LOG2_VECTOR_WIDTH  => G_LOG2_VECTOR_WIDTH,
        G_LOG2_SLICE_WIDTH   => G_LOG2_SLICE_WIDTH
      )
      port map (
        clk                 => clk,
        rstn                => not_rst, 
        PE_acc_clear_input  => acc_clear,
        PE_acc_enable_input => read_en,--ACC_en,
        PE_slice_input_QHV  => QHV,  -- placeholder

        -- Slice i'th SLICE_WIDTH chunk from MHV
        PE_slice_input_BHV  => MHV( ((i+1)*SLICE_WIDTH) - 1 downto i*SLICE_WIDTH ),

        -- Place PE output into i'th G_LOG2_VECTOR_WIDTH chunk
        PE_HamDist_output   => PE_HamDist_output_t(((i+1)*G_LOG2_VECTOR_WIDTH) - 1 downto i*G_LOG2_VECTOR_WIDTH)
      );

  end generate gen_pe;
  
  
  gen_findmin_inputs : for i in 0 to PADDED_MODEL_NUM - 1 generate

        real_model : if i < Model_NUM generate
        begin

            findmin_active_t(i) <= '1';

            findmin_data_t(
                ((i + 1) * G_LOG2_VECTOR_WIDTH) - 1
                downto
                i * G_LOG2_VECTOR_WIDTH
            ) <= PE_HamDist_output_t(
                ((i + 1) * G_LOG2_VECTOR_WIDTH) - 1
                downto
                i * G_LOG2_VECTOR_WIDTH
            );

        end generate real_model;

        padded_model : if i >= Model_NUM generate
        begin

            findmin_active_t(i) <= '0';
            findmin_data_t( ((i + 1) * G_LOG2_VECTOR_WIDTH) - 1 downto i * G_LOG2_VECTOR_WIDTH ) <= (others => '0');

        end generate padded_model;

    end generate gen_findmin_inputs;

  
  uFindMin: findMin 
  generic map(
        NBR_CLASS_NEXT_POW2        => pow2next(Model_NUM),        --7 classes fit in 3 bit so next POW2 is 8
        NBR_CLASS_NEXT_POW2_CLOG2  => clogb(pow2next(Model_NUM)), --7 classes fit in 3 bit so next POW2 is clog2(8)=3 
        NBR_CLASS_CLOG2            => clogb(Model_NUM),           --7 classes fit in 3 bit so next POW2 is clog2(7)=3 
        ACC_WIDTH                  => G_LOG2_VECTOR_WIDTH         --bits of the accumulator
  )
  port map(
        findmin_active_input  => findmin_active_t,
        findmin_data_input    => findmin_data_t,
        findmin_minIdx_output => findmin_minIdx_t
  );
    not_rst <=not rst;
    HamDist_outputs <= PE_HamDist_output_t;
    argMin <= ZERO_PAD& findmin_minIdx_t;
end Behavioral;
