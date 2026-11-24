library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity DisplayController is
    Generic (
        -- 50,000 cycles at 100 MHz = 1 kHz display refresh rate
        -- For Testbench simulation, override this value to 5
        DIV_LIMIT      : integer := 12_499
    );
    Port (
        clk   : in  STD_LOGIC; -- 100 MHz system clock
        reset : in  STD_LOGIC; -- Active-low asynchronous reset ('0')
        cnt1  : in  UNSIGNED(3 downto 0) := (others => '0');
        cnt2  : in  UNSIGNED(3 downto 0) := (others => '0');
        positiveValue : in STD_LOGIC;
        AN    : out STD_LOGIC_VECTOR (7 downto 0); -- 7-segment anodes (active-low)
        seg   : out STD_LOGIC_VECTOR (7 downto 0)  -- 7-segment cathodes + DP (active-low)
    );
end DisplayController;

architecture Behavioral of DisplayController is

    -- Internal 7-segment decoded patterns
    signal seg1, seg2, seg3    : STD_LOGIC_VECTOR(7 downto 0) := (others => '1');

    -- Clock divider signals for display multiplexing
    signal clk_sel        : UNSIGNED(2 downto 0) := (others => '0');
    signal clk_count      : INTEGER :=1;
begin

-- Combinational 7-segment decoder for units (cnt1_reg)
    process (cnt1)
    begin
        case cnt1 is
            when "0000" => seg1 <= "11000000"; -- 0
            when "0001" => seg1 <= "11111001"; -- 1
            when "0010" => seg1 <= "10100100"; -- 2
            when "0011" => seg1 <= "10110000"; -- 3
            when "0100" => seg1 <= "10011001"; -- 4
            when "0101" => seg1 <= "10010010"; -- 5
            when "0110" => seg1 <= "10000010"; -- 6
            when "0111" => seg1 <= "11111000"; -- 7
            when "1000" => seg1 <= "10000000"; -- 8
            when "1001" => seg1 <= "10010000"; -- 9
            when others => seg1 <= "11111111"; -- off
        end case;
    end process;

    -- Combinational 7-segment decoder for tens (cnt2_reg)
    process (cnt2)
    begin
        case cnt2 is
            when "0000" => seg2 <= "11000000"; -- 0
            when "0001" => seg2 <= "11111001"; -- 1
            when "0010" => seg2 <= "10100100"; -- 2
            when "0011" => seg2 <= "10110000"; -- 3
            when "0100" => seg2 <= "10011001"; -- 4
            when "0101" => seg2 <= "10010010"; -- 5
            when "0110" => seg2 <= "10000010"; -- 6
            when "0111" => seg2 <= "11111000"; -- 7
            when "1000" => seg2 <= "10000000"; -- 8
            when "1001" => seg2 <= "10010000"; -- 9
            when others => seg2 <= "11111111"; -- off
        end case;
    end process;
    
    process (positiveValue)
    begin
        if positiveValue /= '1' then 
            seg3 <= "10111111";
        else 
            seg3 <="11111111";
        end if;
    end process;
    
    
    -- Clock divider for 7-segment display multiplexing (~1 kHz)
    process(clk, reset)
    begin
        if reset = '0' then
            clk_count <= 1;
            clk_sel   <=  (others => '0');
        elsif rising_edge(clk) then
            if clk_count = DIV_LIMIT then
                if clk_sel = "111" then
                    clk_sel <= (others => '0');
                else
                    clk_sel   <= clk_sel +1 ;
                end if;
                clk_count <= 1;
            else
                clk_count <= clk_count + 1;
            end if;
        end if;
    end process;

    -- Display multiplexer (switches active digit and segment data)
    process(clk_sel, seg1, seg2, seg3)
    begin
        case clk_sel is
            when "000" =>
                seg <= seg1;       -- Output units digit to segments
                AN  <= "11111110"; -- Enable rightmost display (AN0)
            when "001" =>
                seg <= seg2;       -- Output tens digit to segments
                AN  <= "11111101"; -- Enable second display (AN1)
            when "010" =>
                seg <= seg3; 
                AN  <= "11111011";
            when "011" =>
                seg <= "10000110";
                AN  <= "11110111";
            when "100" =>
                seg <= seg1;       -- Output units digit to segments
                AN  <= "11101111"; -- Enable rightmost display (AN0)
            when "101" =>
                seg <= seg2;       -- Output tens digit to segments
                AN  <= "11011111"; -- Enable second display (AN1)
            when "110" =>
                seg <= seg3; 
                AN  <= "10111111";
            when "111" =>
                 seg <= "10101111";
                AN  <= "01111111";
            when others =>
                seg <= (others => '1');
                AN  <= (others => '1');
        end case;
    end process;
end Behavioral;