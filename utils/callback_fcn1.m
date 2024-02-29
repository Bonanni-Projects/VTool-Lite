function lines = callback_fcn1(~,EventData)

% callback_fcn1 - Callback function - data cursor text update for "CompareSignalGroups".
% lines = callback_fcn1(~,EventData)
%
% For figure window from "CompareSignalGroups": 
% Customizes the text displayed with the data tip 
% cursor. 
%
% P.G. Bonanni
% 9/22/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Get figure handle
hax = get(get(EventData,'Target'),'Parent');
hfig = get(hax,'Parent');

% Recover stored name string data
Names = get(hfig,'UserData');

% Prevent LaTeX interpretation of underscores in Version 2019a or later
if datenum(version('-date')) > datenum('1-Jan-2019')
  Names = strrep(Names,'_','\_');
end

% Derive signal index value from cursor position
pos = get(EventData,'Position');
index = pos(1);

% Customized text lines
lines = {['Index: ',num2str(index)], ...
         Names{index}};

% Reduce the font size
alldatacursors = findall(hfig,'type','hggroup');
set(alldatacursors,'FontSize',8)
