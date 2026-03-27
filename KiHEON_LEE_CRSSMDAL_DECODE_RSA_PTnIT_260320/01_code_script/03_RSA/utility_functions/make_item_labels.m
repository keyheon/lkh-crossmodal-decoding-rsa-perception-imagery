%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function labels = make_item_labels(runs_per_session, cond_labels)
    labels = cell(runs_per_session * numel(cond_labels), 1);
    k = 1;
    for r = 1:runs_per_session
        for e = 1:numel(cond_labels)
            labels{k} = sprintf('r%02d_%s', r, cond_labels{e});
            k = k + 1;
        end
    end
end