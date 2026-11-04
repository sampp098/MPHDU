-- BRAM-oriented MCache, same entity and I/O interface as original.
-- Important: see accompanying notes for cross-port read/write collision limitation.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MCache_BRAM is
    generic (
        G_PORT1_DATA_WIDTH       : integer := 128;
        G_PORT1_Depth            : integer := 56;
        G_PORT1_Depth_Clog2      : integer := 6;
        G_Segment_size           : integer := 32;
        G_Segment_NUM            : integer := 32;
        G_NUM_Classes            : integer := 7;
        G_Dimentsion             : integer := 1024;
        G_Segments_ADDR_WIDTH    : integer := 5;
        G_LOG2_accumulator_WIDTH : natural := 10
    );
    port (
        clk               : in  std_logic;
        rst               : in  std_logic;
        port1_in_Data     : in  std_logic_vector(G_PORT1_DATA_WIDTH-1 downto 0);
        port1_Addr        : in  std_logic_vector(G_PORT1_Depth_Clog2-1 downto 0);
        port1_wr_en       : in  std_logic;
        port1_rd_en       : in  std_logic;
        port1_out_Data    : out std_logic_vector(G_NUM_Classes*16-1 downto 0);
        port2_out_Data    : out std_logic_vector(G_NUM_Classes*G_Segment_size-1 downto 0);
        port2_Addr        : in  std_logic_vector(G_Segments_ADDR_WIDTH-1 downto 0);
        port2_wr_en       : in  std_logic;
        port2_rd_en       : in  std_logic;
        port2_UPDATE_Data : in  std_logic_vector(G_Segment_size-1 downto 0);
        port2_UPDATE_Addr : in  std_logic_vector(15 downto 0);
        HamDist_inputs    : in  std_logic_vector(G_NUM_Classes*G_LOG2_accumulator_WIDTH-1 downto 0)
    );
end MCache_BRAM;

architecture Behavioral of MCache_BRAM is
    constant C_NUM_WORDS_PER_CLASS : integer := G_Dimentsion/G_PORT1_DATA_WIDTH;
    constant C_BANKS               : integer := G_PORT1_DATA_WIDTH/G_Segment_size;
    -- This implementation matches the original optimized bit slicing (128/32).
    constant C_BANK_SEL_BITS       : integer := 2;
    constant C_WORD_BITS           : integer := G_Segments_ADDR_WIDTH-C_BANK_SEL_BITS;

    type bank_output_array_t is array (0 to G_NUM_Classes*C_BANKS-1)
        of std_logic_vector(G_Segment_size-1 downto 0);
    signal bank_q : bank_output_array_t := (others => (others => '0'));
    signal seg_select_q : std_logic_vector(C_BANK_SEL_BITS-1 downto 0) := (others => '0');

    signal p1_word  : integer range 0 to C_NUM_WORDS_PER_CLASS-1;
    signal p1_class : integer range 0 to G_NUM_Classes-1;
    signal p1_valid : std_logic;
    signal p2_word  : integer range 0 to C_NUM_WORDS_PER_CLASS-1;
    signal p2_class : integer range 0 to G_NUM_Classes-1;
    signal p2_valid : std_logic;
    signal p2_bank  : integer range 0 to C_BANKS-1;
begin
    assert G_PORT1_DATA_WIDTH=128 and G_Segment_size=32 and C_BANKS=4
        report "MCache_BRAM requires 128-bit Port1 and 32-bit segments" severity failure;
    assert G_Dimentsion=1024 and G_Segments_ADDR_WIDTH=5
        report "MCache_BRAM supports the supplied 1024-bit, 32-segment configuration" severity failure;
    assert G_PORT1_Depth=G_NUM_Classes*C_NUM_WORDS_PER_CLASS
        report "Port1 depth mismatch" severity failure;
    assert G_PORT1_Depth_Clog2=6
        report "This bank implementation requires six Port1 address bits" severity failure;
    assert G_LOG2_accumulator_WIDTH <= 16 and G_LOG2_accumulator_WIDTH > 0
        report "Invalid accumulator width" severity failure;

    p1_valid <= '1' when unsigned(port1_Addr) < to_unsigned(G_PORT1_Depth, G_PORT1_Depth_Clog2) else '0';
    p1_class <= to_integer(unsigned(port1_Addr(5 downto 3))) when p1_valid='1' else 0;
    p1_word  <= to_integer(unsigned(port1_Addr(2 downto 0)));
    p2_word  <= to_integer(unsigned(port2_Addr(4 downto 2)));
    p2_bank  <= to_integer(unsigned(port2_Addr(1 downto 0)));
    p2_valid <= '1' when unsigned(port2_UPDATE_Addr) < to_unsigned(G_NUM_Classes,16) else '0';
    p2_class <= to_integer(unsigned(port2_UPDATE_Addr)) when p2_valid='1' else 0;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst='1' then
                seg_select_q <= (others=>'0');
            elsif port2_rd_en='1' then
                seg_select_q <= port2_Addr(1 downto 0);
            end if;
        end if;
    end process;

    class_gen : for cls in 0 to G_NUM_Classes-1 generate
        bank_gen : for bank in 0 to C_BANKS-1 generate
            type ram_t is array (0 to C_NUM_WORDS_PER_CLASS-1)
                of std_logic_vector(G_Segment_size-1 downto 0);
            signal ram : ram_t := (others => (others=>'0'));
            attribute ram_style : string;
            attribute ram_style of ram : signal is "block";
            signal we_a, we_b : std_logic;
        begin
            -- Writes to distinct addresses are permitted in the same bank.
            -- When the same segment is written twice, Port2 has priority.
            we_b <= '1' when rst='0' and port2_wr_en='1' and
                       p2_valid='1' and p2_class=cls and p2_bank=bank else '0';
            we_a <= '1' when rst='0' and port1_wr_en='1' and
                       p1_valid='1' and p1_class=cls and
                       not (we_b='1' and p1_word=p2_word) else '0';

            -- RAM port A: refill write. Port1 read output is not externally used.
            process(clk)
            begin
                if rising_edge(clk) then
                    if we_a='1' then
                        ram(p1_word) <= port1_in_Data((bank+1)*G_Segment_size-1 downto bank*G_Segment_size);
                    end if;
                end if;
            end process;

            -- RAM port B: old-data synchronous read and selected-segment write.
            -- Output reset affects only the output register, not RAM contents.
            process(clk)
            begin
                if rising_edge(clk) then
                    if rst='1' then
                        bank_q(cls*C_BANKS+bank) <= (others=>'0');
                    else
                        if port2_rd_en='1' then
                            bank_q(cls*C_BANKS+bank) <= ram(p2_word);
                        end if;
                        if we_b='1' then
                            ram(p2_word) <= port2_UPDATE_Data;
                        end if;
                    end if;
                end if;
            end process;
        end generate;

        port2_out_Data((cls+1)*G_Segment_size-1 downto cls*G_Segment_size) <=
            bank_q(cls*C_BANKS + to_integer(unsigned(seg_select_q)));

        port1_out_Data((cls+1)*16-1 downto cls*16) <=
            (15 downto G_LOG2_accumulator_WIDTH => '0') &
            HamDist_inputs((cls+1)*G_LOG2_accumulator_WIDTH-1 downto cls*G_LOG2_accumulator_WIDTH);
    end generate;
end Behavioral;
