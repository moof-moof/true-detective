

void initRangeButtons() {

    cp5 = new ControlP5(this);
    
    r1 = cp5.addRadioButton("yRangeMax")
        .setPosition(50, 8)
        .setSize(10, 10)
        .setColorForeground(color(140))          // Grey value when pointed at
        .setColorBackground(color(245))          // Off-white when not pointed at, or not set
        .setColorActive(color(0))                // Black when set
        .setColorLabel(color(0))                 // Label text colour
        .setItemsPerRow(3)
        .setSpacingColumn(24)
        
        .addItem("5", 250)
        .addItem("10", 500)
        .addItem("20 mm", 1000);
        
    for(Toggle t:r1.getItems()) {
        t.getCaptionLabel().setColorBackground(color(bleakBlu)); // Label bkgrnd
        t.getCaptionLabel().getStyle().moveMargin(-4, 0,   0,-3);
        t.getCaptionLabel().getStyle().movePadding(4, 0,   0, 3);
        t.getCaptionLabel().getStyle().backgroundWidth = 24;
        t.getCaptionLabel().getStyle().backgroundHeight = 11;
    }
     
    r2 = cp5.addRadioButton("nOfSpokes")
        .setPosition(700, 8)
        .setSize(10, 10)
        .setColorForeground(color(140))          // Grey value when pointed at
        .setColorBackground(color(245))          // Off-white when not pointed at, or not set
        .setColorActive(color(0))                // Black when selected/set
        .setColorLabel(color(0))                 // Label text colour
        .setItemsPerRow(8)
        .setSpacingColumn(24)
        
        .addItem("16", 16)
        .addItem("20", 20)
        .addItem("24", 24)
        .addItem("28", 28)
        .addItem("32", 32)
        .addItem("36", 36)
        .addItem("40", 40)
        .addItem("48 spks", 48);
     
    for(Toggle t:r2.getItems()) {
        t.getCaptionLabel().setColorBackground(color (bleakBlu)); // Label bkgrnd
        t.getCaptionLabel().getStyle().moveMargin(-4, 0,   0,-3);
        t.getCaptionLabel().getStyle().movePadding(4, 0,   0, 3);
        t.getCaptionLabel().getStyle().backgroundWidth = 24;
        t.getCaptionLabel().getStyle().backgroundHeight = 11;
    }

    int ymax = Integer.parseInt(getConfigString("yRangeMax"));

    if(ymax == 250 || ymax == 500 || ymax == 1000) {
        switch(ymax) {
            case(250):  r1.activate(0); break;
            case(500):  r1.activate(1); break;
            case(1000): r1.activate(2); break;
        }
    }
    else r1.activate(2);                                // defaults to 20 mm span deflection scale
    
    int spks = Integer.parseInt(getConfigString("nOfSpokes"));

    switch(spks) {
        case(16): r2.activate(0); break;
        case(20): r2.activate(1); break;
        case(24): r2.activate(2); break;
        case(28): r2.activate(3); break;
        case(32): r2.activate(4); break;
        case(36): r2.activate(5); break;
        case(40): r2.activate(6); break;
        case(48): r2.activate(7); break;
    }
}


void keyPressed() {
    switch(key) {
        case('0'): r1.deactivateAll(); r2.deactivateAll(); break;
        case('1'): r1.activate(0); break;
        case('2'): r1.activate(1); break;
        case('3'): r1.activate(2); break;
    }
}


void controlEvent(ControlEvent theEvent) {
    
    if(theEvent.isFrom(r1)) {
        String parameter = theEvent.getName();
        String value = int(theEvent.getValue()) + "";
        plotterConfigJSON.setString(parameter, value);
        saveJSONObject(plotterConfigJSON, sketchPath("config.json"));
    }
    updateChartSettings();
        
    if(theEvent.isFrom(r2)) {
        String parameter = theEvent.getName();
        String value = int(theEvent.getValue()) + "";
        plotterConfigJSON.setString(parameter, value);
        saveJSONObject(plotterConfigJSON, sketchPath("config.json"));
    }
}
