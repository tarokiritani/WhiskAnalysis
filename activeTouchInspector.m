function varargout = activeTouchInspector(varargin)
% ACTIVETOUCHINSPECTOR MATLAB code for activeTouchInspector.fig
%      ACTIVETOUCHINSPECTOR, by itself, creates a new ACTIVETOUCHINSPECTOR or raises the existing
%      singleton*.
%
%      H = ACTIVETOUCHINSPECTOR returns the handle to a new ACTIVETOUCHINSPECTOR or the handle to
%      the existing singleton*.
%
%      ACTIVETOUCHINSPECTOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ACTIVETOUCHINSPECTOR.M with the given input arguments.
%
%      ACTIVETOUCHINSPECTOR('Property','Value',...) creates a new ACTIVETOUCHINSPECTOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before activeTouchInspector_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to activeTouchInspector_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help activeTouchInspector

% Last Modified by GUIDE v2.5 28-Oct-2014 18:42:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @activeTouchInspector_OpeningFcn, ...
                   'gui_OutputFcn',  @activeTouchInspector_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before activeTouchInspector is made visible.
function activeTouchInspector_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to activeTouchInspector (see VARARGIN)

% Choose default command line output for activeTouchInspector
handles.output = hObject;
javaaddpath 'C:\Program Files\MATLAB\R2012b\java\ij.jar'
javaaddpath 'C:\Program Files\MATLAB\R2012b\java\mij.jar'
MIJ.start
set(hObject, 'DeleteFcn', 'MIJ.exit')
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes activeTouchInspector wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = activeTouchInspector_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double

sliceNum = str2double(get(hObject,'String'));
handles = updateStateBySliceNum(sliceNum, handles);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hString = get(handles.edit1, 'String');
try
    sliceNum = str2num(hString{1})-1;
catch 
    sliceNum = str2num(hString)-1;
end

handles = updateStateBySliceNum(sliceNum, handles);
guidata(hObject, handles);

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hString = get(handles.edit1, 'String');
try
    sliceNum = str2num(hString{1})+1;
catch 
    sliceNum = str2num(hString)+1;
end

handles = updateStateBySliceNum(sliceNum, handles);
guidata(hObject, handles);

function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
try
    delete(handles.area)
end
timing = regexp(get(hObject, 'String'), '\[(\d|\.|\s|\,)+]','match');
timing = cellfun(@eval, timing, 'UniformOutput', false);
timing = cell2mat(timing);
timingFormatted = [timing; timing];
timingFormatted = reshape(timingFormatted, 1, numel(timingFormatted));
lowHigh = [ylim fliplr(ylim)];
lowHigh = repmat(lowHigh, 1, numel(timingFormatted)/4);
baseValue = ylim;
handles.area = area(timingFormatted, lowHigh, baseValue(1), 'FaceColor', [0.8 0.9 0.9], 'LineStyle', 'none');
uistack(handles.area, 'bottom')
timing = reshape(timing, 2, numel(timing)/2)';
handles.onOffTiming = timing;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function handles = updateStateBySliceNum(sliceNum, handles)

timePoint = 0.002*(sliceNum -1) + 0.0005;
MIJ.setSlice(sliceNum);
set(handles.edit1, 'String', num2str(sliceNum))
set(handles.edit3, 'String', num2str(timePoint))

try 
    delete(handles.vertical) 
end
axes(handles.axes1);
handles.vertical = plot([timePoint, timePoint],ylim,'r');
handles.sliceNum = sliceNum;
handles.timePoint = timePoint;

function handles = updateStateByTime(timePoint, handles)

sliceNum = round(1+ (timePoint - 0.0005)/0.002);
MIJ.setSlice(sliceNum);
set(handles.edit1, 'String', num2str(sliceNum))
set(handles.edit3, 'String', num2str(timePoint))

try 
    delete(handles.vertical) 
end
axes(handles.axes1);
handles.vertical = plot([timePoint, timePoint],ylim,'r');
handles.sliceNum = sliceNum;
handles.timePoint = timePoint;

function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

timePoint = str2double(get(hObject,'String'));
handles = updateStateByTime(timePoint, handles);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
timePoint = handles.timePoint - 0.0003;
handles = updateStateByTime(timePoint, handles);
guidata(hObject, handles);

% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
timePoint = handles.timePoint + 0.0003;
handles = updateStateByTime(timePoint, handles);
guidata(hObject, handles);

% --------------------------------------------------------------------
function uipushtool1_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtool1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName,FilterIndex] = uigetfile('*.xsg','Select an xsg file.');
load(fullfile(PathName,FileName), '-mat');
piezoTrace = timeseries(data.acquirer.trace_2, 'StartTime', 1/header.acquirer.acquirer.sampleRate, 'Interval', 1/header.acquirer.acquirer.sampleRate);
axes(handles.axes1)
cla
plot(piezoTrace)
hold on

% --------------------------------------------------------------------
function uipushtool2_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtool2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
onOffTiming = handles.onOffTiming;
uisave('onOffTiming');
