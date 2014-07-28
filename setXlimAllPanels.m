function setXlimAllPanels(windowStart, windowEnd)

allAxesInFigure = findall(gcf, 'type', 'axes');

arrayfun(@(n) xlim(n, [windowStart, windowEnd]), allAxesInFigure)