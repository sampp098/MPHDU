library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

entity findMin is
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
end entity;

--architecture Behavioral of findMin is
    
--    -- Types pour stocker les données et index entre les étages
--    type data_array_lines   is array (NBR_CLASS_NEXT_POW2 - 1 downto 0) of unsigned(ACC_WIDTH - 1 downto 0);
--    type idx_array_lines    is array (NBR_CLASS_NEXT_POW2 - 1 downto 0) of unsigned(NBR_CLASS_CLOG2 - 1 downto 0);
--    type active_array_lines is array (NBR_CLASS_NEXT_POW2 - 1 downto 0) of std_logic;

--    type data_array_stages   is array (NBR_CLASS_NEXT_POW2_CLOG2 - 1 downto 0) of data_array_lines;
--    type idx_array_stages    is array (NBR_CLASS_NEXT_POW2_CLOG2 - 1 downto 0) of idx_array_lines;
--    type active_array_stages is array (NBR_CLASS_NEXT_POW2_CLOG2 - 1 downto 0) of active_array_lines;

--    -- Signaux internes pour stocker les données et index entre les étages
--    signal data_between_stages   : data_array_stages;
--    signal idx_between_stages    : idx_array_stages;
--    signal active_between_stages : active_array_stages;

--begin

--    -- Génération des étages de comparaisons successifs
--    gen_stages : for s in 0 to NBR_CLASS_NEXT_POW2_CLOG2 - 1 generate
--        gen_stage_s : for i in 0 to (NBR_CLASS_NEXT_POW2 / (2 ** s)) - 1 generate

--            -- Premier étage (entrées)
--            first_stage : if s = 0 generate

--                data_between_stages(s)(i)   <= unsigned(findmin_data_input((i + 1) * ACC_WIDTH - 1 downto i * ACC_WIDTH));
--                idx_between_stages(s)(i)    <= to_unsigned(i, NBR_CLASS_CLOG2);
--                active_between_stages(s)(i) <= findmin_active_input(i);

--            end generate first_stage;

--            -- Entre les étages
--            between_stages : if s > 0 generate

--                signal sel : std_logic;

--                begin

--                sel <=
--                    '1' when active_between_stages(s - 1)(2 * i + 1) = '1' and active_between_stages(s - 1)(2 * i) = '0' else
--                    '0' when active_between_stages(s - 1)(2 * i + 1) = '0' else
--                    '1' when data_between_stages(s - 1)(2 * i + 1) < data_between_stages(s - 1)(2 * i) else
--                    '0';

--                -- Sélection de la data la plus petite, et l'indice correspondant
--                data_between_stages(s)(i) <= data_between_stages(s - 1)(2 * i + 1) when sel = '1' else data_between_stages(s - 1)(2 * i);
--                idx_between_stages(s)(i)  <= idx_between_stages(s - 1)(2 * i + 1)  when sel = '1' else idx_between_stages(s - 1)(2 * i);
            
--                -- L'activation de l'étage suivant est le OR logique des deux d'entrée (car une seule doit survivre)
--                active_between_stages(s)(i) <= active_between_stages(s - 1)(2 * i) or active_between_stages(s - 1)(2 * i + 1);

--            end generate between_stages;

--            -- Dernier étage (sortie)
--            last_stage : if s = NBR_CLASS_NEXT_POW2_CLOG2 - 1 generate

--                findmin_minIdx_output <= std_logic_vector(idx_between_stages(s)(0));

--            end generate last_stage;

--        end generate gen_stage_s;
--    end generate gen_stages;

--end Behavioral;
architecture Behavioral of findMin is

    -- One line holds a value for every original class position.
    type data_array_lines is array (0 to NBR_CLASS_NEXT_POW2 - 1) of
        unsigned(ACC_WIDTH - 1 downto 0);

    type idx_array_lines is array (0 to NBR_CLASS_NEXT_POW2 - 1) of
        unsigned(NBR_CLASS_CLOG2 - 1 downto 0);

    type active_array_lines is array (0 to NBR_CLASS_NEXT_POW2 - 1) of
        std_logic;

    -- Stage 0 holds original inputs.
    -- Stages 1..CLOG2 implement the reduction tree.
    type data_array_stages is array (0 to NBR_CLASS_NEXT_POW2_CLOG2) of
        data_array_lines;

    type idx_array_stages is array (0 to NBR_CLASS_NEXT_POW2_CLOG2) of
        idx_array_lines;

    type active_array_stages is array (0 to NBR_CLASS_NEXT_POW2_CLOG2) of
        active_array_lines;

    signal data_between_stages   : data_array_stages;
    signal idx_between_stages    : idx_array_stages;
    signal active_between_stages : active_array_stages;

begin

    ----------------------------------------------------------------
    -- Optional safety assertion:
    -- this architecture requires NBR_CLASS_NEXT_POW2 = 2^CLOG2.
    ----------------------------------------------------------------
    assert NBR_CLASS_NEXT_POW2 = 2 ** NBR_CLASS_NEXT_POW2_CLOG2
        report "findMin error: NBR_CLASS_NEXT_POW2 must equal 2^NBR_CLASS_NEXT_POW2_CLOG2"
        severity failure;

    ----------------------------------------------------------------
    -- Stage 0: Input distances, indices, and active flags.
    ----------------------------------------------------------------
    gen_input_stage : for i in 0 to NBR_CLASS_NEXT_POW2 - 1 generate
    begin

        -- Class i is stored in data-input bits:
        -- [(i+1)*ACC_WIDTH-1 downto i*ACC_WIDTH].
        data_between_stages(0)(i) <= unsigned(
            findmin_data_input((i + 1) * ACC_WIDTH - 1 downto i * ACC_WIDTH)
        );

        idx_between_stages(0)(i) <= to_unsigned(i, NBR_CLASS_CLOG2);

        active_between_stages(0)(i) <= findmin_active_input(i);

    end generate gen_input_stage;

    ----------------------------------------------------------------
    -- Reduction tree.
    --
    -- For eight inputs:
    -- stage 1: 4 winners
    -- stage 2: 2 winners
    -- stage 3: 1 final winner
    ----------------------------------------------------------------
    gen_compare_stages : for s in 1 to NBR_CLASS_NEXT_POW2_CLOG2 generate

        gen_compare_nodes : for i in 0 to
            (NBR_CLASS_NEXT_POW2 / (2 ** s)) - 1 generate

            signal sel_right : std_logic;

        begin

            --------------------------------------------------------
            -- Select the right candidate when:
            -- 1. Right is active and left is inactive, or
            -- 2. Both are active and right has a smaller distance.
            --
            -- Equal distances select the left candidate. This gives
            -- deterministic lowest-index tie-breaking.
            --------------------------------------------------------
            sel_right <=
                '1' when (
                    active_between_stages(s - 1)(2 * i + 1) = '1' and
                    active_between_stages(s - 1)(2 * i)     = '0'
                ) else

                '0' when active_between_stages(s - 1)(2 * i + 1) = '0' else

                '1' when (
                    data_between_stages(s - 1)(2 * i + 1) <
                    data_between_stages(s - 1)(2 * i)
                ) else

                '0';

            data_between_stages(s)(i) <=
                data_between_stages(s - 1)(2 * i + 1)
                when sel_right = '1'
                else
                data_between_stages(s - 1)(2 * i);

            idx_between_stages(s)(i) <=
                idx_between_stages(s - 1)(2 * i + 1)
                when sel_right = '1'
                else
                idx_between_stages(s - 1)(2 * i);

            active_between_stages(s)(i) <=
                active_between_stages(s - 1)(2 * i) or
                active_between_stages(s - 1)(2 * i + 1);

        end generate gen_compare_nodes;

    end generate gen_compare_stages;

    ----------------------------------------------------------------
    -- The final stage contains exactly one winner: element zero.
    --
    -- For 8 classes, this reads:
    -- idx_between_stages(3)(0)
    ----------------------------------------------------------------
    findmin_minIdx_output <= std_logic_vector(
        idx_between_stages(NBR_CLASS_NEXT_POW2_CLOG2)(0)
    );

end architecture Behavioral;