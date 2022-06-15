library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adaptive_threshold_top_level is 
  port(
    -- Clock/Reset
    clk       : in  std_logic;
    reset_n   : in  std_logic;

    -- FIFO1
		fifo1_data		: out std_logic_vector (31 downto 0);
		fifo1_rdreq		: out std_logic;
		fifo1_sclr		: out std_logic;
		fifo1_wrreq		: out std_logic;
		fifo1_empty		: in std_logic;
		fifo1_q		    : in std_logic_vector (31 downto 0);

    -- FIFO2
		fifo2_data		: out std_logic_vector (31 downto 0);
		fifo2_rdreq		: out std_logic;
		fifo2_sclr		: out std_logic;
		fifo2_wrreq		: out std_logic;
		fifo2_empty		: in std_logic;
		fifo2_q		    : in std_logic_vector (31 downto 0);

    -- FIFO3
		fifo3_data		: out std_logic_vector (31 downto 0);
		fifo3_rdreq		: out std_logic;
		fifo3_sclr		: out std_logic;
		fifo3_wrreq		: out std_logic;
		fifo3_empty		: in std_logic;
		fifo3_q		    : in std_logic_vector (31 downto 0);

    -- FIFO4
		fifo4_data		: out std_logic_vector (31 downto 0);
		fifo4_rdreq		: out std_logic;
		fifo4_sclr		: out std_logic;
		fifo4_wrreq		: out std_logic;
		fifo4_empty		: in std_logic ;
		fifo4_q		    : in std_logic_vector (31 downto 0);

    -- Interface to Output FIFO (lookahead)
		ofifo_data		: out std_logic_vector (31 downto 0);
		ofifo_sclr		: out std_logic;
		ofifo_wrreq		: out std_logic;
    ofifo_q		    : in std_logic_vector(31 downto 0);
    ofifo_rdreq		: out std_logic;

    -- Slave Avalon
    avs_add     : in  std_logic_vector(1 downto 0);
    avs_wr      : in  std_logic;
    avs_rd      : in  std_logic;
    avs_wrdata  : in  std_logic_vector(31 downto 0);
    avs_rddata  : out std_logic_vector(31 downto 0);

    -- Master Avalon
    avm_add:          out std_logic_vector(31 downto 0);
    avm_wr:           out std_logic;
    avm_rd:           out std_logic;
    avm_wrdata:       out std_logic_vector(31 downto 0);
    avm_rddata:       in  std_logic_vector(31 downto 0);
    avm_waitrequest:  in  std_logic;
    avm_beginbursttransfer: out std_logic;
    avm_burstcount:    out std_logic_vector(6 downto 0);
    avm_rddatavalid:  in std_logic;
    avm_be         : out std_logic_vector(3 downto 0)
  );
end entity adaptive_threshold_top_level;

architecture rtl of adaptive_threshold_top_level is
  component burst_writer is
    port(
      -- Clock/Reset
      clk:        in  std_logic;
      reset_n:    in  std_logic;

      -- Master Avalon (Writer)
      avm_waitrequest:  in  std_logic;
      avm_wr:           out std_logic;
      avm_wrdata:       out std_logic_vector(31 downto 0);
      avm_address:      out std_logic_vector(31 downto 0);
      avm_burstcount:   out std_logic_vector(6 downto 0);
      avm_beginburst:  out std_logic;

      -- Interface to Output FIFO (lookahead)
      ofifo_q		    : in std_logic_vector(31 downto 0);
      ofifo_rdreq		: out std_logic;

      -- Commands
      enable : in std_logic;
      done : out std_logic;
      burst_count : in std_logic_vector(6 downto 0);
      burst_address : in std_logic_vector(31 downto 0)
    );
  end component burst_writer;

  component burst_reader is
    port(
      -- Clock/Reset
      clk:        in  std_logic;
      reset_n:    in  std_logic;

      -- Master Avalon (Reader)
      avm_rddata:       in  std_logic_vector(31 downto 0);
      avm_waitrequest:  in  std_logic;
      avm_rddatavalid:  in std_logic;
      avm_beginburst:  out std_logic;
      avm_rd:           out std_logic;
      avm_burstcount:   out std_logic_vector(6 downto 0);
      avm_address:      out std_logic_vector(31 downto 0);

      -- Interface to FIFO multiplexer
      row_wrreq        : out std_logic;
      row_data        : out std_logic_vector(31 downto 0);
      row_sclr        : out std_logic;

      -- Commands
      enable : in std_logic;
      done : out std_logic;
      burst_count : in std_logic_vector(6 downto 0);
      burst_address : in std_logic_vector(31 downto 0);
      dummy_read : in std_logic
    );
  end component burst_reader;

  component fifo_mult is
    port(
      -- FIFO1
      fifo1_data		: out std_logic_vector (31 downto 0);
      fifo1_rdreq		: out std_logic;
      fifo1_sclr		: out std_logic;
      fifo1_wrreq		: out std_logic;
      fifo1_empty		: in std_logic;
      fifo1_q		    : in std_logic_vector (31 downto 0);

      -- fifo2
      fifo2_data		: out std_logic_vector (31 downto 0);
      fifo2_rdreq		: out std_logic;
      fifo2_sclr		: out std_logic;
      fifo2_wrreq		: out std_logic;
      fifo2_empty		: in std_logic;
      fifo2_q		    : in std_logic_vector (31 downto 0);

      -- fifo3
      fifo3_data		: out std_logic_vector (31 downto 0);
      fifo3_rdreq		: out std_logic;
      fifo3_sclr		: out std_logic;
      fifo3_wrreq		: out std_logic;
      fifo3_empty		: in std_logic;
      fifo3_q		    : in std_logic_vector (31 downto 0);

      -- fifo4
      fifo4_data		: out std_logic_vector (31 downto 0);
      fifo4_rdreq		: out std_logic;
      fifo4_sclr		: out std_logic;
      fifo4_wrreq		: out std_logic;
      fifo4_empty		: in std_logic ;
      fifo4_q		    : in std_logic_vector (31 downto 0);

      -- Port to command all
      row_rdreq1        : in std_logic;
      row_rdreq2        : in std_logic;
      row_rdreq3        : in std_logic;

      row_q1            : out std_logic_vector(31 downto 0);
      row_q2            : out std_logic_vector(31 downto 0);
      row_q3            : out std_logic_vector(31 downto 0);

      row_wrreq        : in std_logic;
      row_data        : in std_logic_vector(31 downto 0);
      row_sclr        : in std_logic;

      row_empty1        : out std_logic;
      row_empty2        : out std_logic;
      row_empty3        : out std_logic;


      select_idx    : in std_logic_vector(1 downto 0);

      row_wrreq1        : in std_logic;
      row_wrreq2        : in std_logic;
      row_wrreq3        : in std_logic;

      row_data1        : in std_logic_vector(31 downto 0);
      row_data2        : in std_logic_vector(31 downto 0);
      row_data3        : in std_logic_vector(31 downto 0);

      clr_all          : in std_logic
    );
  end component fifo_mult;

  component avalon_slave is
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
  end component avalon_slave;

  component adaptive_threshold is
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
  end component adaptive_threshold;

  component finite_state_machine is
    port(
      -- Clock/Reset
      clk:        in  std_logic;
      reset_n:    in  std_logic;

      -- Master Avalon
      avm_add:          out std_logic_vector(31 downto 0);
      avm_wr:           out std_logic;
      avm_rd:           out std_logic;
      avm_wrdata:       out std_logic_vector(31 downto 0);
      avm_rddata:       in  std_logic_vector(31 downto 0);
      avm_waitrequest:  in  std_logic;
      avm_beginbursttransfer: out std_logic;
      avm_burstcount:    out std_logic_vector(6 downto 0);
      avm_rddatavalid:  in std_logic;

      -- Avalon interface to burst reader and burst writer
      avm_add_burst_reader: in std_logic_vector(31 downto 0);
      avm_rd_burst_reader: in std_logic;
      avm_rddata_burst_reader: out std_logic_vector(31 downto 0);
      avm_waitrequest_burst_reader: out std_logic;
      avm_beginbursttransfer_burst_reader: in std_logic;
      avm_burstcount_burst_reader: in std_logic_vector(6 downto 0);
      avm_rddatavalid_burst_reader: out std_logic;

      avm_add_burst_writer: in std_logic_vector(31 downto 0);
      avm_wr_burst_writer: in std_logic;
      avm_wrdata_burst_writer: in std_logic_vector(31 downto 0);
      avm_waitrequest_burst_writer: out std_logic;
      avm_beginbursttransfer_burst_writer: in std_logic;
      avm_burstcount_burst_writer: in std_logic_vector(6 downto 0);

      -- Commands
      enable:     in std_logic;
      start_address:     in std_logic_vector(31 downto 0);
      done:       out std_logic;

      enable_burst_writer : out std_logic;
      enable_burst_reader : out std_logic;
      enable_compute : out std_logic;

      add_burst_writer : out std_logic_vector(31 downto 0);
      add_burst_reader : out std_logic_vector(31 downto 0);

      burst_count_burst_writer : out std_logic_vector(6 downto 0);
      burst_count_burst_reader : out std_logic_vector(6 downto 0);

      done_burst_writer : in std_logic;
      done_burst_reader : in std_logic;
      done_compute : in std_logic;
      dummy_read_burst_reader : out std_logic;

      select_idx : out std_logic_vector(1 downto 0);
      clr_all : out std_logic

    );

  end component finite_state_machine;

  signal row_rdreq1        : std_logic;
  signal row_rdreq2        : std_logic;
  signal row_rdreq3        : std_logic;

  signal row_q1            : std_logic_vector(31 downto 0);
  signal row_q2            : std_logic_vector(31 downto 0);
  signal row_q3            : std_logic_vector(31 downto 0);

  signal row_wrreq        : std_logic;
  signal row_data        : std_logic_vector(31 downto 0);
  signal row_sclr        : std_logic;

  signal row_empty1        : std_logic;
  signal row_empty2        : std_logic;
  signal row_empty3        : std_logic;


  signal select_idx    : std_logic_vector(1 downto 0);

  signal row_wrreq1        : std_logic;
  signal row_wrreq2        : std_logic;
  signal row_wrreq3        : std_logic;

  signal row_data1        : std_logic_vector(31 downto 0);
  signal row_data2        : std_logic_vector(31 downto 0);
  signal row_data3        : std_logic_vector(31 downto 0);

  signal clr_all          : std_logic;



  signal avm_add_burst_reader               : std_logic_vector(31 downto 0);
  signal avm_rd_burst_reader                : std_logic;
  signal avm_rddata_burst_reader            : std_logic_vector(31 downto 0);
  signal avm_waitrequest_burst_reader       : std_logic;
  signal avm_beginbursttransfer_burst_reader: std_logic;
  signal avm_burstcount_burst_reader        : std_logic_vector(6 downto 0);
  signal avm_rddatavalid_burst_reader       : std_logic;

  signal avm_add_burst_writer               : std_logic_vector(31 downto 0);
  signal avm_wr_burst_writer                : std_logic;
  signal avm_wrdata_burst_writer            : std_logic_vector(31 downto 0);
  signal avm_waitrequest_burst_writer       : std_logic;
  signal avm_beginbursttransfer_burst_writer: std_logic;
  signal avm_burstcount_burst_writer        : std_logic_vector(6 downto 0);




  signal enable:     std_logic;
  signal start_address:     std_logic_vector(31 downto 0);
  signal done:       std_logic;

  signal enable_burst_writer : std_logic;
  signal enable_burst_reader : std_logic;
  signal enable_compute : std_logic;

  signal add_burst_writer : std_logic_vector(31 downto 0);
  signal add_burst_reader : std_logic_vector(31 downto 0);

  signal burst_count_burst_writer : std_logic_vector(6 downto 0);
  signal burst_count_burst_reader : std_logic_vector(6 downto 0);

  signal done_burst_writer : std_logic;
  signal done_burst_reader : std_logic;
  signal done_compute : std_logic;
  signal dummy_read_burst_reader : std_logic;

  constant col_size : std_logic_vector(15 downto 0) :=  std_logic_vector(to_unsigned(320, 16));


begin
  fifo_mult_inst : component fifo_mult
  port map(
    -- FIFO1
    fifo1_data	=>	fifo1_data	,
    fifo1_rdreq	=>	fifo1_rdreq	,
    fifo1_sclr	=>	fifo1_sclr	,
    fifo1_wrreq	=>	fifo1_wrreq	,
    fifo1_empty	=>	fifo1_empty	,
    fifo1_q		  =>  fifo1_q		  ,

    -- fifo2
    fifo2_data	=> fifo2_data	,
    fifo2_rdreq	=> fifo2_rdreq,	
    fifo2_sclr	=> fifo2_sclr	,
    fifo2_wrreq	=> fifo2_wrreq,	
    fifo2_empty	=> fifo2_empty,	
    fifo2_q		  => fifo2_q		,  

    -- fifo3
    fifo3_data	 => fifo3_data	,
    fifo3_rdreq	 => fifo3_rdreq	,
    fifo3_sclr	 => fifo3_sclr	,
    fifo3_wrreq	 => fifo3_wrreq	,
    fifo3_empty	 => fifo3_empty	,
    fifo3_q		   => fifo3_q		  ,

    -- fifo4
    fifo4_data	=> fifo4_data	,
    fifo4_rdreq	=> fifo4_rdreq	,
    fifo4_sclr	=> fifo4_sclr	,
    fifo4_wrreq	=> fifo4_wrreq	,
    fifo4_empty	=> fifo4_empty	,
    fifo4_q		  => fifo4_q		  ,

    -- Port to command all
    row_rdreq1   => row_rdreq1,
    row_rdreq2   => row_rdreq2,
    row_rdreq3   => row_rdreq3,
                               
    row_q1       => row_q1    ,
    row_q2       => row_q2    ,
    row_q3       => row_q3    ,
                               
    row_wrreq    => row_wrreq ,
    row_data     => row_data  ,
    row_sclr     => row_sclr  ,
                               
    row_empty1   => row_empty1,
    row_empty2   => row_empty2,
    row_empty3   => row_empty3,
                               
                               
    select_idx   => select_idx,
                               
    row_wrreq1   => row_wrreq1,
    row_wrreq2   => row_wrreq2,
    row_wrreq3   => row_wrreq3,
                               
    row_data1    => row_data1 ,
    row_data2    => row_data2 ,
    row_data3    => row_data3 ,
                               
    clr_all      => clr_all    
  );

  finite_state_machine_inst : component finite_state_machine
  port map(
    -- Clock/Reset
    clk     => clk,     
    reset_n => reset_n,

    -- Master Avalon
    avm_add           => avm_add,
    avm_wr            => avm_wr ,
    avm_rd            => avm_rd ,
    avm_wrdata        => avm_wrdata,
    avm_rddata        => avm_rddata,
    avm_waitrequest   => avm_waitrequest   ,
    avm_beginbursttransfer  => avm_beginbursttransfer,
    avm_burstcount  => avm_burstcount,
    avm_rddatavalid   => avm_rddatavalid,

    -- Avalon interface to burst reader and burst writer
    avm_add_burst_reader => avm_add_burst_reader,
    avm_rd_burst_reader => avm_rd_burst_reader,
    avm_rddata_burst_reader => avm_rddata_burst_reader,
    avm_waitrequest_burst_reader => avm_waitrequest_burst_reader,
    avm_beginbursttransfer_burst_reader => avm_beginbursttransfer_burst_reader,
    avm_burstcount_burst_reader => avm_burstcount_burst_reader,
    avm_rddatavalid_burst_reader => avm_rddatavalid_burst_reader,

    avm_add_burst_writer => avm_add_burst_writer,
    avm_wr_burst_writer => avm_wr_burst_writer,
    avm_wrdata_burst_writer => avm_wrdata_burst_writer,
    avm_waitrequest_burst_writer => avm_waitrequest_burst_writer,
    avm_beginbursttransfer_burst_writer => avm_beginbursttransfer_burst_writer,
    avm_burstcount_burst_writer => avm_burstcount_burst_writer,

    -- Commands
    enable => enable,
    start_address => start_address,
    done => done,

    enable_burst_writer  => enable_burst_writer ,
    enable_burst_reader  => enable_burst_reader ,
    enable_compute  => enable_compute ,

    add_burst_writer  => add_burst_writer ,
    add_burst_reader  => add_burst_reader ,

    burst_count_burst_writer  => burst_count_burst_writer ,
    burst_count_burst_reader  => burst_count_burst_reader ,

    done_burst_writer  => done_burst_writer ,
    done_burst_reader  => done_burst_reader ,
    done_compute  => done_compute ,
    dummy_read_burst_reader  => dummy_read_burst_reader ,

    select_idx => select_idx,
    clr_all => clr_all
  );

  adaptive_threshold_inst : component adaptive_threshold
  port map(
    -- Clock/Reset
    clk => clk,
    reset_n => reset_n,

    -- Interface to FIFO multiplexer
    row_rdreq1      => row_rdreq1,
    row_rdreq2      => row_rdreq2,
    row_rdreq3      => row_rdreq3,
                                  
    row_q1          => row_q1,
    row_q2          => row_q2,
    row_q3          => row_q3,
                                  
    row_empty1      => row_empty1,
    row_empty2      => row_empty2,
    row_empty3      => row_empty3,
                                  
    row_wrreq1      => row_wrreq1,
    row_wrreq2      => row_wrreq2,
    row_wrreq3      => row_wrreq3,
                                  
    row_data1       => row_data1 ,
    row_data2       => row_data2 ,
    row_data3       => row_data3 ,

    -- Interface to output FIFO
    ofifo_data		 => ofifo_data ,
    ofifo_sclr		 => ofifo_sclr ,
    ofifo_wrreq		 => ofifo_wrreq,

    -- Interface to Avalon Master
    enable => enable_compute,
    col_size => col_size,
    done => done_compute
  );

  burst_writer_inst : component burst_writer
  port map(
    -- Clock/Reset
    clk => clk,
    reset_n => reset_n,

    -- Master Avalon (Writer)
    avm_waitrequest =>  avm_waitrequest_burst_writer,
    avm_wr          =>  avm_wr_burst_writer,
    avm_wrdata      =>  avm_wrdata_burst_writer,
    avm_address     =>  avm_add_burst_writer,
    avm_burstcount  =>  avm_burstcount_burst_writer,
    avm_beginburst  =>  avm_beginbursttransfer_burst_writer,

    -- Interface to Output FIFO (lookahead)
    ofifo_q	=> ofifo_q,
    ofifo_rdreq => ofifo_rdreq,

    -- Commands
    enable => enable_burst_writer,
    done => done_burst_writer,
    burst_count => burst_count_burst_writer,
    burst_address => add_burst_writer
  );

  burst_reader_inst : component burst_reader
  port map(
    -- Clock/Reset
    clk => clk,
    reset_n => reset_n,

    -- Master Avalon (Reader)
    avm_rddata => avm_rddata_burst_reader,
    avm_waitrequest => avm_waitrequest_burst_reader,
    avm_rddatavalid => avm_rddatavalid_burst_reader,
    avm_beginburst => avm_beginbursttransfer_burst_reader,
    avm_rd => avm_rd_burst_reader,
    avm_burstcount => avm_burstcount_burst_reader,
    avm_address => avm_add_burst_reader,

    -- Interface to FIFO multiplexer
    row_wrreq => row_wrreq,
    row_data  => row_data,
    row_sclr  => row_sclr,

    -- Commands
    enable => enable_burst_reader,
    done => done_burst_reader,
    burst_count => burst_count_burst_reader,
    burst_address => add_burst_reader,
    dummy_read => dummy_read_burst_reader
  );

  avalon_slave_inst : component avalon_slave
  port map(
    -- Clock/Reset
    clk        => clk,
    reset_n    => reset_n,

    -- Slave Avalon
    avs_add      => avs_add,
    avs_wr       => avs_wr,
    avs_rd       => avs_rd,
    avs_wrdata   => avs_wrdata,
    avs_rddata   => avs_rddata,

    -- conduits
    start_address => start_address,
    done => done,
    enable => enable
  );

  avm_be <= "1111";
end rtl;
