classdef Utils
    % Collection of generally useful functions
    %
    % @author Daniel Wirtz @date 11.10.2010
    
    methods(Static)
        function comb = createCombinations(ranges, varargin)
            % Creates the cartesian product of the vectors passed as a
            % matrix containing elements of each vector per row.
            %
            % Inputs:
            % ranges: Can either be a cell array of vectors or a vector.
            % varargin: If the first argument is a vector, an arbitrary
            % number of additional vectors can be passed to build the
            % cartesian product from.
            %
            % Return values:
            % comb: A matrix containing the combinations, each row
            % corresponds to an input vector's range.
            %
            % @author Daniel Wirtz @date 11.10.2010
            
            if ~isa(ranges,'cell')
                if isempty(varargin)
                    comb = ranges;
                    return;
                end
                r = cell(1,length(varargin)+1);
                r{1} = ranges;
                [r{2:end}] = varargin{:};
                ranges = r;
            end
            
            n = length(ranges);
            % Create nd-grids
            [matrices{1:n}] = ndgrid(ranges{:});
            % Convert to np x params matrix
            comb = zeros(n,numel(matrices{1}));
            for idx=1:n
                % Check if any range is empty - return empty then
                if isempty(matrices{idx})
                    comb = [];
                    return;
                end
                
                comb(idx,:) = matrices{idx}(:);
            end
        end
        
        function target = copyStructFields(source, target)
            % Recursively copies struct fields from one struct to another.
            %
            % @author Daniel Wirtz @date 03.11.2010
            if ~isstruct(source) || ~isstruct(target)
                error('Both source and target arguments must be structs.');
            end
            % Get the field names from the source struct
            names = fieldnames(source);
            for idx = 1:length(names)
                % For struct fields, recursively copy the inner struct
                if isstruct(source.(names{idx}))
                    % Create target struct if not already set
                    if isempty(target.(names{idx}))
                        target.(names{idx}) = struct;
                    end
                    target.(names{idx}) = general.Utils.copyStructFields(source.(names{idx}),target.(names{idx}));
                % Else just copy the field values
                else
                    target.(names{idx}) = source.(names{idx});
                end
            end
        end
        
        function y = preparePlainPlot(y)
            % Memory-saving plotting for plain result plots.
            %
            % Parameters:
            % y: A result matrix `y` with rows corresponding to single
            % dimensions and columns corresponding to time-steps.
            %
            % Return values:
            % If there are more than 1000 dimensions, the subset with
            % distinct (via unique) last values are extracted. If this
            % still results in more than 4000 plots, the first 4000
            % dimensions are selected.
            if size(y,1) > 1000
                fprintf('Utils/preparePlainPlot: Number of graphs for plot > 1000, taking graphs with distinct y(T) values.\n');
                [v,idx] = unique(y(:,end));
                [v,idxm] = unique(y(:,round(size(y,2)/2)));
                y = y(union(idx,idxm),:);
                sy = size(y,1);
                if sy > 4000
                    fprintf('Utils/preparePlainPlot: Number of graphs for plot still > 4000, taking 4000 graphs.\n');
                    y = y(round(1:sy/4000:sy),:);
                end
            end
        end
    end
    
    methods(Static)
        function res = test_createCombinations
            % Tests the createCombinations function.
            % @author Daniel Wirtz @date 11.10.2010
            res = true;
            
            res = res && isequal([1 2 3 1 2 3; 1 1 1 2 2 2],general.Utils.createCombinations(1:3,1:2));
            
            res = res && isempty(general.Utils.createCombinations(1:3,1:2,[],1:54));
            
            res = res && isequal(1:20,general.Utils.createCombinations(1:20));
        end
    end
    
end
