/**                                        CCC_2x24bit_DRO.ino: Subfile to True_Detective_DRO.ino
__________________________________________________________________________________________________*/
/**
*      Relevant "bits" of the MEGA's peculiar pin-to-register mapping (for reference):
*      Register bit :   7   6   5   4   3   2   1   0
*      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*      Port B       :  13  12  11  10  50  51  52  53
*      Port D       :  38              18  19  20  21     
*      Port E       :   *   *   3   2   5   ?   1   0
*      Port G       :           4          39  40  41
*      Port H       :       9   8   7   6      16  17
*      Port J       :                          14  15
*      ----------------------------------------------
* 
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* ABOUT THE 2x24bit PROTOCOL
* ~~~~~~~~~~~~~~~~~~~~~~~~~~
* There are several different data protocols used for digital calipers and scales. Common ones are
* "7x4bit", "6x4bit" (aka bin6), "BCD" (Binary Coded Digital), and "Digimatic" (Mitutoyo proprietary).

* This sketch, however, is designed to read a "Digital Indicator with Data Output Port" [BG Micro
* Electronics Part Number TOL1049]. This particular unbranded device uses what is usually referred to
* as either the Sylvac (for historical reasons) or "Cheap Chinese Caliper" protocol. However, a tech-
* nically more relevant name is 2x24bit, since it is characterized by data packets comprising two 24
* bit strings in succession, differing in content only by how the datum (zero-point) is defined.

* In terms of update rate this device has two possible modes: normal and fast. In the default NORMAL
* mode the transmission of each packet repeats at circa 3 Hz, but the actual continuous "data burst"
* time for the 48 bits (plus extra long start/stopbits) is less than a single mS, meaning that only
* about 0.3 % of the µC's processing time is spent sending these packets. Each of the data bits need
* just 13 μS, which  translates to a data speed of circa 77 kHz.  In the FAST reading mode the data
* bursts repeat every 20 milliseconds (50 Hz). With the clock speed  being the same as in the default
* mode, the percentage of time spent transmitting increases to 4.5 %.

* In the present application we are only interested in reading the value contained in the second data
* bit string. This is at once LSB-first (i.e."reverse ordered") and inverted (1's are LOW, 0's HIGH).
* 
* As the device has nominally 1v5 output, its signal is passed through a suitable comparator op-amp.
* 
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */



void zeroOptoPulse(uint16_t duration) {
    
    // Raise the C-line via the optocoupler:
    digitalWrite(OPTO_C_PIN, HIGH);
    // Hold the line HIGH for a while (For how many milliseconds minimum must we keep it up?):
    delay(duration);
    // Now turn it off again:
    digitalWrite(OPTO_C_PIN, LOW);
    // Halt here to really get across that we're closed now:
    delay(duration);
}


void filters(void) {
    
    int16_t nextStep = 0;

/// VALUES FOR TEST DRO #1 
    if(prev_value == 0){
        if((final_value ==   80) ||             // Catch most common rest-state glitches first
           (final_value ==  256) ||
           (final_value ==  336) ||
           (final_value == 2112) ||
           (final_value == 2048) ||
           (final_value == 2348) ||
           (final_value == 2368) ||
           (final_value == 2384) ){
            final_value = 0;                    // Simply nullify these (Eekh...ugly "solution"!)
        }
    }
/** VALUES FOR TEST DRO #2 ("red ring")
    if(prev_value == 0){
        if((final_value == 256) ||
           (final_value == 264) ||
           (final_value == 265) ){
            final_value = 0;
        }
    }     */

    if(final_value > 3200) {                        // Implicating a general rollover (negative) value
        final_value = 0;                            // Simply hide negative values for now
    }

    nextStep = int16_t(final_value - prev_value);   // Value volatility check
    
    if ((!skipped) && (abs(nextStep) > MAXJUMP)){   // Previous packet's value was deemed legit, but not this.
        skipped = 1;                                // Note-to-ourselves: Skipped the received value this time
        final_value = prev_value;                   // Substitute latest known-good value
    }
    else {              // If we have come down here we should have checked the obvious glitches, ...
        skipped = 0;    // ... and so we accept the latest proposed value by clearing the skipped-flag
    }
}


void cccClk(void) {     // This ISR enjoys marching to the beat of the "Cheap Chinese Calipers" clock!

    uint8_t data = 0;                   // First things first: Grab the present data bit
    if(PINE & B00001000){ data = 1;}    // Mask port E bit 3 (pin D5): Is it True yet? ...
                                        // ... If it isn't: "Move on! Nothing-to-see-here"
    uint32_t now = millis();            // Time-stamp

    if((now - latest_interrupt) > 5){   // This should be sufficient to distinguish arrival of a new packet
        final_value = value;            // Hand off pending measurement data to the main loop
        gogo = 1;                       // Come-and-get-it!
        value = 0;                      // Purge all them old bits in preparation for a new packet
        bits_so_far = 0;                // Reset tick-tock counter (it will increment instantly anyway)
    }
    else {
        if (bits_so_far > 23 && bits_so_far < 42 ){ // Want the first 15 of the latter 24 reversed order bits
            if (data == 0){          // if DAT_PIN is LOW we record a HIGH (for an immediate inversion) ...
                value |= 0x8000;     // ... by setting the most significant bit ...
            }
        value = value >> 1;          // ... and right-shifting each pass, reversing bit order to MSB-first.
        }
    }
    bits_so_far++;
    latest_interrupt = now;          // latest yeah.. but probably not the last!
}

