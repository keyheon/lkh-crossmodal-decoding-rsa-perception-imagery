%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function r = spearman_corr_vectors(v1, v2)
    if isempty(v1) || isempty(v2)
        r = NaN;
        return;
    end

    if ~any(isfinite(v1)) || ~any(isfinite(v2))
        r = NaN;
        return;
    end

    if numel(unique(v1(isfinite(v1)))) <= 1 || numel(unique(v2(isfinite(v2)))) <= 1
        r = NaN;
        return;
    end

    r = corr(v1, v2, 'Type', 'Spearman', 'Rows', 'pairwise');
end