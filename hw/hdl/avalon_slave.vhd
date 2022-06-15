library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity avalon_slave is
  port(
    -- Clock/Reset
    clk       : in  std_logic;
    reset_n   : in  std_logic;

    -- Slave Avalon
    avs_add     : in  std_logic_vector(1 downto 0);
    avs_wr      : in  std_logic;
    avs_rd      : in  std_logic;
    avs_wrdata  : in  std_logic_vector(31 downto 0);
    avs_rddata  : out std_logic_vector(31 downto 0);

    -- conduits
    start_address : out std_logic_vector(31 downto 0);
    done          : in std_logic;
    enable        : out std_logic
  );
end avalon_slave;

architecture comp of avalon_slave is
  signal RegStartAddress    : std_logic_vector(31 downto 0);
  signal Start              : std_logic;
begin
  enable <= Start;
  start_address <= RegStartAddress;

  -- Avalon write access
  AvalonSlaveWr: process(clk, reset_n)
  begin
    if reset_n = '0' then
      RegStartAddress <= (others => '0');
      Start <= '0';
    elsif rising_edge(clk) then
      Start <= '0';
      if avs_wr = '1' then
        case avs_add is
          when "00" => RegStartAddress <= avs_wrdata;
          when "01" => Start <= avs_wrdata(0);
          when others => null;
        end case;
      end if;
    end if;
  end process AvalonSlaveWr;

  -- Avalon read access
  AvalonSlaveRd: process(clk)
  begin
    if rising_edge(clk) then
      if avs_rd = '1' then
        avs_rddata <= (others => '0');
        case avs_add is
          when "00" => avs_rddata <= RegStartAddress;
          when "10" => avs_rddata(0) <= done;
          when others => null;
        end case;
      end if;
    end if;
  end process AvalonSlaveRd;
end comp;
