%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function roiList = dedup_by_basename_prefer_r_in_dir(roiList, preferDir)
    [fold, nam, ext] = cellfun(@fileparts, roiList, 'UniformOutput', false); %#ok<ASGLU>
    base = regexprep(nam, '^r+', '');
    score = startsWith(nam, 'r') + contains(fold, preferDir);
    ubase = unique(base, 'stable');
    keep = false(size(roiList));
    for k = 1:numel(ubase)
        idx = find(strcmp(base, ubase{k}));
        [~, best] = max(score(idx));
        keep(idx(best)) = true;
    end
    roiList = roiList(keep);
end