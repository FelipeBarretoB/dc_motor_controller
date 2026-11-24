library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MotorController is
    Port (
        clk   : in  STD_LOGIC; -- 100 MHz system clock
        reset : in  STD_LOGIC; -- Active-low asynchronous reset ('0')
        A     : in  STD_LOGIC; -- PmodENC channel A
        B     : in  STD_LOGIC; -- PmodENC channel B
        AN    : out STD_LOGIC_VECTOR (7 downto 0); -- 7-segment anodes (active-low)
        LED   : out STD_LOGIC_VECTOR (8 downto 0); -- small LED to sum and debug
        seg   : out STD_LOGIC_VECTOR (7 downto 0)  -- 7-segment cathodes + DP (active-low)
    );
end MotorController;

architecture Behavioral of MotorController is
    -- Sampling timer for PmodENC debouncing
    signal positiveValue  : STD_LOGIC :='1';

    -- Internal BCD counter registers (0 to 9)
    signal cnt1_reg       : UNSIGNED(3 downto 0) := (others => '0');
    signal cnt2_reg       : UNSIGNED(3 downto 0) := (others => '0');
    signal cnt_dir        : SIGNED(8 downto 0) := (others => '0');
begin

    LED <= STD_LOGIC_VECTOR(cnt_dir); -- to show the if the sum is working 

    U_ENCODER : entity work.RotaryEncController
        generic map(
            DEBOUNCE_LIMIT => 25_000
        )
        port map(
            clk => clk,
            reset => reset,
            A => A,
            B => B, 
            cnt1 => cnt1_reg,
            cnt2 => cnt2_reg,
            cnt => cnt_dir,
            positiveValue => positiveValue
        );

    U_DISPLAY : entity work.DisplayController
        generic map(
            DIV_LIMIT => 12_499
        )
        port map (
            clk => clk,
            reset => reset,
            cnt1 => cnt1_reg,
            cnt2 => cnt2_reg,
            AN => AN,
            seg => seg,
            positiveValue => positiveValue
        );

end Behavioral;