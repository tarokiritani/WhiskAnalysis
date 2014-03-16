function whiskHilbert = whiskHilbert(whiskAngle)
    whiskAngle = whiskAngle - mean(whiskAngle);
    time = 0:(length(whiskAngle) - 1) * 0.5 + 0.25;
    ts = timeseries(whiskAngle, time);
    filterWindow = [2, 100];
    tsFiltered = idealfilter(ts, filterWindow, pass);
    figure;
    plot(tsFiltered);
    x = hilbert(whiskAngle);
    whiskHelbert = abs(x);
    figure;
    plot(abs(x));