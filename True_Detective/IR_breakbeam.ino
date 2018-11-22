/**                                           IR_breakbeam.ino: Subfile to True_Detective_DRO.ino
__________________________________________________________________________________________________*/


void spokeUp() { // This ISR runs when IR phototransistor state goes from LOW to HIGH (the trailing edge)

    uint32_t this_ping = millis();
    delta_ping = this_ping - prev_ping;
    
    if(delta_ping > max_spin){              // If spinning slower than max spokes/s: increment counter

        prev_ping = this_ping;
        pending = false;                    // Potential speeding ticket is now reprieved
        spoke_ping = true;                  // Hoist the new-spoke flag
    }
    else {                                  // Spinning too fast, dammit!
        if(delta_ping > (max_spin / 2)){    // (Faster than max_spin and) slower than twice the max
            if (pending){                   // Okay, presume this is for real
                beeeep();    // Speeding alert: No counting while detection is possibly not stable
                Serial.println("  xxx");
                pending = false;            // Clear the violation record for now
            }
            else {pending = true;}          // Note a first violation. It still may be false alarm.
        }
        prev_ping = this_ping;
    }      // Assuming anything faster than twice the max_spin may be jitter/noise: just ignore it
}


uint8_t demandedNumberOfSpokes() {    // Read the DIP array for selection of number of spokes in wheel

         if(digitalRead(DP1) == LOW) return 16;
    else if(digitalRead(DP2) == LOW) return 20;
    else if(digitalRead(DP3) == LOW) return 24;
    else if(digitalRead(DP4) == LOW) return 28;
    else if(digitalRead(DP5) == LOW) return 32;
    else if(digitalRead(DP6) == LOW) return 36;
    else if(digitalRead(DP7) == LOW) return 40;
    else if(digitalRead(DP8) == LOW) return 48;
    else {
        attenzionePericolo();       // Audio alert: No spoke count value has been explicitly selected
        Serial.print("DEFAULTS! ");
        return 36;                  // Defaults to 36 spokes
    }
}


void checkAudioSignalFlags() {
    
    if(beep_flag && (millis() - beep_began) > 200){ // Time to turn off the speed warning "beeeep"?
        digitalWrite(ACTV_PIEZO, LOW);
        beep_flag = false;
    }

    if(bip_flag && (millis() - bip_began) > 20){    // Time to turn off the spoke-marker "tick"?
        digitalWrite(ACTV_PIEZO, LOW);
        bip_flag = false;;
    }
}
