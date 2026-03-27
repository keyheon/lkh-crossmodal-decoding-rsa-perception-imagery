%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function [X_ordered, ok] = reorder_to_standard(X, labels, standard_labels)
    label_map = containers.Map(labels, 1:numel(labels));
    reorder_idx = nan(numel(standard_labels), 1);

    for i = 1:numel(standard_labels)
        if isKey(label_map, standard_labels{i})
            reorder_idx(i) = label_map(standard_labels{i});
        end
    end

    if any(isnan(reorder_idx))
        X_ordered = [];
        ok = false;
    else
        X_ordered = X(reorder_idx, :);
        ok = true;
    end
end