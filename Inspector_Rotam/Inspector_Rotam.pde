 /**
 * Most code (other than the controlP5 library, Scott Lidgett's Graph class and J David Eisenberg's
 * dashed lines) is by Martin Bergman <bergman.martin at gmail dot com> 2016.
 * License: CC BY-SA v3.0 - http://creativecommons.org/licenses/by-sa/3.0/legalcode
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

 
import java.awt.Frame;
import java.awt.BorderLayout;
import processing.serial.*;
import controlP5.*;


/// ///////////////////////////////////////////////////////////////////////////////
/// 
///  Serial port to connect to:
        String serialPortName = "/dev/ttyACM3";
/// 
///  If you need to debug the plotter without using a real serial port set this to true:
        boolean simulateSerial = true;
///
/// ///////////////////////////////////////////////////////////////////////////////

/* Variables and constants declarations: */

color     bleakBlu        = color(216, 228, 248);         // Chart background colour
color     deadRed         = color(255, 0, 0);             // Graph (line) colour
color     cursedMist      = color(255, 255, 255, 56);     // Spoke "cursor" colour
color     spookyEmber     = color(255, 168, 0, 90);       // Alternative spoke cursor colour
float[]   lgValues        ;                               // Line graph values array
float[]   lgDataPoints    ;                               // Line graph data points array
byte[]    inBuffer        = new byte [40];                // Received (buffered) serial bytes
int       lgOffset        = 1000;                         // Static value for center correction
int       numberOfSpokes  ;                               // What it says on the label
int       spokeID         ;                               // Ordinal number of the present datapoint
int       xArg            = 35;                           // Upper-left corner of chart frame (x-pos)
int       yArg            = 25;                           // Upper-left corner of chart frame (y-pos)
int       wArg            = 950;                          // Width of chart frame
int       hArg            = 525;                          // Height of chart frame


/* Objects declarations: */

Serial      serialPort;                                   // Serial port object
JSONObject  plotterConfigJSON;                            // Settings file object
ControlP5   cp5;  RadioButton r1, r2;                     // GUI control objects
RotaGraph   RG = new RotaGraph(xArg, yArg, wArg, hArg, color(0)); // Plot object
PFont       mono;                                         // Monospaced font object



String getConfigString(String id) {                // Used for fetching persistent settings from file
    
    String s = "";
    try {
        s = plotterConfigJSON.getString(id);
    } 
    catch (Exception e) {
        s = "";
    }
    return s;
}

void setChartSettings(int NofS) {                   // Called in setup()
    
    RG.xLabel = " spoke# ";
    RG.yLabel = "          mm";
    if(!simulateSerial) {
        RG.Title = "Reading the \"True Detective\" serial stream!" ;
    }
    else {
        RG.Title = "Reading a simulated serial stream" ;
    }
    RG.yDiv = 10;                                   // Number of visible divisions on y-axis "ruler"
    RG.xDiv = NofS; 
    RG.xMax = NofS / 2; 
    RG.xMin = NofS /-2;
    RG.yMax = int(getConfigString("yRangeMax"));    //  250,  500  or  1000
    RG.yMin = RG.yMax * -1;                         // -250, -500  or -1000
    RG.BackgroundColor = bleakBlu;  
    RG.GraphColor      = deadRed;
    RG.SpokeColor      = color(192);
    RG.GraphWeight     = 1.5;
    RG.Font = loadFont("LucidaSans-12.vlw");        // Java/PFont default: Lucida Sans 12 pts
}

void updateChartSettings() {                        // Called only when y-range is changed
    
    RG.yMax = int(getConfigString("yRangeMax"));    //  250,  500  or  1000
    RG.yMin = RG.yMax * -1;                         // -250, -500  or -1000
}


void drawNums(String id, String val) {              // Displays spoke referenced values digitally
    
    fill(50);                                       // Dark grey background rectangles
    noStroke();
    rect(35, height -49, 24, 19); rect(61, height -49, 42, 19);
    
    fill(bleakBlu);
    textFont(mono); textAlign(RIGHT);               // Digits require a monospaced font
    text(id, 55, height -35); text(val, 98, height -35);
    textFont(RG.Font);                              // Restore default font for graph labels etc
}

void drawCursor(int id, int NofS) {
    stroke(cursedMist); strokeWeight(20);
//    stroke(spookyEmber); strokeWeight(20);
    line(float(id) / NofS  * wArg + xArg,  yArg + 8,          // Starting point of cursor bar
         float(id) / NofS  * wArg + xArg,  yArg + hArg - 7);  // End point
}

/// **************************************************************


void setup() {
    
    frame.setTitle("Inspector Rotam");
    size(1004, 580);                              // Maximum size for EeePC 900 screens (1024 x 600)

/* Load the settings save file: */
    plotterConfigJSON = loadJSONObject(sketchPath("config.json"));

/* Get the desired number of spokes, presumably pre-saved in the config file:  */
    numberOfSpokes = int(getConfigString("nOfSpokes"));

/* Else make a plausible assumption and save it "for the record" (as provisional default): */
    if((numberOfSpokes != 16) && (numberOfSpokes != 20) && (numberOfSpokes != 24)
     &&(numberOfSpokes != 28) && (numberOfSpokes != 32) && (numberOfSpokes != 36)
     &&(numberOfSpokes != 40) && (numberOfSpokes != 48)) {
        numberOfSpokes = 36;
        plotterConfigJSON.setString("nOfSpokes", "36");
        saveJSONObject(plotterConfigJSON, sketchPath("config.json"));
    }

/* Init chart: */
    setChartSettings(numberOfSpokes);

/* Create arrays of suitable (and equal) lengths for the values and the data points respectively: */
    lgValues =     new float[numberOfSpokes + 1];
    lgDataPoints = new float[numberOfSpokes + 1];

/* Fill up with initial values (zeroes) for the line graph: */
    for (int k = 0; k < (lgValues.length); k ++) {
        lgValues[k] = 0;
            
/* Fill the spoke reference static array with e.g. 37 consequtive "self-named" meta values 0-36: */
        lgDataPoints[k] = k;
    }

/* Init the radio buttons: */
    initRangeButtons();

/* Load the mono font */
    mono = loadFont("LiberationMono-Bold-14.vlw");
    
/* Start serial communication if possible: */
    if (!simulateSerial) {
        serialPort = new Serial(this, serialPortName, 57600);
    }
    else {
        serialPort = null;
    }
}


/// **************************************************************


void draw() {
    
    String[] nums = {"", ""};                                   // Stores the two input string parts
    
/* Read serial input and update the values accordingly */
    if (simulateSerial || serialPort.available() > 0) {
        String rxString = "";
        String trmRxString = "";
        if (!simulateSerial) {
            try {
                serialPort.readBytesUntil('\r', inBuffer);
            }
            catch (Exception e) {
                println("Exception :e[");                       // This is rare, fortunately
            }
            rxString = new String(inBuffer);

/* Snip off any trailing spaces and such  */
            trmRxString = trim(rxString);
            
/* Make sure string has only 1-2 digits, a comma and then 1-4 digits. If not — neutralise it:  */
            if (!trmRxString.matches("\\d{1,2},\\d{1,4}")) {
                trmRxString = "0,1000";                  // 1000 'cause that's our temporary offset
                println("Foul data: "+ rxString);
            }
        }
        else {
            trmRxString = trim(SerialSimulator(numberOfSpokes)); // Using phoney values instead.
        }
        
//        println(trmRxString);                                 /// just for debugging

/* Split the string into a two-part array at the comma delimiter: */      
        nums = splitTokens(trmRxString, ",");                   /// should we use split() instead?

        spokeID = Integer.parseInt(nums[0]);                // Spoke count maps directly to "ID"
        
/* Translate (rotate) the spoke numbers by 180° to fit the chart layout:  */
        if (spokeID > numberOfSpokes/2) {spokeID -= numberOfSpokes/2;}
        else                            {spokeID += numberOfSpokes/2;}

// Filter 1:
/* Is value within the maximal y-range of 0-2000 (that is: +/-10mm)?  Otherwise set it to 0: */
        if (float(nums[1]) < 0 || float(nums[1]) > 2000){
            lgValues[spokeID] = 0;
            println("Out-of-range!");
        }

// Filter 2:
/* Compare new value vs old value for this ID, for suspected glitches (jumps greater than 1mm) */
        else if (abs(lgOffset - float(nums[1])) - (lgOffset - lgValues[spokeID]) > 100) {
            lgValues[spokeID] = lgValues[spokeID];      // if test fail: use old value
        }   /// This works better, but still lets thru some really off values
//      else if ( jfr med snittet av de närmaste två ekrarna: Är hoppet stort för denna eker?)
        
/* Update the graph value: (Corresponding spoke array item receives latest multiplied value) */
        else {
            lgValues[spokeID] = (float(nums[1])) - lgOffset;
        }

/* Since first spoke in graph is also the last their values must always be equal: */
        if (lgValues[0] != lgValues[lgValues.length - 1]){
            lgValues[0]  = lgValues[lgValues.length - 1];
        }
    }

/* Draw everything to screen:  */
    RG.DrawAxis();
    drawCursor(spokeID, numberOfSpokes);
    RG.LineGraph(lgDataPoints, lgValues);
    
    drawNums(nums[0], nums[1]);

    if (simulateSerial) {delay(150);}
}

