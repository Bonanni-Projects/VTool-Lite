function FiguresToPNG()

% FIGURESTOPNG - Save current figures to .png files.
% FiguresToPNG()
%
% Saves the currently displayed figures to .png format 
% filea, using file names derived from figure numbers 
% and names. 
%
% P.G. Bonanni
% 4/9/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Get handles to displayed figures
handles = get(0,'Children');

% Return immediately if no figures
if isempty(handles)
  fprintf('No figures to save!\n');
  return
end

% Order handles according to figure number
C = get(handles,'Number');
if isscalar(C), num=C; else num=cat(1,C{:}); end
[~,i] = sort(num);  handles=handles(i);

% Loop over figures
fprintf('Saving files ...\n');
for k = 1:length(handles)
  h = handles(k);
  num = get(h,'Number');
  name = get(h,'Name');
  outfile = sprintf('fig%02d_%s.png',num,name);
  fprintf('  %s\n',outfile);
  print(h,'-dpng',outfile)
end
fprintf('Done.\n');
