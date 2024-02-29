function p = GetParam(pname)

% GETPARAM - Return a VTool configuration parameter.
% p = GetParam(pname)
%
% Returns the specified configuration parameter. 
%
% P.G. Bonanni
% 5/24/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


switch pname
  case 'FrequencyPlotRange'
    p = 2.5;  % default plot range for frequency plots [Hz]
  case 'FrequencyResolution'
    p = 0.025;  % 1/T frequency resolution for spectum calculations [Hz]
  case 'DefaultNumberPlotRows'
    p = 3;  % default number of plot rows per window in "PlotDataset"
  case 'DefaultNameLayer'
    p = '';  % default name layer used for figure window labeling
  case 'MaxDisplayLines'
    p = 15;  % "Display" function uses editor if number of lines exceeds this limit
  otherwise
    error('Invalid parameter name.')
end
