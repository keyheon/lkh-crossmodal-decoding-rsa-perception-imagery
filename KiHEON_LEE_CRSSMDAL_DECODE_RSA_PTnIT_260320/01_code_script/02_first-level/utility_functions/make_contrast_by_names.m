%% Utility_function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function convec = make_contrast_by_names(SPM, pos_names, neg_names)
% Build a contrast vector using equal weighting within each side.
    n_cols = size(SPM.xX.X, 2);
    convec = zeros(1, n_cols);

    idx_pos = [];
    for i = 1:numel(pos_names)
        idx_pos = [idx_pos, pick_cols_for_cond(SPM, pos_names{i})]; %#ok<AGROW>
    end
    idx_pos = unique(idx_pos);
    if ~isempty(idx_pos)
        convec(idx_pos) = convec(idx_pos) + 1 / numel(idx_pos);
    elseif ~isempty(pos_names)
        warning('No columns found for positive side: %s', strjoin(pos_names, ', '));
    end

    idx_neg = [];
    for i = 1:numel(neg_names)
        idx_neg = [idx_neg, pick_cols_for_cond(SPM, neg_names{i})]; %#ok<AGROW>
    end
    idx_neg = unique(idx_neg);
    if ~isempty(idx_neg)
        convec(idx_neg) = convec(idx_neg) - 1 / numel(idx_neg);
    elseif ~isempty(neg_names)
        warning('No columns found for negative side: %s', strjoin(neg_names, ', '));
    end
end
