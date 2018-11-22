 /**
 *
 * Most code by Martin Bergman <bergman.martin at gmail dot com> 2016.
 * License: CC BY-SA v3.0 - http://creativecommons.org/licenses/by-sa/3.0/legalcode
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * For performance reasons and simplicity's sake, we avoid having to handle negative gauge values.
 * For starters we can comfortably really only save and read the last 15 bits of each packet (out of
 * a possible 24), so all those significant left-most bits characteristic of negative values (coded
 * as two's complement) would be lost.
 *
 * (Also, the tools maximum measurement is "3176"(31.76mm), which requires only 12 bits anyway)
 *
 * A simpler, more practical solution is to physically adjust the lateral position of the indicator 
 * plunger only _after_ the DRO has been automatically zeroed on each system start-up. This way a 
 * suitably high random positive value can be selected as datum.
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "SPI.h"

#define  CLK_PIN       2    // DRO clock line (amplified) on MEGA 2560 digital pin D2 (INT0)
#define  PHOTO_TRANS   3    // IR phototransistor detector on digital pin D3 (INT1)
#define  DAT_PIN       5    // DRO data line (amplified) on digital pin D5
#define  TICK_PIN     10    // Button to reset spoke enumeration and "tick marker" on digital pin D10.
#define  DP1          30    // DIP switch defines:  16 spokes
#define  DP2          32    //                      20 spokes
#define  DP3          34    //                      24 spokes
#define  DP4          36    //                      28 spokes
#define  DP5          38    //                      32 spokes
#define  DP6          40    //                      36 spokes
#define  DP7          42    //                      40 spokes
#define  DP8          44    //                      48 spokes
#define  ACTV_PIEZO   54    // MEGA 2560 analogue pin A0, a.k.a. D54: the (G)rim Beeper.
#define  OPTO_C_PIN   64    // MEGA 2560 analogue pin A10
#define  MAXJUMP      50    // Value must accomodate fluctuating, yet legitimate measurements @ 3Hz

#define  PIN_MOUSECAM_RST                 29    // Optical flow sensor (mouse cam) reset
#define  PIN_MOUSECAM_NCS                 25    // Optical flow sensor (mouse cam) chip select
#define  PIN_MISO                         50    // MEGA hardware SPI pins: SS, MOSI, MISO, SCK
#define  PIN_MOSI                         51
#define  PIN_SCLK                         52
#define  PIN_SS                           53    
#define  ADNS3080_PIXELS_X                30    // Mouse cam image width (pixels)
#define  ADNS3080_PIXELS_Y                30    // Mouse cam image height (pixels)
#define  ADNS3080_PRODUCT_ID            0x00
#define  ADNS3080_CONFIGURATION_BITS    0x0a
#define  ADNS3080_MOTION_BURST          0x50
#define  ADNS3080_PRODUCT_ID_VAL        0x17


volatile uint8_t    gogo        = 0;        // Flag (for new complete mesurement data sample)
         uint16_t   value       = 0;        // Input packet accumulator variable
volatile int16_t    final_value = 0;        // Ditto when ready for output
         uint16_t   nrml_value  = 0;        // Ad-hoc normalised value with added positive offset
         uint16_t   bits_so_far, prev_value = 0;
         uint8_t    skipped     = 0;        // Flag (for glitch filter tracking)
         uint32_t   latest_interrupt;
         uint16_t   slow_step   = 500;      // Adjust this by trial-and-error for a reliable setup
volatile uint32_t   beep_began;
volatile uint32_t   bip_began;
volatile boolean    beep_flag   = false;    // Flag for the speeding alarm
volatile boolean    pending     = false;
volatile boolean    bip_flag    = false;    // Flag for the spoke-marker "tick"
volatile boolean    spoke_ping  = false;    // Flag announcing detection of a passing spoke
         uint8_t    spoke_count = 0;        // Cardinal number of spokes in the examined wheel
         int8_t     cnt         = 0;        // Present ordinal number in the running spoke count 
volatile uint32_t   prev_ping;
volatile uint32_t   delta_ping;             // Time diff between current ping interrupt and prev_ping
const    uint8_t    max_spin    = 24;       // Ping interval (ms) at the maximum reliable ¬
                                            //... rotational speed of 1/max_spin spokes/second (sps)
         int8_t     now_dir    = 0;         // Variables used to provide a sense of direction
         int8_t     latest_dir = 0;

struct MB {                                 // Collection of "motion burst" mode data
    uint8_t  motion;
    int8_t   dx, dy;                        // Delta X (dx) is actually all that we want in here...
    uint8_t  squal;
    uint16_t shutter;
    uint8_t  max_pix;
};

/// _____________________________________________________________________________________________


void setup()
{
    pinMode(CLK_PIN, INPUT);        // Clock signal = D2 (PE4, INT0)(actually INT4...)
    pinMode(DAT_PIN, INPUT);        // Data signal  = D5 (PE3)
    pinMode(OPTO_C_PIN, OUTPUT);    // Optocoupler input for raising signal on CLK line = A10 (PK2)
    pinMode(TICK_PIN, INPUT_PULLUP);
    pinMode(DP1, INPUT_PULLUP);
    pinMode(DP2, INPUT_PULLUP);
    pinMode(DP3, INPUT_PULLUP);
    pinMode(DP4, INPUT_PULLUP);
    pinMode(DP5, INPUT_PULLUP);
    pinMode(DP6, INPUT_PULLUP);
    pinMode(DP7, INPUT_PULLUP);
    pinMode(DP8, INPUT_PULLUP);
    pinMode(PIN_SS,   OUTPUT);      // SPI library requires SS to be OUTPUT, even if pin isn't used!
    pinMode(PIN_MISO,  INPUT);
    pinMode(PIN_MOSI, OUTPUT);
    pinMode(PIN_SCLK, OUTPUT);
    
    pinMode(PHOTO_TRANS, INPUT);    // Pullup is not set until after initial detection test below
    pinMode(ACTV_PIEZO, OUTPUT);    // Beeper/Buzzer/Summer (active piezo element) = A0
    digitalWrite(ACTV_PIEZO, LOW);
    


    basic_beep(150);                // (Cold-starting with caliper attached is _awfully_ slow; ¬
                                    // ... takes about 10 seconds just to come this far!)
    delay(slow_step);
    zeroOptoPulse(slow_step);       // The "electrically safer" version of zeroPulse() via optocoupler.
                 // (Initial use of this func makes sure the DRO measurement output starts at zero.)
    done_zeroing_beep();

    SPI.begin();
    SPI.setClockDivider(SPI_CLOCK_DIV32);
    SPI.setDataMode(SPI_MODE3);
    SPI.setBitOrder(MSBFIRST);

    mousecamInit();

    spoke_count = demandedNumberOfSpokes();

    Serial.begin(57600);

//    verboseSerialMasthead();          // Hide metadata from the Inspector, it confuses him so...

    pinMode(PHOTO_TRANS, INPUT_PULLUP); // Pullup to avoid triggering from "near-shield" inductance.

    attachInterrupt(0, cccClk, FALLING);// INT0 maps to pin D2 here, actually called INT4 on the MEGA
    attachInterrupt(1, spokeUp, RISING);// INT1 maps to pin D3 here, actually called INT5 on the MEGA

    summerOfLove();                     // Setup finished!;
}

/// _____________________________________________________________________________________________


void loop()
{
    checkAudioSignalFlags();                // Time to muffle the beeper?
    
    if (!digitalRead(TICK_PIN)) {           // A button push to GND restarts spoke count
        cnt = 0;
        nrml_value = prev_value + 1000;     // Set normal value (for calibration use, final_value may be 0)
        bip();  
    }

    if (spoke_ping) {                       // There goes another spoke!
/**
    The spokeUp() interrupt has possibly interfered with an ADNS-3080 "burst" transmission: \
    We've better reset the SPI serial timing, just in case: 
        digitalWrite(PIN_MOUSECAM_NCS, 1);  // Raise Chip Select pin to abort burst mode
        delayMicroseconds(5);               // Wait > 4uS (t_BEXIT).
 */

        feelTheFlow();                      // Read the ADSN-3080 optical flow sensor

        cnt += now_dir;                     // Add 1 spoke with the sign for now_dir. Note that ¬
                                            // ... direction needs to be "primed" when tick-starting.
        if(cnt > spoke_count){              // A full progressive revolution resets the counter:
            cnt = 1;                        // Let's call the first spoke #1, not #0, okay?
            bip();                          // Piezo "tick" for aural feedback.
        }
        if(cnt <= 0){                       // A complete counter-revolution "upsets" the Count :)
            cnt = spoke_count;              // Reversing and decrementing past spoke #1 simply ¬
                                            // ... ups the count to the maximum spoke number.
            bip();                          // Piezo "tick" for aural feedback.
        }
        if (gogo){                          // A new DRO packet has been flagged already!
            filters();                      // Weeding out any flagrant glitches first

            prev_value = final_value;       // Prepare next-round filter
            
            final_value = nrml_value - final_value;
            Serial.print(cnt - 1);          // Print the spoke number zero-based for Inspector Rotam
            Serial.print(',');              // Print the delimeter
            Serial.println(final_value);    // Print the normalised measurement
            
            final_value = 0;                // Tidy up again
            gogo = 0;                       // Here we gogo... not
        }
        else {                              // If no new DRO value yet. (This oughtn't happen often)
            Serial.print(cnt - 1);          // Print the spoke number zero-based for the Inspector
            Serial.print(',');              // Print the delimeter
            Serial.println(prev_value);     // Substitute what we had last
        }
        spoke_ping = false;                 // No ping -- no play.
    }
}


void verboseSerialMasthead()                // Don't call this unless debugging.
{
    Serial.print("\n   Starting! \n   ---------\n   spoke_count: \"");
    Serial.print((spoke_count), DEC); Serial.println("\" was selected");
    Serial.print("   max_spin:     "); Serial.print((max_spin), DEC); Serial.println("  milliseconds");
    delay(500);

    if(digitalRead(PHOTO_TRANS)){
        Serial.println("\n > Laser beam detected! <");
    }
    else {
        Serial.println("\n >>>>>>>>>> NO LASER FOUND <<<<<<<<<<");
    }

    if(mousecamInit() == -1) {
        Serial.println("\n   Mouse cam has failed to init!\n   *****************************\n\n");
    }
}
