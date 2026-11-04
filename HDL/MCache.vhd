----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/20/2026 06:44:41 PM
-- Design Name: 
-- Module Name: AXI_Access - Behavioral
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
----------------------------------------------------------------------------------
-- MCache
-- Port1: 128-bit linear read/write access, typically from AXI/DDR refill path
-- Port2: reads one segment (e.g. 32-bit) for all classes in parallel
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MCache is
    generic (
        G_PORT1_DATA_WIDTH      : integer := 128;
        G_PORT1_Depth           : integer := 56;
        G_PORT1_Depth_Clog2     : integer := 6;

        G_Segment_size          : integer := 32;
        G_Segment_NUM           : integer := 32;
        G_NUM_Classes           : integer := 7;
        G_Dimentsion            : integer := 1024;
        G_Segments_ADDR_WIDTH   : integer := 5;
        G_LOG2_accumulator_WIDTH: natural := 10
    );
    port (
        clk            : in  std_logic;
        rst            : in  std_logic;

        port1_in_Data  : in  std_logic_vector(G_PORT1_DATA_WIDTH-1 downto 0);
        port1_Addr     : in  std_logic_vector(G_PORT1_Depth_Clog2-1 downto 0);
        port1_wr_en    : in  std_logic;
        port1_rd_en    : in  std_logic;
        port1_out_Data : out STD_LOGIC_VECTOR((G_NUM_Classes*16)-1 downto 0);

        port2_out_Data     : out std_logic_vector((G_NUM_Classes*G_Segment_size)-1 downto 0);
        port2_Addr         : in  std_logic_vector(G_Segments_ADDR_WIDTH-1 downto 0);
        port2_wr_en        : in  std_logic;
        port2_rd_en        : in  std_logic;
        port2_UPDATE_Data  : in std_logic_vector(G_Segment_size-1 downto 0);
        port2_UPDATE_Addr  : in std_logic_vector(15 downto 0);
        HamDist_inputs  : in  STD_LOGIC_VECTOR((G_NUM_Classes*G_LOG2_accumulator_WIDTH)-1 downto 0)
        
    );
end MCache;

architecture Behavioral of MCache is

    constant C_NUM_WORDS_PER_CLASS    : integer := G_Dimentsion / G_PORT1_DATA_WIDTH;
    constant C_SEGMENTS_PER_WORD      : integer := G_PORT1_DATA_WIDTH / G_Segment_size;
    constant C_SEG_SEL_BITS           : integer := 2; -- valid for 128/32 = 4 segments/word
    constant C_WORD_IDX_WIDTH         : integer := G_Segments_ADDR_WIDTH - C_SEG_SEL_BITS;

    subtype word_t is std_logic_vector(G_PORT1_DATA_WIDTH-1 downto 0);
    type class_mem_t is array (0 to C_NUM_WORDS_PER_CLASS-1) of word_t;
    type full_mem_t  is array (0 to G_NUM_Classes-1) of class_mem_t;

    signal MHV            : full_mem_t := (others => (others => (others => '0')));
    signal port1_out_reg  : std_logic_vector(G_PORT1_DATA_WIDTH-1 downto 0) := (others => '0');
    signal port2_out_reg  : std_logic_vector((G_NUM_Classes*G_Segment_size)-1 downto 0) := (others => '0');

begin

    assert (G_Dimentsion mod G_PORT1_DATA_WIDTH = 0)
        report "G_Dimentsion must be divisible by G_PORT1_DATA_WIDTH"
        severity failure;

    assert (G_PORT1_DATA_WIDTH mod G_Segment_size = 0)
        report "G_PORT1_DATA_WIDTH must be divisible by G_Segment_size"
        severity failure;

    assert (C_SEGMENTS_PER_WORD = 4)
        report "This implementation assumes 4 segments per word, e.g. 128/32 = 4"
        severity warning;

    assert (G_PORT1_Depth = G_NUM_Classes * C_NUM_WORDS_PER_CLASS)
        report "G_PORT1_Depth must equal G_NUM_Classes * (G_Dimentsion / G_PORT1_DATA_WIDTH)"
        severity failure;

    process(clk)
--        variable v_p1_addr      : integer;
--        variable v_class_idx    : integer;
--        variable v_word_idx     : integer;

--        variable v_seg_addr     : integer;
--        variable v_seg_word_idx : integer;
--        variable v_seg_idx      : integer;
--        variable v_lsb          : integer;
--        variable v_msb          : integer;
        
        variable v_p1_addr      : integer;
        variable v_class_idx    : integer;
        variable v_word_idx     : integer;
        
        variable v_seg_word_idx : integer;
        variable v_seg_idx      : integer;
        variable v_lsb          : integer; 
        variable v_msb          : integer;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                port1_out_reg <= (others => '0');
                port2_out_reg <= (others => '0');

            else
                ------------------------------------------------------------------
                -- PORT1: linear 128-bit access
                -- Linear map:
                --   class_idx = addr / words_per_class
                --   word_idx  = addr mod words_per_class
                ------------------------------------------------------------------
                if port1_wr_en = '1' then
                    v_p1_addr := to_integer(unsigned(port1_Addr));
                    
--                    if v_p1_addr < G_PORT1_Depth then
--                        v_class_idx := v_p1_addr / C_NUM_WORDS_PER_CLASS;
--                        v_word_idx  := v_p1_addr mod C_NUM_WORDS_PER_CLASS;

--                        MHV(v_class_idx)(v_word_idx) <= port1_in_Data;
--                    end if;

                    if v_p1_addr < G_PORT1_Depth then
                    
                        v_class_idx :=
                            to_integer(unsigned(port1_Addr(G_PORT1_Depth_Clog2-1 downto 3)));
                    
                        v_word_idx :=
                            to_integer(unsigned(port1_Addr(2 downto 0)));
                    
                        MHV(v_class_idx)(v_word_idx) <= port1_in_Data;
                    
                    end if;

                end if;

                if port1_rd_en = '1' then
                    v_p1_addr := to_integer(unsigned(port1_Addr));
                    
                    if v_p1_addr < G_PORT1_Depth then
                        v_class_idx :=
                            to_integer(unsigned(port1_Addr(G_PORT1_Depth_Clog2-1 downto 3)));
                    
                        v_word_idx :=
                            to_integer(unsigned(port1_Addr(2 downto 0)));

                        port1_out_reg <= MHV(v_class_idx)(v_word_idx);
                    else
                    
--                    if v_p1_addr < G_PORT1_Depth then
--                        v_class_idx := v_p1_addr / C_NUM_WORDS_PER_CLASS;
--                        v_word_idx  := v_p1_addr mod C_NUM_WORDS_PER_CLASS;

--                        port1_out_reg <= MHV(v_class_idx)(v_word_idx);
--                    else
                        port1_out_reg <= (others => '0');
                    end if;
                end if;

                ------------------------------------------------------------------
                -- PORT2: segment read for all classes
                -- port2_Addr for 1024/32 = 32 segments:
                --   [4:2] => word index  (0..7)
                --   [1:0] => segment idx (0..3) within 128-bit word
                ------------------------------------------------------------------
--                if port2_rd_en = '1' then
--                    v_seg_addr     := to_integer(unsigned(port2_Addr));
--                    v_seg_word_idx := v_seg_addr / C_SEGMENTS_PER_WORD;
--                    v_seg_idx      := v_seg_addr mod C_SEGMENTS_PER_WORD;

--                    v_lsb := v_seg_idx * G_Segment_size;
--                    v_msb := v_lsb + G_Segment_size - 1;

--                    if v_seg_word_idx < C_NUM_WORDS_PER_CLASS then
--                        for i in 0 to G_NUM_Classes-1 loop
--                            port2_out_reg(((i+1)*G_Segment_size)-1 downto i*G_Segment_size) <=
--                                MHV(i)(v_seg_word_idx)(v_msb downto v_lsb);
--                        end loop;
--                    else
--                        port2_out_reg <= (others => '0');
--                    end if;
--                end if;
--                ------------------------------------------------------------------
                -- PORT2: segment read for all classes
                -- port2_Addr(4 downto 2) -> 128-bit word index
                -- port2_Addr(1 downto 0) -> 32-bit segment index
                ------------------------------------------------------------------
                if port2_rd_en = '1' then
                
                    v_seg_word_idx :=
                        to_integer(unsigned(
                            port2_Addr(G_Segments_ADDR_WIDTH-1 downto C_SEG_SEL_BITS)
                        ));
                
                    v_seg_idx :=
                        to_integer(unsigned(
                            port2_Addr(C_SEG_SEL_BITS-1 downto 0)
                        ));
                
                    v_lsb := v_seg_idx * G_Segment_size;
                    v_msb := v_lsb + G_Segment_size - 1;
                
                    if v_seg_word_idx < C_NUM_WORDS_PER_CLASS then
                        for i in 0 to G_NUM_Classes-1 loop
                            port2_out_reg(
                                ((i+1)*G_Segment_size)-1 downto i*G_Segment_size
                            ) <=
                                MHV(i)(v_seg_word_idx)(v_msb downto v_lsb);
                        end loop;
                    else
                        port2_out_reg <= (others => '0');
                    end if;
                
                end if;
                ------------------------------------------------------------------
                -- PORT2: single-segment update
                --
                -- port2_Addr        : segment address, 0..31
                -- port2_UPDATE_Addr : class address,   0..6
                -- port2_UPDATE_Data : new 32-bit segment
                ------------------------------------------------------------------
--                if port2_wr_en = '1' then
                
--                    v_seg_addr := to_integer(unsigned(port2_Addr));
                
--                    if v_seg_addr < G_Segment_NUM then
                
--                        v_seg_word_idx := v_seg_addr / C_SEGMENTS_PER_WORD;
--                        v_seg_idx      := v_seg_addr mod C_SEGMENTS_PER_WORD;
                
--                        v_lsb := v_seg_idx * G_Segment_size;
--                        v_msb := v_lsb + G_Segment_size - 1;
                
--                        v_class_idx := to_integer(unsigned(port2_UPDATE_Addr));
                
--                        if v_class_idx < G_NUM_Classes then
--                            MHV(v_class_idx)(v_seg_word_idx)(v_msb downto v_lsb)
--                                <= port2_UPDATE_Data;
--                        end if;
                
--                    end if;
                
--                end if;
                ------------------------------------------------------------------
                -- PORT2: single-segment update
                ------------------------------------------------------------------
                if port2_wr_en = '1' then
                
                    v_seg_word_idx :=
                        to_integer(unsigned(
                            port2_Addr(G_Segments_ADDR_WIDTH-1 downto C_SEG_SEL_BITS)
                        ));
                
                    v_seg_idx :=
                        to_integer(unsigned(
                            port2_Addr(C_SEG_SEL_BITS-1 downto 0)
                        ));
                
                    v_lsb := v_seg_idx * G_Segment_size;
                    v_msb := v_lsb + G_Segment_size - 1;
                
                    v_class_idx := to_integer(unsigned(port2_UPDATE_Addr));
                
                    if (v_seg_word_idx < C_NUM_WORDS_PER_CLASS) and
                       (v_class_idx < G_NUM_Classes) then
                
                        MHV(v_class_idx)(v_seg_word_idx)(v_msb downto v_lsb)
                            <= port2_UPDATE_Data;
                
                    end if;
                
                end if;

            end if;
        end if;
    end process;

    --port1_out_Data <= port1_out_reg;
    port2_out_Data <= port2_out_reg;
    
    gen_zero_extend : for i in 0 to G_NUM_Classes-1 generate
    begin
        port1_out_Data((i+1)*16-1 downto i*16) <=
            (16-G_LOG2_accumulator_WIDTH-1 downto 0 => '0') &
            HamDist_inputs((i+1)*G_LOG2_accumulator_WIDTH-1 downto i*G_LOG2_accumulator_WIDTH);
    end generate; 

end Behavioral;
