%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function check_class_balance(name, emo, labelnames)
counts = cellfun(@(e) sum(strcmp(emo, e)), labelnames);
if any(counts == 0)
    error('%s: at least one class is missing (counts=%s)', name, mat2str(counts));
end
end