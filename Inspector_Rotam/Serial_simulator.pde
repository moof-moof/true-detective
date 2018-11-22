///   ///////////////////////////////////////////////////////////////////////////
///   ////  For when debugging the plotter without using a real serial port  ////
///   ///////////////////////////////////////////////////////////////////////////


byte  cnt   = 0;
int   rumba = 0;
int   trend = 1;
int[] rw8   = new int[numberOfSpokes];       // "Wobble-eight" array for simulator

void ramble(){
    rumba += trend;
    if      (rumba >  11) trend = -1;
    else if (rumba < -11) trend =  1;
}


int rimWobble8_32[] = {     // Sinusoidal data table: 32 points, -100/+100 amplitude,  720* angle
     0, 38, 71, 92, 100, 92, 71, 38,
     0, -38, -71, -92, -100, -92, -71, -38,
     0, 38, 71, 92, 100, 92, 71, 38,
     0, -38, -71, -92, -100, -92, -71, -38
};

int rimWobble8_36[] = {     // Sinusoidal data table: 36 points, -100/+100 amplitude,  720* angle
    0, 34, 64, 87, 98, 98, 87, 64, 34,
    0, -34, -64, -87, -98, -98, -87, -64, -34,
    0, 34, 64, 87, 98, 98, 87, 64, 34,
    0, -34, -64, -87, -98, -98, -87, -64, -34
};

int rimWobble8_40[] = {     // Sinusoidal data table: 40 points, -100/+100 amplitude,  720* angle
    0, 31, 59, 81, 95, 100, 95, 81, 59, 31,
    0, -31, -59, -81, -95, -100, -95, -81, -59, -31,
    0, 31, 59, 81, 95, 100, 95, 81, 59, 31,
    0, -31, -59, -81, -95, -100, -95, -81, -59, -31
};


String SerialSimulator(int sp) {

    switch(sp) {
        case(16): ; break;
        case(20): ; break;
        case(24): ; break;
        case(28): ; break;
        case(32): rw8 = rimWobble8_32; break;
        case(36): rw8 = rimWobble8_36; break;
        case(40): rw8 = rimWobble8_40; break;
        case(48): ; break;
    }

    if (cnt == rw8.length){           // if cnt is maxed already ... rebase
        cnt = 0;
    }

    String rx = "";
    rx = cnt + "," + ((rw8[cnt]+1000) + rumba) + '\r';
    
    cnt  ++;                          // increment counter
    ramble();
    delay(20);

    return rx;
}
