#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include "hwlib.h"
#include "socal/hps.h"
#include "../hps_soc_system.h"
#include "alt_16550_uart.h"

#include "alt_interrupt.h"

#include "alt_globaltmr.h"


#include <socal/socal.h>

#include "alt_bridge_manager.h"


#define IMG_WIDTH 320
#define IMG_HEIGHT 240

ALT_16550_HANDLE_t handle;

ALT_STATUS_CODE status;

uint32_t size_rx, size_tx;

int int_id = ALT_INT_INTERRUPT_UART0;


uint8_t* img = NULL;

uint32_t img_offset = 0;

bool transmission_done;
bool irq_hit = false;

void *fpga_leds = ALT_LWFPGASLVS_ADDR + HPS_FPGA_LEDS_BASE;

void *fpga_dma = ALT_LWFPGASLVS_ADDR + HPS_ADAPTIVE_THRESHOLD_DMA_BASE;


void uart_callback(uint32_t icciar, void* context) 
{
  ALT_16550_INT_STATUS_t int_status;
  alt_16550_int_status_get(&handle, &int_status);

  switch (int_status)
  {
  case ALT_16550_INT_STATUS_RX_DATA:
  case ALT_16550_INT_STATUS_RX_TIMEOUT:
    {
      uint32_t fifo_level_rx;
      alt_16550_fifo_level_get_rx(&handle, &fifo_level_rx);

      uint32_t copy_size = fifo_level_rx;
      if(img_offset+fifo_level_rx > IMG_WIDTH*IMG_HEIGHT) {
        copy_size = IMG_WIDTH*IMG_HEIGHT - img_offset;
      }

      if(copy_size > 0) {
        alt_16550_fifo_read(&handle, img+img_offset, copy_size);
        img_offset += copy_size;
        fifo_level_rx -= copy_size;
      }

      if(fifo_level_rx > 0) {
        alt_16550_fifo_clear_rx(&handle);
      }

      break;
    }
  case ALT_16550_INT_STATUS_TX_IDLE:
    {
      uint32_t fifo_level_tx;
      alt_16550_fifo_level_get_tx(&handle, &fifo_level_tx);

      uint32_t copy_size = size_tx - fifo_level_tx;
      if(img_offset+copy_size > IMG_WIDTH*IMG_HEIGHT) {
        copy_size = IMG_WIDTH*IMG_HEIGHT - img_offset;
      }

      if(copy_size > 0) {
        alt_16550_fifo_write(&handle, img+img_offset, copy_size);
        img_offset += copy_size;
      } else {
        transmission_done = true;
      }
      alt_16550_int_disable_tx(&handle);
      irq_hit = true;

      break;
    }
  case ALT_16550_INT_STATUS_LINE:
    {
      uint32_t line_status;
      alt_16550_line_status_get(&handle, &line_status);

      if (line_status & ALT_16550_LINE_STATUS_OE)
      {
        printf("UART[buffer]: Overrun Error detected.\n");
      }
      else if (line_status & ALT_16550_LINE_STATUS_PE)
      {
        /* Unlikely to occur as parity is turned off. Added for completeness. */
        printf("UART[buffer]: Parity Error detected.\n");
      }
      else if (line_status & ALT_16550_LINE_STATUS_FE)
      {
        printf("UART[buffer]: Framing Error detected.\n");
      }
      else if (line_status & ALT_16550_LINE_STATUS_RFE)
      {
        printf("UART[buffer]: Receiver FIFO Error detected.\n");
      }

      break;
    }
  default:
      break;
  }

}

void delay_us(uint32_t us) {
  uint64_t start_time = alt_globaltmr_get64();
  uint32_t timer_prescaler = alt_globaltmr_prescaler_get() + 1;
  uint64_t end_time;
  alt_freq_t timer_clock;

  assert(ALT_E_SUCCESS == alt_clk_freq_get(ALT_CLK_MPU_PERIPH, &timer_clock));
  end_time = start_time + us * ((timer_clock / timer_prescaler) / ALT_MICROSECS_IN_A_SEC);

  // polling wait
  while(alt_globaltmr_get64() < end_time);
}

void setup_fpga_leds() {
    // Switch on first LED only
    alt_write_word(fpga_leds, 0x1);
}

void handle_fpga_leds() {
    uint32_t leds_mask = alt_read_word(fpga_leds);

    if (leds_mask != (0x01 << (HPS_FPGA_LEDS_DATA_WIDTH - 1))) {
        // rotate leds
        leds_mask <<= 1;
    } else {
        // reset leds
        leds_mask = 0x1;
    }

    alt_write_word(fpga_leds, leds_mask);
}

void do_adaptive_threshold(uint8_t* img)
{
  alt_freq_t timer_clock;
  assert(ALT_E_SUCCESS == alt_clk_freq_get(ALT_CLK_MPU_PERIPH, &timer_clock));
  uint32_t timer_prescaler = alt_globaltmr_prescaler_get() + 1;
  uint64_t end_time;
  uint64_t start_time = alt_globaltmr_get64();

  // for(int i=0; i<240; i += 60) {
    void* ptr = (void*)img;
    alt_write_word(fpga_dma, img);

    start_time = alt_globaltmr_get64();
    alt_write_word(fpga_dma+0x4, 0x1); // start

    uint32_t finished;
    do {
      finished = alt_read_word(fpga_dma+0x8);
    } while(finished == 0);
  // }

  // measure elapsed time
  end_time = alt_globaltmr_get64();

  uint32_t us = (end_time - start_time) / ((timer_clock / timer_prescaler) / ALT_MICROSECS_IN_A_SEC);
  printf("elapsed: %lu us\n", us);
}

void do_adaptive_threshold_hps(uint8_t* img)
{

  uint8_t* res = (uint8_t*)malloc(320*240);

  for(int i=0; i<240*320; ++i) {
    res[i] = img[i];
  }

  alt_freq_t timer_clock;
  assert(ALT_E_SUCCESS == alt_clk_freq_get(ALT_CLK_MPU_PERIPH, &timer_clock));
  uint32_t timer_prescaler = alt_globaltmr_prescaler_get() + 1;
  uint64_t end_time;
  uint64_t start_time = alt_globaltmr_get64();

  for(int i=0; i<240; ++i) {
    for(int j=0; j<320; ++j) {
      uint16_t sum = 0;
      if(i < 1 || j < 1 || i >= 240-1 || j >= 320-1) {
        res[i*320+j] = img[i*320+j];
      } else {
        for(int k=0; k<3; ++k) {
          for(int l=0; l<3; ++l) {
            sum += (uint16_t)img[(i-1+k)*320+(j-1+l)];
          }

          if(sum > 9*img[i*320+j]) {
            res[i*320+j] = 0x00;
          } else {
            res[i*320+j] = 0xFF;
          }
        }
      }
    }
  }

  // measure elapsed time
  end_time = alt_globaltmr_get64();

  uint32_t us = (end_time - start_time) / ((timer_clock / timer_prescaler) / ALT_MICROSECS_IN_A_SEC);
  printf("elapsed hps: %lu us\n", us);

  for(int i=0; i<240*320; ++i) {
    img[i] = res[i];
  }

  free(res);
}

int main() {

  // Setting up bridges
  alt_bridge_init(ALT_BRIDGE_F2H, NULL, NULL);

  alt_globaltmr_init();

  handle.device     = ALT_16550_DEVICE_SOCFPGA_UART0;
  handle.location   = 0;
  handle.clock_freq = 0;


  setup_fpga_leds();

  alt_16550_init(handle.device, handle.location, handle.clock_freq, &handle);

  // Configure for 8-N-1.
  // This is not really needed as the default configuration is 8-N-1.
  alt_16550_line_config_set(&handle, ALT_16550_DATABITS_8,
      ALT_16550_PARITY_DISABLE,
      ALT_16550_STOPBITS_1);

  // Configure for 115200 baud.
  alt_16550_divisor_set(&handle, 5);

  // alt_16550_baudrate_set(&handle, ALT_16550_BAUDRATE_115200);

  // Enable the UART
  alt_16550_enable(&handle);

  // Get divisor
  uint32_t divisor;
  alt_16550_divisor_get(&handle, &divisor);

  uint32_t baudrate;
  alt_16550_baudrate_get(&handle, &baudrate);

  alt_int_global_init();
  alt_int_cpu_init();
  alt_int_cpu_enable();
  alt_int_global_enable();

  alt_16550_fifo_enable(&handle);

  // Query the size for rx
  alt_16550_fifo_size_get_rx(&handle, &size_rx);
  alt_16550_fifo_size_get_tx(&handle, &size_tx);

  alt_16550_fifo_trigger_set_rx(&handle,
      ALT_16550_FIFO_TRIGGER_RX_HALF_FULL);
  alt_16550_fifo_trigger_set_tx(&handle,
      ALT_16550_FIFO_TRIGGER_TX_EMPTY);

  // Only enable TX when data needs to be written
  alt_16550_int_enable_rx(&handle);

  // Allows to detect errors
  alt_16550_int_enable_line(&handle);

  alt_int_isr_register(int_id, uart_callback, NULL);

  if(int_id >= 32) {
    uint32_t int_target = (1 << alt_int_util_cpu_count()) - 1;
    alt_int_dist_target_set(int_id, int_target);
  }
  alt_int_dist_enable(int_id);


  img = (uint8_t*)malloc(IMG_WIDTH*IMG_HEIGHT);

  while(true) {
    img_offset = 0;
    while(img_offset < IMG_WIDTH*IMG_HEIGHT) {
    }

    do_adaptive_threshold(img);

    transmission_done = false;
    img_offset = 0;
    while(!transmission_done) {
      irq_hit = false;
      alt_16550_int_enable_tx(&handle);
      while(!irq_hit) {
      }
    }

  }
  free(img);


  alt_int_dist_disable(int_id);
  alt_int_isr_unregister(int_id);
  alt_16550_int_disable_all(&handle);

  alt_16550_fifo_disable(&handle);

  alt_int_global_disable();
  alt_int_cpu_disable();
  alt_int_cpu_uninit();
  alt_int_global_uninit();

  alt_16550_disable(&handle);
  alt_16550_uninit(&handle);


  // printf("Hi!\n");

  while (true) {
    handle_fpga_leds();

    delay_us(ALT_MICROSECS_IN_A_SEC / 10);
  }


  return 0;
}

