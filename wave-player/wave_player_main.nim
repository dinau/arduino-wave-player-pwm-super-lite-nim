import conf_sys
import sd_card,fat_lib,systick
import pwm,spi,uart

# Use Timer1 Interrupt
# Refer to http://milkandlait.blogspot.com/2014/06/avr-gcc.html
{.emit:"""
#include <avr/interrupt.h>
static void inline pwmPeriodIntr(void);
    #pragma GCC optimize ("O3")
    ISR(TIMER1_OVF_vect){
        pwmPeriodIntr();
    }
    #pragma GCC optimize ("Os")
""".}

# *******************************
#  external referenced functions
# *******************************
# proc wave_player_main*()

# *******************************
# local template
# *******************************
template pwm_period_timer_music_stop() =
    #pwm_period_timer_stop() # This function occures pop noise.
    fPlaying = false

template pwm_period_timer_music_start() =
    pwm_period_timer_start()
    fPlaying = true

##################################
const
#   bCH_MONO        = 1
    bCH_STEREO      = 2
    wREAD_COUNT     = 512
    bHEADER_COUNT   = 44
var
    lbSample_bits   = 16.byte
    ldwSample_freq  = 44100.dword
    lbCh_mode:byte  = bCH_STEREO
    lwReadCount     = 0.word
    lbReadCountS16  = 0.byte
    fPlaying:bool   = false
    ldwSongFileSectors:dword = 0

type TMode = enum
    S16 = 0'u8, M16, S8, M8
var bMode:TMode

# ################################
# pwmPeriodIntr (TIMER1)
# *******************************
# For speed up, this interrupt function is redundant.
proc pwmPeriodIntr(){.exportc,inline.} =
    when TEST_PORT_ENABLE: test_on()
    if not fPlaying: return              # to avoid pop noise
    ###
    var bL,bR:byte
    if bMode == S16:                     # Stereo 16bit
        discard send_ff()                # discard lower 8bit
        pwm_dutyL( send_ff() + 0x80'u8 ) # only output hi byte
        discard send_ff()                # discard lower 8bit
        pwm_dutyR( send_ff() + 0x80'u8 ) # only output hi byte
        lbReadCountS16 -= 1
        # check boundery of 512byte per sector
        if lbReadCountS16 == 0:          # End of one sector
            lbReadCountS16 = 128         # 128 = 512/4
            discard send_ff()            # dummy read. discard CRC
            discard send_ff()            # 2nd dummy read.
            ldwSongFileSectors -= 1
            while send_ff() != 0xFE: discard
    else:
        case bMode
            of M16:                      # Mono 16bit
                discard send_ff()        # discard lower 8bit
                bL = send_ff() + 0x80'u8
                bR = bL
                lwReadCount -= 2
            of S8:                       # Stereo 8bit
                bL = send_ff()
                bR = send_ff()
                lwReadCount -= 2
            else:                        # Mono 8bit
                bL = send_ff()
                bR = bL
                lwReadCount -= 1
        # change pwm duties
        pwm_dutyL( bL )
        pwm_dutyR( bR )
        # check boundery of 512byte sector
        if lwReadCount == 0:              # End of one sector
            lwReadCount = wREAD_COUNT
            discard send_ff()             # dummy read. discard CRC
            discard send_ff()             # 2nd dummy read.
            ldwSongFileSectors -= 1
            while send_ff() != 0xFE:discard

    if ldwSongFileSectors == 0:           # Check end of one song
        pwm_period_timer_music_stop()

    ###
    when TEST_PORT_ENABLE: test_off()
    # end interruput

# *****************
#  varialble definitions
# *****************
const
    CUT_LAST_TAG_NOISE = (30 * 1000) # 30k bytes
when HAVE_LED_IND_BLINK:
    const
        LED_PERIOD_PLAYNG  = 75
        LED_PERIOD_PAUSING = 10

# *****************
#  wave_player_main
# *****************
template fbtn_next_song_on: untyped = fbtn_short_on
template fbtn_pause_on:     untyped = fbtn_long_on

proc wave_player_main*(){.inline.} =
    when HAVE_LED_IND_BLINK:
        var bTimeout_led: byte = 0
    var
        swBtnLowCount  :sword = 0
        fbtn_bit_prev  :sbit = true
        fbtn_short_on  :sbit = false
        fbtn_long_on   :sbit = false
        fbtn_pause_prev:sbit = false

    when HAVE_POWER_OFF_MODE:
        fbtn_long_on2 = false
        fbtn_power_off_on = fbtn_long_on2

    when HAVE_LED_IND_PWM:              #  pseudo PWM setting
        const
            IND_PERIOD         = 125.int8
            IND_DUTY_LOW_SPEED = 1.int8
            IND_DUTY_HI_SPEED  = 3.int8
        var
            sbIndDuty    = 0.int8
            sbIndCurrPos = 0.int8
            sbIndSpeed   = IND_DUTY_LOW_SPEED
            sbIndDelta   = sbIndSpeed

    while true:
        setTickCounter(10)              # ; set wait 10msec
        while getTickCounter() > 0:     # ; wait 10msec
            if ldwSongFileSectors == 0: # ; found end of file
                break                   # : promptly exit and prepare next song
            when HAVE_LED_IND_PWM:
                # ---------------------
                # pseudo PWM for LED
                # ---------------------
                if sbIndCurrPos < sbIndDuty: ind_on() else: ind_off()
                inc(sbIndCurrPos)
                if sbIndCurrPos == IND_PERIOD: sbIndCurrPos = 0

        # end while.  wait 10msec

        # ---------------------------------------------------
        # Start main process from here, called every 10msec.
        # ---------------------------------------------------

        # ------------------
        # Control from UART
        # ------------------
        var inChar = UART_getc().char
        case inChar:
            of 'n',' ':                     # Next song
                fbtn_next_song_on = true
            of 's','p',0x1b.char:           # Play pause (toggle)
                if fbtn_pause_on:
                    fbtn_pause_on = false
                    pwm_period_timer_music_start()
                else:
                    fbtn_pause_on = true
                    pwm_period_timer_music_stop()
            else:
                discard

        # ------------------
        # Next song and start
        # ------------------
        if (ldwSongFileSectors == 0) or fbtn_next_song_on:
            pwm_period_timer_music_stop()
            fbtn_next_song_on = false
            sd_stop_read()

            # ------------------
            # Search next song
            # ------------------
            searchNextFile()
            # Seek to Target file sector
            sd_start_read(gdwTargetFileSector)

            # ; delete about last 30Kbyte to cut tag data in *.wav file
            ldwSongFileSectors = (getBPB_FileSize() - CUT_LAST_TAG_NOISE.dword) shr 9

            when WPM_INFO:
                xprintf("\n    getBPB_FileSize() = %ld",getBPB_FileSize())
                xprintf("\n    ldwSongFileSectors = %ld",ldwsongFileSectors)

            # ------------------
            # Get wav header info
            # ------------------
            when READ_WAV_HEADER_INFO:
                sd_read_pulse_byte(22)         # pos(22) skip to channel info
                lbCh_mode = sd_data_byte()     # pos(23)
                sd_data_byte()                 # pos(24) skip to sampling freq.
                ldwSample_freq = sd_data_byte().dword + (sd_data_byte().dword shl 8) +
                                                        (sd_data_byte().dword shl 16) +
                                                        (sd_data_byte().dword shl 24) # pos(28)
                sd_read_pulse_byte(6)          # pos(34) skip to sample bits
                lbSample_bits = sd_data_byte() # pos(35)
                sd_read_pulse_byte(9)          # pos(44) skip to last position of header

                when WPM_INFO:
                    xprintf("\n    gCh_mod = %d, ldwSample_freq = %ld, lbSample_bits = %d",lbCh_mode ,ldwSample_freq,lbSample_bits)
            else:
                sd_read_pulse_byte(44)         # pos(44) just skip all wav header

            # ------------------
            # Set sampling frequency
            # ------------------
            setPwmPeriod(ldwSample_freq.int32)

            lwReadCount = wREAD_COUNT - bHEADER_COUNT
            # ------------------
            # Decide mode and initialize
            # ------------------
            if lbCh_mode == bCH_STEREO:
                if lbSample_bits == 16:
                    bMode = S16
                    lbReadCountS16 = (lwReadCount shr 2).uint8
                else: bMode = S8
            else:
                if lbSample_bits == 16: bMode = M16
                else: bMode = M8
            # ------------------
            # Music start
            # ------------------
            pwm_period_timer_music_start()

            when WPM_INFO:
                case bMode:
                    of S16:xprintf("\n    Stereo 16bit")
                    of S8: xprintf("\n    Stereo 8bit")
                    of M8: xprintf("\n    Mono 8bit")
                    else:discard
                xprintf("\n    Music start")

        # --------------------
        # LED indicator 1  --- pseudo PWM
        # ------------------*/
        when HAVE_LED_IND_PWM:
            sbIndDuty += sbIndDelta
            if sbIndDuty > IND_PERIOD: sbIndDelta = -1.int8 *% sbIndSpeed
            if sbIndDuty == 0:         sbIndDelta = sbIndSpeed
            sbIndSpeed = if fPlaying: IND_DUTY_LOW_SPEED else: IND_DUTY_HI_SPEED
        # -------------------
        # LED indicator 2 --- simple ON/OFF
        # -------------------
        when HAVE_LED_IND_BLINK:
            if bTimeout_led == 0:
                if fPlaying:
                    bTimeout_led = LED_PERIOD_PLAYNG      #  during Playing, on/off
                    ledToggle()
                else:
                    when HAVE_LED_IND_BLINK_PAUSE_INDICATOR:
                        bTimeout_led = LED_PERIOD_PAUSING #  during Pause, on/off
                        ledToggle()
                    else:
                        bTimeout_led = 1
                        ind_off()
            bTimeout_led = bTimeout_led - 1
        # -------------------
        #  button sw input
        # -------------------
        when HAVE_BUTTON_SW:
            let btn = btn_bit_now()
            if fbtn_bit_prev xor btn: # input from port by btn_bit_now()
                if btn: #  ; 0 --> 1: btn released
                    if (swBtnLowCount > 10) and (swBtnLowCount < 130): # 100msec < x < 1.3sec
                        fbtn_short_on = true
                    swBtnLowCount = 0
            fbtn_bit_prev = btn
            if btn == false:
                swBtnLowCount += 1
            if swBtnLowCount > 120: #   ; 1.2sec >
                fbtn_long_on = true
            when HAVE_POWER_OFF_MODE:
                if swBtnLowCount > 400: # ; 4sec >
                    # ; "long on2" is meaning go to sleep mode
                    fbtn_long_on2 = true
            # -------------------
            # Release Pause
            # -------------------
            if not fPlaying: # if during pause
                if fbtn_next_song_on:
                    pwm_period_timer_music_start()
                    fbtn_next_song_on = false
                    fbtn_pause_on = false
            # ------------------
            # Enter Pause
            # ------------------*/
            if fbtn_pause_prev xor fbtn_pause_on:
                if fbtn_pause_on:
                    pwm_period_timer_music_stop()
            fbtn_pause_prev = fbtn_pause_on

    # ; [forever loop end]
