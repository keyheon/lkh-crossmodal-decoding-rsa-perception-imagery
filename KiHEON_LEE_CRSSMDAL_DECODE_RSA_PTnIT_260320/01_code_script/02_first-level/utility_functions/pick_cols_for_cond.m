%% Utility_function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function idx = pick_cols_for_cond(SPM, cond_name)
% Return column indices corresponding to the first HRF basis function for a condition.
    pattern = sprintf('Sn\\(\\d+\\)\\s%s.*\\*bf\\(1\\)', regexptranslate('escape', cond_name));
    names = SPM.xX.name;
    idx = find(~cellfun('isempty', regexp(names, pattern)));
end