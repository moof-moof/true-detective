/**                                           Optical_flow.ino: Subfile to True_Detective_DRO.ino
__________________________________________________________________________________________________*/
 

void feelTheFlow() {
    
    MB mb;
    mousecamReadMotion(&mb);
    
    int8_t dir = (int8_t)mb.dx;             // Fetch a new displacement value

    if      (dir > 0)  dir =  1;            // Rotating "forwards"
    else if (dir < 0)  dir = -1;            // Rotating "backwards"
    else               dir =  0;            // Zero movement

    now_dir = dir;
}


/// ***************************************************************************************
///     SPI routines for the ADNS-3080 optical flow "mousecam" sensor:
/// ***************************************************************************************


void mousecamReset() {
    
    digitalWrite(PIN_MOUSECAM_RST,HIGH);
    delay(1);                                                   // reset pulse >10us
    digitalWrite(PIN_MOUSECAM_RST,LOW);
    delay(35);                                                  // 35ms from reset to functional
}


int mousecamInit() {
    
    pinMode(PIN_MOUSECAM_RST,OUTPUT);
    pinMode(PIN_MOUSECAM_NCS,OUTPUT);
    
    digitalWrite(PIN_MOUSECAM_NCS,HIGH);
    mousecamReset();
    
    int pid = mousecamReadReg(ADNS3080_PRODUCT_ID);
    if(pid != ADNS3080_PRODUCT_ID_VAL)   return -1;
    
    mousecamWriteReg(ADNS3080_CONFIGURATION_BITS, 0x19);      // turn on sensitive mode
    return 0;
}


void mousecamWriteReg(int reg, int val) {
    
    digitalWrite(PIN_MOUSECAM_NCS, LOW);
    SPI.transfer(reg | 0x80);
    SPI.transfer(val);
    digitalWrite(PIN_MOUSECAM_NCS,HIGH);
    delayMicroseconds(50);
}


int mousecamReadReg(int reg) {
    
    digitalWrite(PIN_MOUSECAM_NCS, LOW);
    SPI.transfer(reg);
    delayMicroseconds(75);
    int ret = SPI.transfer(0xff);
    digitalWrite(PIN_MOUSECAM_NCS,HIGH); 
    delayMicroseconds(1);
    return ret;
}


void mousecamReadMotion(struct MB *p) {

    digitalWrite(PIN_MOUSECAM_NCS, LOW);
    SPI.transfer(ADNS3080_MOTION_BURST);        // Burst mode reg adress
    delayMicroseconds(75);                      // Wait for t_SRAD-MOT, then read without delay
    p->motion =   SPI.transfer(0xff);
    p->dx =       SPI.transfer(0xff);
    p->dy =       SPI.transfer(0xff);
    p->squal =    SPI.transfer(0xff);
    p->shutter =  SPI.transfer(0xff)<<8;
    p->shutter |= SPI.transfer(0xff);
    p->max_pix =  SPI.transfer(0xff);
    digitalWrite(PIN_MOUSECAM_NCS,HIGH);        // Raise CS to stop burst mode
    delayMicroseconds(5);                       // Wait for at least t_BEXIT
}
