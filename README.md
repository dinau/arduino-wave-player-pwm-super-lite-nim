## Arduino Wave Player PWM - Super Lite -  Nim
---

<img src="https://github.com/dinau/arduino-wave-player-pwm-super-lite-nim/blob/main/doc/arduino-nano-wave-pwm-player-real-1280-2020-11.jpg?raw=true" width=320>

* #### Description
    * This project is very simple wave player program with SD card using Nim language and
      using only passive parts, capacitor,diode and resistor except SC card.

* #### Prerequisite
    * [nim-1.6.0](https://nim-lang.org/install.html)  
        * **Important**:  It must be used above nim version otherwise it won't work well.
    * avr-gcc v7.3.0 (inclued in [arduino-1.8.16 IDE](https://www.arduino.cc/en/software))  
        * For example, if on Windows10 set executable path to  
             **d:\arduino-1.8.16\hardware\tools\avr\bin**  
    * make,rm and etc Linux tool commands
* #### Target Boards
    * Arduino Uno / Nano
* #### Schematic and Photo
    [Schematic](#schematic)  
    [Photo](#photo)   
    [Output filter](#output-filter)
* ### Build project
    * You can use make command for build management as follows,
        ```sh
        $ make # build target
        $ make clean # clean target
        $ make w # upload to flash
        ```
        or
        ```sh
        $ nim make # build target
        $ nim clean # clean target
        $ nim w # upload to flash
        ```
    * Artifacts (`*`.hex,`*`.lst files etc) would be generate to **.BUILD** folder.

* #### Supported SD card
    * SDSC/SDHC card  FAT16 and FAT32  
        1. First, format SD card using [SD Card Formatter](https://www.sdcard.org/downloads/formatter_4/index.html)
        1.  Copy PCM wav files to root directory of the SD card.

* #### Supported file
    PCM wave files that have file extension "**.wav**" on root directory.  
    PCM:16bit/8bit, fs(sampling rate)=32kHz,**44.1kHz**,48kHz.  
    Stereo/Mono.    
    
* #### Hardware setting    
    * Refer to the file **./port_setting.txt**     
    * PWM output port:    
        ```
        Audio Left     PWM out : OC1A: PB1, 15pin, D9
        Audio Right    PWM out : OC1B: PB2, 16pin, D10
        ```
    
* #### User button (S1) 
    * D2 (PD2)   Button SW
        * **Next song** : One click during Play mode.    
        * **Play Pause**: Push long time .     
        * **Play**      : One click from Pause state.    
* #### Control from UART 
    * Set baudrate: 38400bps
        * **Next song**:
            Send from key board '**n**' or ' '(**Space**) during Play or Pause mode.    
        * **Play/Pause**:
            Send from key board '**s**' or '**p**' or '**ESC**'(Escape char) during Play or Pause mode.     
            Play or Pause mode would be toggled. 
* #### Display music filename during play mode by UART output.
    * This is debug purpose so only display **8.3 type** filename (ansi).
        - UART output
            ```
            OURPLACE.WAV   # Power on. Start playing music.
            RAINBOWS.WAV
            ACOUST~1.WAV
            ARTP7   .WAV
            HOTELC  .WAV
            OURPLACE.WAV   # Repeat form first file. 
            RAINBOWS.WAV
            ...
            ```
* ### Schematic  
    * Arduino Nano    
        * External 3.3V power is required so that the current consumption of SD card might exceed instantaneously over 100mA when power becomes on. 
            * <img src="https://github.com/dinau/arduino-wave-player-pwm-super-lite-nim/blob/main/doc/arduino-nano-wave-pwm-player.png?raw=true" width=640>

* ### Photo
    * Arduino Nano compatible board
    <img src="https://github.com/dinau/arduino-wave-player-pwm-super-lite-nim/blob/main/doc/arduino-nano-wave-pwm-player-real-1280-2020-11.jpg?raw=true" width=640>

* ### Output filter
    ![filer](http://mpu.up.seesaa.net/image/pwm-filter-output.png)


### Other links2
* Wave player project Super lite series
    * Nim language
        * [Arduino Wave Player PWM Super Lite Nim / Nim](https://github.com/dinau/arduino-wave-player-pwm-super-lite-nim) Completed.
        * [STM32 Wave Player PWM Super Lite Nim / STM32(F0,L1,F3,F4)  Nim](https://github.com/dinau/stm32-wave-player-pwm-super-lite-nim) Completed. 
    * C++ language
        * [Wave Player Super Lite / STM32(F0,L1,F4) / Mbed2 / C++](https://os.mbed.com/users/mimi3/code/wave_player_super_lite) Completed.
    * Jal language
        * [Pwm Wave Player Jalv2 / PIC16F1xxx / Jal](https://github.com/dinau/16f-wave-player-pwm-super-lite-jalv2)
