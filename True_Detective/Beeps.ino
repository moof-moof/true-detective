/**                                                  Beeps.ino: Subfile to True_Detective_DRO.ino
__________________________________________________________________________________________________*/
 
 

/// =======  DRO beeps:  =======

void basic_beep(uint8_t dura) {
    digitalWrite(ACTV_PIEZO, HIGH); delay(dura);
    digitalWrite(ACTV_PIEZO, LOW); delay(dura);
}


void done_zeroing_beep(void) {
    basic_beep(30); basic_beep(30); 
}


/// =======  Spoke beeps:  =======

void beeeep()
{
    digitalWrite(ACTV_PIEZO, HIGH);
    beep_began = millis();
    beep_flag = true;
}

void bip()
{
    digitalWrite(ACTV_PIEZO, HIGH);
    bip_began = millis();
    bip_flag = true;
}


void attenzionePericolo()
{
    // at-ten-ZIO-ne
    digitalWrite(ACTV_PIEZO, HIGH);delay(30); digitalWrite(ACTV_PIEZO, LOW);delay(120);
    digitalWrite(ACTV_PIEZO, HIGH);delay(30); digitalWrite(ACTV_PIEZO, LOW);delay(120);
    digitalWrite(ACTV_PIEZO, HIGH);delay(250);digitalWrite(ACTV_PIEZO, LOW);delay(100);
    digitalWrite(ACTV_PIEZO, HIGH);delay(30); digitalWrite(ACTV_PIEZO, LOW);delay(250);
    // pe-ri-CO-lo
    digitalWrite(ACTV_PIEZO, HIGH);delay(30); digitalWrite(ACTV_PIEZO, LOW);delay(120);
    digitalWrite(ACTV_PIEZO, HIGH);delay(30); digitalWrite(ACTV_PIEZO, LOW);delay(120);
    digitalWrite(ACTV_PIEZO, HIGH);delay(350);digitalWrite(ACTV_PIEZO, LOW);delay(100);
    digitalWrite(ACTV_PIEZO, HIGH);delay(30); digitalWrite(ACTV_PIEZO, LOW);delay(1500);
}


void summerOfLove()
{
    digitalWrite(ACTV_PIEZO, HIGH);delay(50);digitalWrite(ACTV_PIEZO, LOW);delay(50);
    digitalWrite(ACTV_PIEZO, HIGH);delay(50);digitalWrite(ACTV_PIEZO, LOW);delay(50);
    digitalWrite(ACTV_PIEZO, HIGH);delay(75);digitalWrite(ACTV_PIEZO, LOW);
}


