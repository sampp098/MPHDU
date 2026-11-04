library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity int_ram is
    generic (
        G_AXI_Data_size : integer := 128;
        N_Elements      : integer := 32;
        RAM_DATA_SIZE   : integer := 2;
        RAM_DEPTH       : integer := 4;
        RAM_DEPTH_CLOG2 : integer := 2;
        RAM_SEL_WIDTH   : integer := 5
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;

        -- Port 1: wide access (2 rows packed into 1 AXI beat)
        --addr1   : in  std_logic_vector((RAM_DEPTH_CLOG2-2)-1 downto 0);
        addr1   : in  std_logic_vector((RAM_DEPTH_CLOG2-1)-1 downto 0); --when depth is less than 8
        ram_sel : in  std_logic_vector(RAM_SEL_WIDTH-1 downto 0);
        wr_en1  : in  std_logic;
        rd_en1  : in  std_logic;
        din1    : in  std_logic_vector(G_AXI_Data_size-1 downto 0);
        dout1   : out std_logic_vector(G_AXI_Data_size-1 downto 0);

        -- Port 2: full-row vector access
        addr2   : in  std_logic_vector(RAM_DEPTH_CLOG2-1 downto 0);
        wr_en2  : in  std_logic;
        rd_en2  : in  std_logic;
        din2    : in  std_logic_vector(N_Elements*RAM_DATA_SIZE-1 downto 0);
        dout2   : out std_logic_vector(N_Elements*RAM_DATA_SIZE-1 downto 0)
    );
end int_ram;

architecture Behavioral of int_ram is

    component RAM is
        generic (
            ram_data_size    : integer := 32;
            ram_depth        : integer := 128;
            ram_depth_clogb2 : integer := 7
        );
        port (
            clk   : in  std_logic;
            rst   : in  std_logic;
            addr  : in  std_logic_vector(ram_depth_clogb2-1 downto 0);
            wr_en : in  std_logic;
            rd_en : in  std_logic;
            din   : in  std_logic_vector(ram_data_size-1 downto 0);
            dout  : out std_logic_vector(ram_data_size-1 downto 0)
        );
    end component;

    type ram_dout_array is array (0 to N_Elements-1) of std_logic_vector(RAM_DATA_SIZE-1 downto 0);
    type ram_din_array  is array (0 to N_Elements-1) of std_logic_vector(RAM_DATA_SIZE-1 downto 0);

    signal ram_dout : ram_dout_array;

    signal ram_addr_i  : std_logic_vector(RAM_DEPTH_CLOG2-1 downto 0);
    signal ram_wr_en_i : std_logic_vector(N_Elements-1 downto 0);
    signal ram_rd_en_i : std_logic_vector(N_Elements-1 downto 0);
    signal ram_din_i   : ram_din_array;

    signal p1_ram_addr  : std_logic_vector(RAM_DEPTH_CLOG2-1 downto 0);
    signal p1_ram_wr_en : std_logic_vector(N_Elements-1 downto 0);
    signal p1_ram_rd_en : std_logic_vector(N_Elements-1 downto 0);
    signal p1_ram_din   : ram_din_array;

    constant ROW_WIDTH  : integer := N_Elements * RAM_DATA_SIZE;
    constant PORT1_ROWS : integer := G_AXI_Data_size / ROW_WIDTH;

    type t_state is (S_IDLE, S_P1_RD_0, S_P1_RD_1, S_P1_WR_0, S_P1_WR_1);
    signal state : t_state := S_IDLE;

    signal addr1_lat  : std_logic_vector(addr1'range) := (others => '0');
    signal din1_lat   : std_logic_vector(G_AXI_Data_size-1 downto 0) := (others => '0');
    signal dout1_reg  : std_logic_vector(G_AXI_Data_size-1 downto 0) := (others => '0');
    signal p1_busy    : std_logic;

begin

    assert (RAM_DATA_SIZE = 2) or (RAM_DATA_SIZE = 4) or (RAM_DATA_SIZE = 8) or
           (RAM_DATA_SIZE = 16) or (RAM_DATA_SIZE = 32)
        report "RAM_DATA_SIZE must be one of: 2,4,8,16,32"
        severity failure;

    assert (G_AXI_Data_size = PORT1_ROWS * ROW_WIDTH)
        report "G_AXI_Data_size must be an integer multiple of row width"
        severity failure;

    p1_busy <= '1' when state /= S_IDLE else '0';

    gen_RAMs: for i in 0 to N_Elements-1 generate
    begin
        RAM_inst: RAM
            generic map (
                ram_data_size    => RAM_DATA_SIZE,
                ram_depth        => RAM_DEPTH,
                ram_depth_clogb2 => RAM_DEPTH_CLOG2
            )
            port map (
                clk   => clk,
                rst   => rst,
                addr  => ram_addr_i,
                wr_en => ram_wr_en_i(i),
                rd_en => ram_rd_en_i(i),
                din   => ram_din_i(i),
                dout  => ram_dout(i)
            );
    end generate;

    -- Direct combinational mux:
    -- Port2 owns RAM when port1 is idle and not starting a new transaction.
    process(state, rd_en1, wr_en1, addr2, wr_en2, rd_en2, din2,
        p1_ram_addr, p1_ram_wr_en, p1_ram_rd_en, p1_ram_din)
    begin
        ram_addr_i  <= addr2;
        ram_wr_en_i <= (others => '0');
        ram_rd_en_i <= (others => '0');

        for i in 0 to N_Elements-1 loop
            ram_din_i(i) <= din2((i+1)*RAM_DATA_SIZE-1 downto i*RAM_DATA_SIZE);
        end loop;

        if wr_en2 = '1' then
            ram_wr_en_i <= (others => '1');
        end if;

        if rd_en2 = '1' then
            ram_rd_en_i <= (others => '1');
        end if;

        if (state /= S_IDLE) or (rd_en1 = '1') or (wr_en1 = '1') then
            ram_addr_i  <= p1_ram_addr;
            ram_wr_en_i <= p1_ram_wr_en;
            ram_rd_en_i <= p1_ram_rd_en;
            for i in 0 to N_Elements-1 loop
                ram_din_i(i) <= p1_ram_din(i);
            end loop;
        end if;
    end process;

    -- Port1 FSM only
    process(clk)
        variable row0 : unsigned(RAM_DEPTH_CLOG2-1 downto 0);
        variable row1 : unsigned(RAM_DEPTH_CLOG2-1 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state      <= S_IDLE;
                p1_ram_addr  <= (others => '0');
                p1_ram_wr_en <= (others => '0');
                p1_ram_rd_en <= (others => '0');
                dout1_reg   <= (others => '0');
                addr1_lat   <= (others => '0');
                din1_lat    <= (others => '0');

                for i in 0 to N_Elements-1 loop
                    p1_ram_din(i) <= (others => '0');
                end loop;

            else
                p1_ram_wr_en <= (others => '0');
                p1_ram_rd_en <= (others => '0');

                for i in 0 to N_Elements-1 loop
                    p1_ram_din(i) <= (others => '0');
                end loop;

                row0 := resize(unsigned(addr1_lat), RAM_DEPTH_CLOG2) sll 1;
                row1 := (resize(unsigned(addr1_lat), RAM_DEPTH_CLOG2) sll 1) + 1;

                case state is

                    when S_IDLE =>
                        if rd_en1 = '1' then
                            addr1_lat    <= addr1;
                            p1_ram_addr  <= std_logic_vector(resize(unsigned(addr1), RAM_DEPTH_CLOG2) sll 1);
                            p1_ram_rd_en <= (others => '1');
                            state        <= S_P1_RD_0;

                        elsif wr_en1 = '1' then
                            addr1_lat    <= addr1;
                            din1_lat     <= din1;
                            p1_ram_addr  <= std_logic_vector(resize(unsigned(addr1), RAM_DEPTH_CLOG2) sll 1);
                            for i in 0 to N_Elements-1 loop
                                p1_ram_wr_en(i) <= '1';
                                p1_ram_din(i)   <= din1((i+1)*RAM_DATA_SIZE-1 downto i*RAM_DATA_SIZE);
                            end loop;
                            state <= S_P1_WR_0;
                        end if;

                    when S_P1_RD_0 =>
                        for i in 0 to N_Elements-1 loop
                            dout1_reg((i+1)*RAM_DATA_SIZE-1 downto i*RAM_DATA_SIZE) <= ram_dout(i);
                        end loop;

                        p1_ram_addr  <= std_logic_vector(row1);
                        p1_ram_rd_en <= (others => '1');
                        state        <= S_P1_RD_1;

                    when S_P1_RD_1 =>
                        for i in 0 to N_Elements-1 loop
                            dout1_reg(ROW_WIDTH + (i+1)*RAM_DATA_SIZE-1 downto ROW_WIDTH + i*RAM_DATA_SIZE) <= ram_dout(i);
                        end loop;
                        state <= S_IDLE;

                    when S_P1_WR_0 =>
                        p1_ram_addr <= std_logic_vector(row1);
                        for i in 0 to N_Elements-1 loop
                            p1_ram_wr_en(i) <= '1';
                            p1_ram_din(i)   <= din1_lat(ROW_WIDTH + (i+1)*RAM_DATA_SIZE-1 downto ROW_WIDTH + i*RAM_DATA_SIZE);
                        end loop;
                        state <= S_P1_WR_1;

                    when S_P1_WR_1 =>
                        state <= S_IDLE;

                end case;
            end if;
        end if;
    end process;

    dout1 <= dout1_reg;

    process(ram_dout)
    begin
        for i in 0 to N_Elements-1 loop
            dout2((i+1)*RAM_DATA_SIZE-1 downto i*RAM_DATA_SIZE) <= ram_dout(i);
        end loop;
    end process;

end Behavioral;