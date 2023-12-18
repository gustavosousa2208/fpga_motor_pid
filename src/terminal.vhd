library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity terminal is 
    port (
        clk, sys_reset : in std_logic;
        desiredDirection : out std_logic_vector(1 downto 0);
        desiredSpeed, desiredDutyCycle : out integer;
        actualSpeed, pulseCounter : in integer;
        var1, var2, var3, var4 : inout integer;
        btn0, btn1 : in std_logic;
        terminal_reset_out : out std_logic;
        rx : in std_logic;
        tx : out std_logic;
        leds : out std_logic_vector(5 downto 0)
    );
end entity;

architecture rtl of terminal is 

    component uart IS
    GENERIC(
        clk_freq  :  INTEGER    := 27_000_000;  --frequency of system clock in Hertz
        baud_rate :  INTEGER    := 115_200;      --data link baud rate in bits/second
        os_rate   :  INTEGER    := 16;          --oversampling rate to find center of receive bits (in samples per baud period)
        d_width   :  INTEGER    := 8;           --data bus width
        parity    :  INTEGER    := 1;           --0 for no parity, 1 for parity
        parity_eo :  STD_LOGIC  := '0');        --'0' for even, '1' for odd parity
    PORT(
        clk      :  IN   STD_LOGIC;                             --system clock
        reset_n  :  IN   STD_LOGIC;                             --ascynchronous reset
        tx_ena   :  IN   STD_LOGIC;                             --initiate transmission
        tx_data  :  IN   STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --data to transmit
        rx       :  IN   STD_LOGIC;                             --receive pin
        rx_busy  :  OUT  STD_LOGIC;                             --data reception in progress
        rx_error :  OUT  STD_LOGIC;                             --start, parity, or stop bit error detected
        rx_data  :  OUT  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --data received
        tx_busy  :  OUT  STD_LOGIC;                             --transmission in progress
        tx       :  OUT  STD_LOGIC);                            --transmit pin
    END component;

    signal motorReset_n : std_logic;
    signal toSend : std_logic_vector(7 downto 0);
    signal tx_busy : std_logic;
    signal tx_ena : std_logic;
    signal actualSpeedVector, pulseCounterVector : std_logic_vector(31 downto 0) := (others => '0');
    signal rx_busy, rx_error : std_logic;
    signal rx_data, last_data : std_logic_vector(7 downto 0);
    signal recv_toggle : std_logic := '0';
    signal treated : std_logic := '0';

    type functions is (reset_t, idle);
    signal state, next_state : functions := idle;

begin
    motorReset_n <= not sys_reset;
    actualSpeedVector <= "0000000000000000" & std_logic_vector(to_unsigned(actualSpeed, 16));
    pulseCounterVector <= "0000000000000000" & std_logic_vector(to_unsigned(pulseCounter, 16));
    
    uart0 : uart generic map(
        clk_freq => 27_000_000,
        baud_rate => 115_200,
        os_rate => 16,
        d_width => 8,
        parity => 0,
        parity_eo => '0'
    ) 
    port map(
        clk => clk,
        reset_n => motorReset_n,
        tx_ena => tx_ena,
        tx_data => toSend,
        rx => rx,
        rx_busy => rx_busy,
        rx_error => rx_error,
        rx_data => rx_data,
        tx_busy => tx_busy,
        tx => tx
    );

    recv_data : process(clk, rx_busy, last_data)
    begin
        if sys_reset = '1' or treated = '1' then
            last_data <= (others => '0');
            recv_toggle <= '0';
        elsif falling_edge(rx_busy) then
            last_data <= rx_data;
            recv_toggle <= not recv_toggle;
        end if;
    end process;

    treat_data : process(clk, rx_busy, last_data)
        variable letter_n : integer range 0 to 255 := 0;
        variable received : std_logic;
        variable step : integer range 0 to 3 := 0;
    begin
        if rising_edge(clk) then
            if last_data = x"52" then
                case step is 
                    when 0 => 
                        terminal_reset_out <= '1';
                        step := 1;
                    when 1 => 
                        step := 2;
                    when 2 => 
                        step := 3;
                    when 3 => 
                        step := 0;
                        treated <= '1';
                        terminal_reset_out <= '0';
                    when others => null;
                end case;
            else
                step := 0;
                treated <= '0';
            end if;
        end if;
    end process;

    update_duty_cycle : process(clk, btn0, btn1)
        variable start : std_logic := '0';
    begin
        if rising_edge(clk) then
            if btn0 = '0' and btn1 = '1' then
                desiredDutyCycle <= 180;
                desiredDirection <= "10";
            elsif btn1 = '0' and btn0 = '1'then  
                desiredDutyCycle <= 180;
                desiredDirection <= "01";
            else
                desiredDutyCycle <= 0;
                desiredDirection <= "00";
            end if;
        end if;
    end process;

    send_data : process(sys_reset, clk, tx_busy)
        variable letter_n : integer range 0 to 255 := 0;
        variable requested : std_logic;
    begin
        if sys_reset = '1' then
            letter_n := 0;
            requested := '0';
        elsif rising_edge(clk) then
            if tx_busy = '0' then
                tx_ena <= '1';
                if requested = '0' then
                    requested := '1';
                    letter_n := letter_n + 1;
                    if letter_n = 12 then
                        letter_n := 0;
                    end if;
                end if;
            else 
                tx_ena <= '0';
                requested := '0';
            end if;
            
            case letter_n is 
                when 0 => toSend <= x"53";
                when 1 => toSend <= actualSpeedVector(31 downto 24);
                when 2 => toSend <= actualSpeedVector(23 downto 16);
                when 3 => toSend <= actualSpeedVector(15 downto 8);
                when 4 => toSend <= actualSpeedVector(7 downto 0);
                when 5 => toSend <= x"43";
                when 6 => toSend <= pulseCounterVector(31 downto 24);
                when 7 => toSend <= pulseCounterVector(23 downto 16);
                when 8 => toSend <= pulseCounterVector(15 downto 8);
                when 9 => toSend <= pulseCounterVector(7 downto 0);
                when 10 => toSend <= x"0D";
                when 11 => toSend <= x"0A";
                when others => null;
            end case;
        end if;
    end process;

    leds(0) <= rx_error;
    leds(1) <= not terminal_reset_out;
    leds(2) <= recv_toggle;
end architecture;