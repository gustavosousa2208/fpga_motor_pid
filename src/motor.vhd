library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity motor is 
    port(
        clk : in std_logic;
        reset : in std_logic;
        speed : out std_logic;
        direction : out std_logic_vector(1 downto 0);
        desiredDirection : in std_logic_vector(1 downto 0);
        encoder : in std_logic_vector(1 downto 0);
        actualSpeed, pulseCounter : out integer ;
        desiredSpeed, desiredDutyCycle : in integer;
        terminal_reset : in std_logic
    );
end entity;

architecture rtl of motor is

    type stateType is (reset_state, idle, forward, backward);
    signal state, nextState : stateType := reset_state;

    signal started : std_logic := '0';
    signal PWMEnable, pwm : std_logic := '1';
    signal reset_bus : std_logic := '0';
begin

    reset_bus <= reset or terminal_reset;

    generatePWM : process(clk, reset_bus, desiredDutyCycle)
        variable counter : integer := 0;
        variable sawtooth : integer := 0;
    begin
        if rising_edge(clk) then
            if counter < 211 then
                counter := counter + 1;
            else
                counter := 0;
                if sawtooth <= 1023 then
                    sawtooth := sawtooth + 1;
                else
                    sawtooth := 0;
                end if;
            end if;
        end if;

        if sawtooth < desiredDutyCycle then
            pwm <= '1';
        else
            pwm <= '0';
        end if;
    end process;

    -- speed <= '0';
    speed <= pwm when PWMEnable = '1' else '0';
    direction <= desiredDirection;

    pulses_counter : process(clk, reset_bus, encoder)
        variable counter : integer range 65535 downto 0 := 0;
    begin
        if reset_bus = '1' then
            counter := 0;
        elsif rising_edge(encoder(0)) then
            if encoder(1) = '1' then
                counter := counter + 1;
            else
                counter := counter - 1;
            end if;
        end if;

        pulseCounter <= counter;
    end process;

    actualSpeed <= 257;

end architecture;