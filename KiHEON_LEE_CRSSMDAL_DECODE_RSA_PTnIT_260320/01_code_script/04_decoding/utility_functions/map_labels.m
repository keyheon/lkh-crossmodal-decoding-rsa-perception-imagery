%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function lab = map_labels(emo, labelnames)
lab = zeros(numel(emo), 1);
for i = 1:numel(emo)
    k = find(strcmp(labelnames, emo{i}), 1, 'first');
    if isempty(k)
        error('Unknown label "%s"', emo{i});
    end
    lab(i) = k;
end
end