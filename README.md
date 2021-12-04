## Arduino Wave Player PWM - Super Lite -  Nim
---
* #### Description
    * This project is very simple wave player program with SD card using Nim language.  

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
    * PD2, D2   Button SW
        ```sh
        Next song : One click during Play mode.    
        Play Pause: Push long time .     
        Play      : One click from Pause state.    
        ```

* ### Schematic  
    * Arduino Nano    
<img src="https://github.com/dinau/arduino-wave-player-pwm-super-lite-nim/blob/main/doc/arduino-nano-wave-pwm-player.png?raw=true" width=640>

* ### Photo
    * Arduino Nano compatible board
    <img src="https://github.com/dinau/arduino-wave-player-pwm-super-lite-nim/blob/main/doc/arduino-nano-wave-pwm-player-real-1280-2020-11.jpg?raw=true" width=640>

* ### Output filter
    ![filer](http://mpu.up.seesaa.net/image/pwm-filter-output.png)
