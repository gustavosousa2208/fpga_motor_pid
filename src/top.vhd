-- Author : Gustavo Sousa
-- Date : 18/11/2023
-- File : top.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    port(
        -- system pins
        clk, btn0, btn1 : in std_logic;
        leds : out std_logic_vector(5 downto 0);

        -- encoder and driver pins
        encoder: in std_logic_vector(1 downto 0);
        speed : out std_logic;
        direction : out std_logic_vector(1 downto 0);

        -- display pins
        cs, mosi, sck, dc : out std_logic;

        -- serial pins
        tx, rx_dbg, tx_dbg : out std_logic;
        rx : in std_logic
    );
end entity;

architecture rtl of top is 

    component terminal is 
        port (
            clk, sys_reset : in std_logic;
            desiredSpeed, desiredDutyCycle : out integer;
            actualSpeed, pulseCounter : in integer;
            var1, var2, var3, var4 : inout integer;
            btn0, btn1 : in std_logic;
            rx : in std_logic;
            tx : out std_logic;
            terminal_reset_out : out std_logic;
            leds : out std_logic_vector(5 downto 0);
            desiredDirection : out std_logic_vector(1 downto 0)
        );
    end component;
    signal terminal_clk : std_logic;
    signal terminal_reset_out : std_logic;
    signal reset : std_logic := '0'; -- reset do sistema todo
    
    component motor is 
        port(
            clk : in std_logic;
            reset : in std_logic;
            speed : out std_logic;
            direction : out std_logic_vector(1 downto 0);
            desiredDirection : in std_logic_vector(1 downto 0);
            encoder : in std_logic_vector(1 downto 0);
            actualSpeed, pulseCounter : out integer;
            desiredSpeed, desiredDutyCycle : in integer;
            terminal_reset : in std_logic
        );
    end component;
    signal desiredSpeed, desiredDutyCycle, actualSpeed, pulseCounter : integer;
    signal motor_clk : std_logic;
    signal desiredDirection : std_logic_vector(1 downto 0);
    signal var1, var2, var3, var4 : integer;

    component Gowin_rPLL
        port (
            clkout: out std_logic;
            clkin: in std_logic
        );
    end component;
    signal pllin : std_logic;
    signal pllout : std_logic;
    signal sys_reset : std_logic;

begin

    terminal0 : terminal port map(
        clk => terminal_clk,
        btn0 => btn0,
        btn1 => btn1,
        desiredSpeed => desiredSpeed,
        actualSpeed => actualSpeed, 
        desiredDutyCycle => desiredDutyCycle,
        rx => rx,
        tx => tx,
        var1 => var1,
        var2 => var2,
        var3 => var3,
        var4 => var4,
        leds => leds,
        pulseCounter => pulseCounter,
        desiredDirection => desiredDirection,
        terminal_reset_out => terminal_reset_out,
        sys_reset => sys_reset
    );

    motor0 : motor port map(
        clk => motor_clk,
        reset => sys_reset,
        speed => speed,
        direction => direction,
        encoder => encoder,
        desiredSpeed => desiredSpeed,
        actualSpeed => actualSpeed,
        desiredDirection => desiredDirection,
        desiredDutyCycle => desiredDutyCycle,
        pulseCounter => pulseCounter,
        terminal_reset => terminal_reset_out
    );

    terminal_clk <= clk;
    motor_clk <= clk;

    sys_reset <= '0';
    rx_dbg <= rx;
    tx_dbg <= tx;
end architecture;