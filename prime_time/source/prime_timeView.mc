import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

using Toybox.Time.Gregorian as Date;
using Toybox.Math as Math;

class prime_timeView extends WatchUi.WatchFace {

    // All primes we need to decompose every number in [1, 60]
    var primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59];
    // All prime decompositions for numbers in [1, 60]
    // Each entry in the list can be made by multiplying all key^values with eachother
    var primeDecompositions = [
        {}, //0 - we dont use this
        {}, //1 - empty list/plot represents 1
        {2 => 1}, //2
        {3 => 1}, //3
        {2 => 2}, //4
        {5 => 1}, //5
        {2 => 1, 3=> 1}, //6
        {7 => 1}, //7
        {2 => 3}, //8
        {3 => 2}, //9
        {2 => 1, 5 => 1}, //10
        {11 => 1}, //11
        {2 => 2, 3 => 1}, //12
        {13 => 1}, //13
        {2 => 1, 7 => 1}, //14
        {3 => 1, 5 => 1}, //15
        {2 => 4}, //16
        {17 => 1}, //17
        {2 => 1, 3 => 2}, //18
        {19 => 1}, //19
        {2 => 2, 5 => 1}, //20
        {3 => 1, 7 => 1}, //21
        {2 => 1, 11 => 1}, //22
        {23 => 1}, //23
        {2 => 3, 3 => 1}, //24
        {5 => 2}, //25
        {2 => 1, 13 => 1}, //26
        {3 => 3}, //27
        {2 => 2, 7 => 1}, //28
        {29 => 1}, //29
        {2 => 1, 3 => 1, 5 => 1}, //30
        {31 => 1}, //31
        {2 => 5}, //32
        {3 => 1, 11 => 1}, //33
        {2 => 1, 17 => 1}, //34
        {5 => 1, 7 => 1}, //35
        {2 => 2, 3 => 3}, //36
        {37 => 1}, //37
        {2 => 1, 19 => 1}, //38
        {3 => 1, 13 => 1}, //39
        {2 => 3, 5 => 1}, //40
        {41 => 1}, //41
        {2 => 1, 3 => 1, 7=> 1}, //42
        {43 => 1}, //43
        {2 => 2, 11 => 1}, //44
        {3 => 2, 5 => 1}, //45
        {2 => 1, 23 => 1}, //46
        {47 => 1}, //47
        {2 => 4, 3 => 1}, //48
        {7 => 2}, //49
        {2 => 1, 5 => 2}, //50
        {3 => 1, 17 => 1}, //51
        {2 => 2, 13 => 1}, //52
        {53 => 1}, //53
        {2 => 1, 3 => 3}, //54
        {5 => 1, 11 => 1}, //55
        {2 => 3, 7 => 1}, //56
        {3 => 1, 19 => 1}, //57
        {2 => 1, 29 => 1}, //58
        {59 => 1}, //59
        {2 => 2, 3 => 1, 5 => 1} //60
        // Do up to 60 later to do minutes as well
    ];

    enum {
        DISPLAY_HOURS,
        DISPLAY_MINUTES,
        DISPLAY_SECONDS
    }

    // More general numbers to aid in plotting
    var maxNumHands = primes.size(); // we need 17 prime numbers in total
    var maxExponents = 5; // Highest amount of prime exponents needed

    var screenWidth;
    var screenHeight;
    var diskRadius; // Radius of the watch
    var centerX; // Center coords of the watch (not necessarily center of screen)
    var centerY;

    var usedPrimes; // the indices of the primes used in plotting at this time
    var displayHand = DISPLAY_SECONDS; // Start out in high-power mode so show seconds

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        //setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Set screen size vars
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        diskRadius = screenHeight>>1;
        centerX = screenWidth>>1;
        centerY = screenHeight>>1;

        usedPrimes = []; // Reset list of prime numbers used in this plot
        
        // Clear the entire screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        // Get and show the current time
        var clockTime = System.getClockTime();
        var clockHour = clockTime.hour;
        var clockMin = clockTime.min;
        var clockSec = clockTime.sec;

        // Make correction: wrap around zeroes
        if (clockHour == 0) {clockHour = 60;}
        if (clockMin == 0) {clockMin = 60;}
        if (clockSec == 0) {clockSec = 60;}

        // Plot Hours, Minutes or Seconds (depending on power state?)
        switch (displayHand) {
            case DISPLAY_HOURS:
                drawAllHands(dc, clockHour);
            break;
            case DISPLAY_MINUTES:
                drawAllHands(dc, clockMin);
            break;
            case DISPLAY_SECONDS:
                drawAllHands(dc, clockSec);
            break;
            default:
                System.println("No display setting matched!");
            break;
        }

        // Draw circles to count factors with
        drawUnitCircles(dc);

        // Draw the legend for each used prime number
        drawHandLegend(dc);

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        displayHand = DISPLAY_SECONDS;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        displayHand = DISPLAY_MINUTES;
    }

    // Draw a filled polygon at angle theta 
    function fillPolygon(dc, dx, dy, theta, points) {
        var sin = Math.sin(theta);
        var cos = Math.cos(theta);

        for (var i = 0; i < points.size(); ++i) {
            var x = (points[i][0] * cos) - (points[i][1] * sin) + dx;
            var y = (points[i][0] * sin) + (points[i][1] * cos) + dy;
            points[i][0] = x;
            points[i][1] = y;
        }

        dc.fillPolygon(points);
    }

    // Draw one prime hand: a triangle with its radial length equal to the number of factors for this prime number
    function drawHand(dc, theta, length) {
        var barWidth = 8.0;

        var pts = [[0.0, -(1-length) * diskRadius], [-barWidth, -diskRadius], [barWidth, -diskRadius]];
        fillPolygon(dc, centerX, centerY, theta, pts);
    }

    // Take the dc & hours/minutes/seconds hand number, and plot it
    function drawAllHands(dc, handNumber) {
        var handNumberDecomposition = primeDecompositions[handNumber];

        var primeFactors = handNumberDecomposition.keys();
        for (var i = 0; i < handNumberDecomposition.size(); ++i) {
            var primeNumber = primeFactors[i];
            var primeExponent = handNumberDecomposition[primeNumber];
            var primeIdx = primes.indexOf(primeNumber);

            var theta = primeIdx * 2.0 * Math.PI / maxNumHands;
            var length = primeExponent * 1.0/maxExponents;
            drawHand(dc, theta, length);
            usedPrimes = usedPrimes.add(primeIdx); // this prime number is used, plot its legend later
        }
    }

    // Draw for each used prime factor the legend to the polygon as well indicating the number
    function drawHandLegend(dc){
        for (var i = 0; i < usedPrimes.size(); ++i) {
            var primeIdx = usedPrimes[i];
            var primeNumberText = primes[primeIdx].format("%2d");
            var theta = primeIdx * 2.0 * Math.PI / maxNumHands;

            var sin = Math.sin(theta);
            var cos = Math.cos(theta);

            var x = 0.3 * diskRadius * sin + centerX;
            var y = - 0.3 * diskRadius * cos + centerY;

            var legendText = new WatchUi.Text({
                :text=> primeNumberText,
                :color=>Graphics.COLOR_WHITE,
                :font=>Graphics.FONT_SMALL,
                :justification=>Graphics.TEXT_JUSTIFY_CENTER,
                :locX => x,
                :locY=> y
            });
            legendText.draw(dc);
        }
    }

    // Draw circles around to center in black on top of the hands to count exponents with
    function drawUnitCircles(dc){
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        for (var i = 1; i < maxExponents; ++i) {
            dc.drawCircle(centerX, centerY, i * diskRadius/maxExponents);
        } 
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    }

}
