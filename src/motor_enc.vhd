library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MotorEncController is
    GENERIC (
        CONUTS_FOR_REV : integer := 524
        SAMPLE_TIME    : integer := 9_999_999
    );
    port(
        clk   : in  STD_LOGIC; -- 100 MHz system clock
        reset : in  STD_LOGIC; -- Active-low asynchronous reset ('0')
        A     : in  STD_LOGIC; -- PmodENC channel A
        B     : in  STD_LOGIC; -- PmodENC channel B
        cnt1  : out UNSIGNED(3 downto 0) := (others => '0');
        cnt2  : out UNSIGNED(3 downto 0) := (others => '0');
        speed : out UNSIGNED(3 downto 0) := (others => '0');
    );
end MotorEncController;

architecture Behavioral of MotorEncController is

    signal A_sync, B_sync : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal A_prev         : STD_LOGIC := '0';
    signal A_edge         : STD_LOGIC := '0';

    signal speed          : UNSIGNED(3 downto 0) := (others =>'0');
    signal sample_timer   : integer range 0 to SAMPLE_TIME := 0; --we should look into this, SAMPLE_TIME is to big for updating the the speed counter every 0.1s
    signal cnt1_reg, cnt2_reg, cnt       : UNSIGNED(3 downto 0) := (others => '0');

begin

    A_edge <= '1' when (A_sync(1) = '1' and A_prev ='0') else  '0';
    dir <= dir_reg; 

    process(clk, reset)
    begin
        if reset = '0' then 

        elsif rising_edge(clk) then
            A_sync <= A_sync(0) & A;
            B_sync <= B_sync(0) & B;

            if sample_timer = SAMPLE_TIME - 1 then
                sample_timer <= 0;
                speed <= (cnt * 60) / CONUTS_FOR_REV

            else
                sample_timer <= sample_timer +1;
            end if;

            if A_edge ='1' then
                cnt <= cnt + 1;
            end if;

        end if;
    end process;

end Behavioral;