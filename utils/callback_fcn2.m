function lines = callback_fcn2(~,EventData)

% callback_fcn2 - Callback function - data cursor text update for "PlotBinnedSequences".
% lines = callback_fcn2(~,EventData)
%
% For figure windows from "PlotBinnedSequences": 
% Customizes the text displayed with the data tip 
% cursor. 
%
% P.G. Bonanni
% 10/10/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Get axes and figure handles
hax = get(get(EventData,'Target'),'Parent');
hfig = get(hax,'Parent');

% Recover stored user data
UserData = get(hax,'UserData');
npoints  = UserData.npoints;
indexVals = UserData.indexVals;

% Derive array index value from cursor position
pos = get(EventData,'Position');  i=pos(1); yval=pos(2);
index = indexVals(1 + floor(i/npoints));

% Customized text line(s)
lines = {['Case Index: ',num2str(index)]
         ['Y = ',num2str(yval,'%g')]};

% Reduce the font size
alldatacursors = findall(hfig,'type','hggroup');
set(alldatacursors,'FontSize',8)
