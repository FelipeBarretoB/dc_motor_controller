library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RotaryEncController is
    Generic (
        -- For Testbench simulation, override this value to 5
        DEBOUNCE_LIMIT : integer := 25_000
    );
    Port (
        clk   : in  STD_LOGIC; -- 100 MHz system clock
        reset : in  STD_LOGIC; -- Active-low asynchronous reset ('0')
        A     : in  STD_LOGIC; -- PmodENC channel A
        B     : in  STD_LOGIC; -- PmodENC channel B
        cnt1  : out  UNSIGNED(3 downto 0) := (others => '0');
        cnt2  : out  UNSIGNED(3 downto 0) := (others => '0');
        cnt : out SIGNED(8 downto 0) := (others => '0');
        positiveValue : out std_logic 
    );
end RotaryEncController;

architecture Behavioral of RotaryEncController is
    -- 2-FF synchronizers to prevent metastability on asynchronous Pmod inputs
    signal A_sync, B_sync : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal A_prev         : STD_LOGIC := '0';
   
    -- Sampling timer for PmodENC debouncing
    signal deb_count      : integer range 0 to DEBOUNCE_LIMIT := 0;
    signal step_en        : STD_LOGIC;
    signal dir            : std_logic := '1';

    -- Internal BCD counter registers (0 to 9)
    signal cnt1_reg       : UNSIGNED(3 downto 0) := (others => '0');
    signal cnt2_reg       : UNSIGNED(3 downto 0) := (others => '0');
    signal cnt_sum        : SIGNED(8 downto 0) := (others => '0');
    signal cnt_dir        : SIGNED(8 downto 0) := (others => '0');

begin


    -- Detect a clean rising edge on A at each debounced sampling tick
    step_en <= '1' when (deb_count = DEBOUNCE_LIMIT - 1 and A_sync(1) = '1' and A_prev = '0') else '0';
    cnt_sum <= signed ('0' & (cnt2_reg*10 + cnt1_reg)); -- we sum the values, so we can later use them in the speed controller
    cnt_dir <= -cnt_sum when dir = '0' else cnt_sum;
    cnt1 <= cnt1_reg;
    cnt2 <= cnt2_reg;
    cnt <= cnt_dir;
    positiveValue <= dir;

    -- Main sequential process: synchronization, debouncing, and BCD up/down counting
    process(clk, reset)
    begin
        if reset = '0' then
            A_sync    <= (others => '0');
            B_sync    <= (others => '0');
            A_prev    <= '0';
            deb_count <= 0;
            cnt1_reg  <= (others => '0');
            cnt2_reg  <= (others => '0');
            dir <= '1';

        elsif rising_edge(clk) then
            -- 1. Synchronize external Pmod signals
            -- A_sync(0) goes into A_sync(1) and A goes into A_sync(0) (same for B)
            A_sync <= A_sync(0) & A;
            B_sync <= B_sync(0) & B;

            -- 2. Sample every 1 ms to filter mechanical contact bounce
            if deb_count = DEBOUNCE_LIMIT - 1 then
                deb_count <= 0;
                A_prev    <= A_sync(1);
            else
                deb_count <= deb_count + 1;
            end if;

            -- 3. Up/Down BCD counter (00 to 99)
            if step_en = '1' then
                if B_sync(1) = dir then -- Clockwise: INCREMENT
                    if cnt1_reg = "1001" then
                        if cnt2_reg /= "1001" then
                            cnt2_reg <= cnt2_reg + 1;
                            cnt1_reg <= (others => '0');
                        end if;
                    else
                        if cnt2_reg /= "1000" then  
                            cnt1_reg <= cnt1_reg + 1;
                        end if;
                    end if;

                else -- B_sync(1) = '1' -> Counter-clockwise: DECREMENT
                    if cnt1_reg = "0000" then
                        if cnt2_reg /= "0000" then
                            cnt2_reg <= cnt2_reg - 1;
                            cnt1_reg <= "1001";
                        else
                            dir <= not dir;
                            cnt1_reg <= cnt1_reg +1;
                        end if;
                    else
                        cnt1_reg <= cnt1_reg - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
   

end Behavioral;