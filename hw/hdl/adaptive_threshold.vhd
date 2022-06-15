library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adaptive_threshold is
  port(
    -- Clock/Reset
    clk:        in  std_logic;
    reset_n:    in  std_logic;

    -- Interface to FIFO multiplexer
    row_rdreq1        : out std_logic;
    row_rdreq2        : out std_logic;
    row_rdreq3        : out std_logic;

    row_q1            : in std_logic_vector(31 downto 0);
    row_q2            : in std_logic_vector(31 downto 0);
    row_q3            : in std_logic_vector(31 downto 0);

    row_empty1        : in std_logic;
    row_empty2        : in std_logic;
    row_empty3        : in std_logic;

    row_wrreq1        : out std_logic;
    row_wrreq2        : out std_logic;
    row_wrreq3        : out std_logic;

    row_data1        : out std_logic_vector(31 downto 0);
    row_data2        : out std_logic_vector(31 downto 0);
    row_data3        : out std_logic_vector(31 downto 0);

    -- Interface to output FIFO
		ofifo_data		: out std_logic_vector (31 downto 0);
		ofifo_sclr		: out std_logic;
		ofifo_wrreq		: out std_logic;

    -- Interface to Avalon Master
    enable            : in std_logic;
    col_size          : in std_logic_vector(15 downto 0);
    done              : out std_logic
  );
end adaptive_threshold;

architecture comp of adaptive_threshold is
  type SM is(IdleCompute, ReadDelay, FirstCompute, Compute, LastCompute, LastComputeWrite);
  signal StateM: SM;

begin
  -- Adaptive thresholding process
  ComputeProcess: process(clk, reset_n)
    variable ColCounter : unsigned(15 downto 0);

    variable last_q1 : std_logic_vector(15 downto 0);
    variable last_q2 : std_logic_vector(15 downto 0);
    variable last_q3 : std_logic_vector(15 downto 0);

    variable last_result : std_logic_vector(23 downto 0);
    variable current_result : std_logic_vector(31 downto 0);
    variable next_result : std_logic_vector(7 downto 0);


    procedure fifo_set_read is
    begin
      row_rdreq1 <= not row_empty1;
      row_rdreq2 <= not row_empty2;
      row_rdreq3 <= not row_empty3;
    end;

    procedure fifo_unset_read is
    begin
      row_rdreq1 <= '0';
      row_rdreq2 <= '0';
      row_rdreq3 <= '0';
    end;

    procedure fifo_set_write_back is
    begin
      row_wrreq1 <= not row_empty1;
      row_wrreq2 <= not row_empty2;
      row_wrreq3 <= not row_empty3;

      row_data1 <= row_q1;
      row_data2 <= row_q2;
      row_data3 <= row_q3;
    end;


    procedure fifo_unset_write_back is
    begin
      row_wrreq1 <= '0';
      row_wrreq2 <= '0';
      row_wrreq3 <= '0';
    end;

    function do_computation(
        row1 : std_logic_vector(23 downto 0);
        row2 : std_logic_vector(23 downto 0);
        row3 : std_logic_vector(23 downto 0)
      ) return std_logic_vector is

      variable region_sum : unsigned(11 downto 0) := x"000";
    begin
      region_sum := region_sum + unsigned(row1(23 downto 16));
      region_sum := region_sum + unsigned(row1(15 downto 8));
      region_sum := region_sum + unsigned(row1(7 downto 0));
      region_sum := region_sum + unsigned(row2(23 downto 16));
      region_sum := region_sum + unsigned(row2(15 downto 8));
      region_sum := region_sum + unsigned(row2(7 downto 0));
      region_sum := region_sum + unsigned(row3(23 downto 16));
      region_sum := region_sum + unsigned(row3(15 downto 8));
      region_sum := region_sum + unsigned(row3(7 downto 0));

      if region_sum < 9*unsigned(row2(15 downto 8)) then
        return x"FF";
      else
        return x"00";
      end if;
    end function;

  begin
    if reset_n = '0' then
      ColCounter := x"0000";
      StateM <= IdleCompute;
      ofifo_wrreq <= '0';
      ofifo_sclr <= '1';
      done <= '1';

      fifo_unset_read;
      fifo_unset_write_back;

    elsif rising_edge(clk) then
      ofifo_sclr <= '0';
      ofifo_wrreq <= '0';

      case StateM is
        when IdleCompute =>
          done <= '1';
          fifo_unset_read;
          fifo_unset_write_back;
          ColCounter := x"0000";

          if enable = '1' then
            StateM <= ReadDelay;
            fifo_set_read;
            ofifo_sclr <= '1';
            done <= '0';
          end if;

        -- Need 1 clock cycle delay for FIFO read
        when ReadDelay =>
          StateM <= FirstCompute;
          ofifo_sclr <= '0';

        when FirstCompute =>
          -- The first compuation is special because the leftmost pixel
          -- is outside the border
          last_result(7 downto 0) := do_computation(
            row_q1(15 downto 0) & x"00",
            row_q2(15 downto 0) & x"00",
            row_q3(15 downto 0) & x"00");

          last_result(15 downto 8) := do_computation(
            row_q1(23 downto 0),
            row_q2(23 downto 0),
            row_q3(23 downto 0));

          last_result(23 downto 16) := do_computation(
            row_q1(31 downto 8),
            row_q2(31 downto 8),
            row_q3(31 downto 8));

          last_q1 := row_q1(31 downto 16);
          last_q2 := row_q2(31 downto 16);
          last_q3 := row_q3(31 downto 16);

          ColCounter := ColCounter + 4;
          StateM <= Compute;
          fifo_set_write_back;

        when Compute => 
          current_result(7 downto 0) := do_computation(
            row_q1(7 downto 0) & last_q1(15 downto 0),
            row_q2(7 downto 0) & last_q2(15 downto 0),
            row_q3(7 downto 0) & last_q3(15 downto 0));

          current_result(15 downto 8) := do_computation(
            row_q1(15 downto 0) & last_q1(7 downto 0),
            row_q2(15 downto 0) & last_q2(7 downto 0),
            row_q3(15 downto 0) & last_q3(7 downto 0));

          current_result(23 downto 16) := do_computation(
            row_q1(23 downto 0),
            row_q2(23 downto 0),
            row_q3(23 downto 0));

          current_result(31 downto 24) := do_computation(
            row_q1(31 downto 8),
            row_q2(31 downto 8),
            row_q3(31 downto 8));

          last_q1 := row_q1(31 downto 16);
          last_q2 := row_q2(31 downto 16);
          last_q3 := row_q3(31 downto 16);

          ofifo_wrreq <= '1';
          ofifo_data <= current_result(7 downto 0) & last_result;
          last_result := current_result(31 downto 8);

          fifo_set_write_back;

          ColCounter := ColCounter + 4;
          if ColCounter >= unsigned(col_size)-4 then
            StateM <= LastCompute;
            fifo_unset_read;
          end if;
        when LastCompute =>
          current_result(7 downto 0) := do_computation(
            row_q1(7 downto 0) & last_q1(15 downto 0),
            row_q2(7 downto 0) & last_q2(15 downto 0),
            row_q3(7 downto 0) & last_q3(15 downto 0));

          current_result(15 downto 8) := do_computation(
            row_q1(15 downto 0) & last_q1(7 downto 0),
            row_q2(15 downto 0) & last_q2(7 downto 0),
            row_q3(15 downto 0) & last_q3(7 downto 0));

          current_result(23 downto 16) := do_computation(
            row_q1(23 downto 0),
            row_q2(23 downto 0),
            row_q3(23 downto 0));

          current_result(31 downto 24) := do_computation(
            row_q1(31 downto 8),
            row_q2(31 downto 8),
            row_q3(31 downto 8));

          next_result := do_computation(
            x"00" & row_q1(31 downto 16),
            x"00" & row_q2(31 downto 16),
            x"00" & row_q3(31 downto 16));

          fifo_set_write_back;

          ofifo_wrreq <= '1';
          ofifo_data <= current_result(7 downto 0) & last_result;
          StateM <= LastComputeWrite;

        when LastComputeWrite =>
          ofifo_wrreq <= '1';
          ofifo_data <= next_result & current_result(31 downto 8);
          StateM <= IdleCompute;

          fifo_unset_write_back;
        when others => null;
      end case;
    end if;
  end process;
end comp;
