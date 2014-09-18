function [WhiskPeriods, QuietPeriods] = classifyWhiskState(whiskTs, varargin)
% WHISKMOVE = CLASSIRYWHISKSTATE(WHISKTS, VARARGIN) calculates whisking and quiet periods
% based on a timeseries WHISKTS. It is possible to choose two algoriths to
% classify whisker states. The default is the velocity threshold algorithm.
% 1. velocityThreshold algorithm
% The definition of quiet period is a. the angle velocity of the whisker is less than a given threshold (default is
% 400 deg/sec), b. the quiet period lasts more than a given period (default is 0.6 sec).
% You can set three optional arguments: THRESHOLDANGLE, WINDOW, and
% 
% 2. hilbert algorithm
% 
% 
% 
% 

p = inputParser;
defaultThreshold = 400;
defaultWindow = 0.6; % in second
defaultAlgorithm = 'velocityThreshold';
defaultDurThreshold = 0.2; % in second
p.addRequired('whiskTs');
p.addOptional('thresholdAngle',defaultThreshold, @isnumeric);
p.addOptional('window',defaultWindow, @isnumeric);
p.addOptional('algorithm',defaultAlgorithm, @ischar);
p.addOptional('durThreshold',defaultDurThreshold, @isnumeric);
p.addOptional('longWhiskingTime',false);
parse(p,whiskTs,varargin{:});

samplingRate = 1/whiskTs.TimeInfo.Increment;
onset = whiskTs.TimeInfo.Start;
whiskAngles = squeeze(whiskTs.Data);
if strcmp(p.Results.algorithm, 'velocityThreshold')
    
    whiskMove = abs(diff(whiskAngles)) > p.Results.thresholdAngle / samplingRate;
    % turn 0s to 1 flanked by two 1s.
    for k = 2:length(whiskMove)
        if whiskMove(k) == 0 && whiskMove(k-1) == 1
            followingPeriod = whiskMove(k:min(length(whiskMove),k + p.Results.window*samplingRate));
            whiskMove(k) = any(followingPeriod);
        end
    end
    
    whiskMove = timeseries(whiskMove, 'StartTime', onset + 0.5/samplingRate, 'Interval', 1/samplingRate);
    
elseif strcmp(p.Results.algorithm, 'hilbert')

    whiskMove = whiskAngles - mean(whiskAngles);
    whiskMove = abs(hilbert(whiskMove));
    whiskMove = whiskMove > p.Results.thresholdAngle;
%     timePoints = onset:1/samplingRate:onset+length(whiskMove)*1/samplingRate;
    whiskMove = timeseries(whiskMove, 'StartTime', onset, 'Interval', 1/samplingRate);

elseif strcmp(p.Results.algorithm, 'fft')
    
end

if p.Results.longWhiskingTime % if whisking state has to be longer than durThreshold
    durThreshold = floor(p.Results.durThreshold/whiskTs.TimeInfo.Increment);
    onOff = whiskMove.data;
    for k = 1:length(onOff)
        if onOff(max(1, k-1)) == 0
            if any(onOff(k:min(k + durThreshold, length(onOff))) == 0)
                onOff(k) = 0;
            end
        end
    end
    whiskMove.data = onOff;
end

onsets = diff(whiskMove.Data) == 1;
onsets = whiskMove.Time(onsets);
offsets = diff(whiskMove.Data) == -1;
offsets = whiskMove.Time(offsets);

if onsets(1) < offsets(1) && length(onsets) == length(offsets)
    WhiskPeriods = [onsets, offsets];
    QuietPeriods = [[0; offsets], [onsets; whiskMove.TimeInfo.End]];
elseif onsets(1) < offsets(1) && length(onsets) == length(offsets) + 1
    WhiskPeriods = [onsets,[offsets; whiskMove.TimeInfo.End]];
    QuietPeriods = [[0; offsets], onsets];
elseif onsets(1) > offsets(1) && length(onsets) == length(offsets)
    WhiskPeriods = [[0; onsets], [offsets; whiskMove.TimeInfo.End]];
    QuietPeriods = [offsets, onsets];
elseif onsets(1) > offsets(1) && length(onsets) + 1 == length(offsets)
    WhiskPeriods = [[0; onsets], offsets];
    QuietPeriods = [offsets, [onsets; whiskMove.TimeInfo.End]];
end

figure;
h = plot(whiskTs - mean(whiskTs));
hold on;
ylimit = ylim;
area(whiskMove.Time, squeeze(whiskMove.Data) * (ylimit(2)-ylimit(1)) + ylimit(1), 'baseValue',ylimit(1), 'FaceColor', [0.8 0.9 0.9])
uistack(h, 'top');
title('Whisker angle')
ylabel('deg')
 