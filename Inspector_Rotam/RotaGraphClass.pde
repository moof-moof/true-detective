/**=========================================================================================     
 *    The RotaGraph class contains functions and variables for displaying linear graphs,
 *    and basically comprises a reduced set of features from Scott Lidgett's Graph class.
 *    
 *     A list of functions within this derived class:   
 *       Graph(int x, int y, int w, int h, color k)
 *       DrawAxis()
 *       LineGraph([][]) 
 *
 *     Added dashed lines functions by J David Eisenberg:
 *       dashline()
 *
 *=========================================================================================*/   


class RotaGraph 
{
    boolean Dot = true;            // Draw dots at each data point if true
    boolean RightAxis;             // Draw the next graph using the right axis if true
    boolean ErrorFlag = false;     // If the time array isn't in ascending order, make true  
    boolean ShowMouseLines = true; // Draw lines and give values of the mouse position
    
    int     xDiv = 5, yDiv = 5;    // Number of sub divisions (defaults). Corrected in setup()
    int     xPos, yPos;            // Location of the top left corner of the graph  
    int     Width, Height;         // Width and height of the graph
    

    color   GraphColor;
    color   BackgroundColor;  
    color   SpokeColor;

    String  Title = "Title";        // Default titles
    String  xLabel = "x - Label";
    String  yLabel = "y - Label";
    
    float   yMax = 1024, yMin = 0;  // Default axis dimensions
    float   xMax = 10, xMin = 0;
    float   yMaxRight = 1024, yMinRight = 0;
    float   GraphWeight = 1;

    PFont   Font;                   // Selected font used for text 
    
    RotaGraph(int x, int y, int w, int h, color k) {    // The main declaration function
        xPos = x;
        yPos = y;
        Width = w;
        Height = h;
        GraphColor = k;
    }

/*  ==========================================================================================
    Main axes Lines, Graph Labels, Graph Background
    ==========================================================================================  */
    void DrawAxis(){
        
        fill(BackgroundColor); color(0); stroke(BackgroundColor); strokeWeight(1);
        int t = 28;
        rect(xPos - t * 1.6, yPos-t,  Width + t * 2.5, Height + t * 2);// Outline
        textAlign(CENTER); textSize(12);
        
        float c = textWidth(Title);
        fill(BackgroundColor); color(0); stroke(0); strokeWeight(1);
        rect(xPos + Width / 2 - c / 2, yPos -35, c, 0);                  // Heading Rectangle  
        
        fill(0);
        text(Title, xPos + Width/2, yPos - 7);                        // Heading Title
        textAlign(CENTER); textSize(12);
        text(xLabel, xPos + Width/2, yPos + Height + 25);            // x-axis Label 
        
        rotate(-PI/2);                                               // Rotate -90 degrees
        text(yLabel, -yPos - Height / 2, xPos - t * 1.6 + 20);       // y-axis Label  
        rotate(PI/2);                                                // Rotate back
        
        textSize(10); noFill(); stroke(0); smooth();strokeWeight(1);


        line(xPos,          yPos + Height,
             xPos,          yPos);                                   // y-axis line
             
        line(xPos,          yPos + Height,
             xPos + Width + 2,  yPos + Height);                      // x-axis line 
        
        stroke(0); strokeWeight(1.5);
        if(yMin < 0){                                                // zero value line
            line(xPos - 7,
                 yPos + Height -(abs(yMin) / (yMax - yMin)) * Height, 
                 xPos + Width + 2,
                 yPos + Height -(abs(yMin) / (yMax - yMin)) * Height);
        }
        
        if(RightAxis){                                               // Right-axis line   
            stroke(0); strokeWeight(1);
            line(xPos + Width + 3, yPos + Height, xPos + Width + 3, yPos);
        }

/*  ==========================================================================================
    Sub-divisions for both axes:
    x-axis
    ==========================================================================================  */ 
        for(int x = 0; x <= xDiv; x++){
            stroke(SpokeColor); strokeWeight(1);
            dashline(float(x) / xDiv * Width + xPos, yPos,              //  x-axis subdivisions  
                     float(x) / xDiv * Width + xPos, yPos + Height - 2,
                     4, 3);                                             // Full height "spoke bars"

            stroke(0); strokeWeight(1);
            line(float(x) / xDiv * Width + xPos, yPos + Height,         // x-axis "ruler score marks"
                 float(x) / xDiv * Width + xPos, yPos + Height + 5);
                   
            strokeWeight(1); textSize(10);                              // x-axis Labels
            String xAxis = str(xMin + float(x)/ xDiv * (xMax - xMin));  // splitting floats into strings
            String[] xAxisMS = split(xAxis,'.');                        // skipping the decimals 
            text(xAxisMS[0], float(x)/ xDiv * Width + xPos, yPos + Height + 15); // x-axis integer labels
        }

        stroke(64); strokeWeight(2);                                    // Zero-spoke marker
        line(float(xPos + Width / 2), yPos + 1,  
             float(xPos + Width / 2), yPos + Height - 1);

        
/*  =========================================================================================
    y-axis (left side)
    ==========================================================================================  */
        stroke(0); strokeWeight(1);
        
        for(int y = 0; y <= yDiv; y++){
            line(xPos, float(y) / yDiv * Height + yPos,                 // y-axis "ruler" subdivisions
                 xPos - 7, float(y) / yDiv * Height + yPos); 

            textAlign(RIGHT); fill(20);
            String yAxis = str((yMin + float(y)/ yDiv * (yMax - yMin))/100);// Make the y-label a string
            String[] yAxisMS = split(yAxis,'.');                        // Split string on decimal point
            
            text(yAxisMS[0] + "." + yAxisMS[1].charAt(0),
                 xPos - 8, float(yDiv - y)/ yDiv * Height + yPos + 3); // y-axis labels 
                        
            stroke(0);
            line(xPos, yPos,  xPos, yPos + Height);                     // Blit the y-axis again
        }

        stroke(0);  strokeWeight(1);                                    // Horiz'l guide (value) lines 
        for(int i = 1; i <= yDiv; i ++){
            dashline(xPos,             float(i)/ yDiv * Height + yPos,  
                     xPos + Width + 2, float(i)/ yDiv * Height + yPos,   2, 3);
        }
        
        line(xPos,             yPos,           xPos + Width + 2, yPos);  // "frame" top margin
        line(xPos + Width + 3, yPos + Height,  xPos + Width + 3, yPos);  // "frame" right margin
    }





/*  =========================================================================================
    Straight line graph 
    =========================================================================================  */
    
    void LineGraph(float[] x ,float[] y) {
        for (int i = 0; i < (x.length-1); i ++){
            strokeWeight(GraphWeight); stroke(GraphColor); noFill(); smooth();
            
            line(xPos + (x[i]     - x[0])     / (x[x.length - 1] - x[0]) * Width,
                 yPos + Height    - (y[i]     / (yMax - yMin) * Height) + (yMin) / (yMax - yMin) * Height,
                 
                 xPos + (x[i + 1] - x[0])     / (x[x.length - 1] - x[0]) * Width,
                 yPos + Height    - (y[i + 1] / (yMax - yMin) * Height) + (yMin) / (yMax - yMin) * Height);
        }
    }


/*  =========================================================================================
    Dashed lines functions by J David Eisenberg (2009):
    =========================================================================================  */
    /* 
     * Draws a dashed line with given set of dashes and gap lengths.
     * x0 starting x-coordinate of line.
     * y0 starting y-coordinate of line.
     * x1 ending x-coordinate of line.
     * y1 ending y-coordinate of line.
     * spacing array giving lengths of dashes and gaps in pixels;
     *  an array with values {5, 3, 9, 4} will draw a line with a
     *  5-pixel dash, 3-pixel gap, 9-pixel dash, and 4-pixel gap.
     *  if the array has an odd number of entries, the values are
     *  recycled, so an array of {5, 3, 2} will draw a line with a
     *  5-pixel dash, 3-pixel gap, 2-pixel dash, 5-pixel gap,
     *  3-pixel dash, and 2-pixel gap, then repeat.
     */
     
    void dashline(float x0, float y0, float x1, float y1, float[ ] spacing) {
        
        float distance = dist(x0, y0, x1, y1);
        float [ ] xSpacing = new float[spacing.length];
        float [ ] ySpacing = new float[spacing.length];
        float drawn = 0.0;                                  // amount of distance drawn
        
        if (distance > 0) {
            int i;
            boolean drawLine = true; // alternate between dashes and gaps
            
    /*
        Figure out x and y distances for each of the spacing values.
        "Memory is traded for time"
    */
            for (i = 0; i < spacing.length; i++) {
                xSpacing[i] = lerp(0, (x1 - x0), spacing[i] / distance);
                ySpacing[i] = lerp(0, (y1 - y0), spacing[i] / distance);
            }
            
            i = 0;
            while (drawn < distance) {
                if (drawLine) {
                    line(x0, y0, x0 + xSpacing[i], y0 + ySpacing[i]);
                }
                x0 += xSpacing[i];
                y0 += ySpacing[i];
            /* Add distance "drawn" by this line or gap */
                drawn = drawn + mag(xSpacing[i], ySpacing[i]);
                i = (i + 1) % spacing.length;               // cycle through array
                drawLine = !drawLine;                       // switch between dash and gap
            }
        }
    }
    
    
    /*
     * Draw a dashed line with given dash and gap length.
     * x0 starting x-coordinate of line.
     * y0 starting y-coordinate of line.
     * x1 ending x-coordinate of line.
     * y1 ending y-coordinate of line.
     * dash - length of dashed line in pixels
     * gap - space between dashes in pixels
     */
     
    void dashline(float x0, float y0, float x1, float y1, float dash, float gap) {
        
        float [ ] spacing = { dash, gap };
        dashline(x0, y0, x1, y1, spacing);
    }
}


