function activeTouchContact
% edit the following matrix and run the function. The first column inidcates the
% frame where the whisker touches the piezo. The second column indicates
% the last frame where the whisker is still in contact with the piezo. The
% numbers in a row can be the same.
onOffFrames = [
    3815 3818;
    3865 3872;
    3935 3941;
    4010 4041;
    4052 4059;
    4066 4124;
    4139 4148;
    4157 4166;
    4186 4191
];

onOffTiming = zeros(1, 30000);
for k = 1:length(onOffFrames)
    onOffTiming(onOffFrames(k, 1):onOffFrames(k, 2)) = 1;
end

onOffTimingTs = timeseries(onOffTiming, 'StartTime', 0.0005, 'Interval', 0.002);

uisave({'onOffFrames', 'onOffTiming', 'onOffTimingTs'}, 'activeTouchContact');