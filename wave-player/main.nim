#[
  2019,2021 by audin (http://mpu.seesaa.net)
  Nim language test program for Arduino UNO and its compatibles.
  AVR = atmega328p / 16MHz
  avr-gcc: ver.7.3.0 (arduino-1.8.16/hardware/tools/avr/bin)
  nim-1.6.0
  UART baudrate 38400 bps

]#

import conf_sys,pwm,systick,spi,uart
import sd_card,fat_lib,wave_player_main
#[ /* SD card pin
 Pin side
 --------------\
         9     = \    DAT2/NC
             1 ===|   CS/DAT3    [CS]
             2 ===|   CMD/DI     [DI]
             3 ===|   VSS1
 Bottom      4 ===|   VDD
 View        5 ===|   CLK        [CLK]
             6 ===|   VSS2
             7 ===|   DO/DAT0    [DO]
         8       =|   DAT1/IRQ
 -----------------

                                         Arduino      NUCLEO-F411       NUCLEO-F030R8
 Logo side
 -----------------
         8       =|   DAT1/IRQ
             7 ===|   DO/DAT0    [DO]     D12           D12/PA_6           D12/PA_6
             6 ===|   VSS2
 Top         5 ===|   CLK        [CLK]    D13           D13/PA_5           D13/PA_5
 View        4 ===|   VDD
             3 ===|   VSS1
             2 ===|   CMD/DI     [DI]     D11           D11/PA_7           D11/PA_7
             1 ===|   CS/DAT3    [CS]     D8/D4         D10/PB_6           D10/PB_6
         9     = /    DAT2/NC
 --------------/
 */
]#

template initPort*() =
# set pull up to i/o port.
    PORTB.st 0xFF
    PORTC.st 0xFF
    PORTD.st 0xFF
    DDRB.st  0xEF # all output except PB4
    DDRD.st  0xFF # all output port

# main program
proc main() =
    initPort()
    ind_off()
    initSystick()
    when UART_INFO:
        initUart(mBRate(UART_BAUDRATE)) # 38400bps
    initSpi()                       # SCK=8MHz
    initPwm()                       # PWM setting
    enablePwmPeriodIntr()           # enable PWM period interrupt

    ei()                            # enable all interrupt

    while not sd_init():            # SDSC,SDHC initialize
        wait_ms(2000)
    FAT_init()                      # Accept FAT16 and FAT32
    wave_player_main()              # Play wav file

# Run main
main()

