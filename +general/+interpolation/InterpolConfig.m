classdef InterpolConfig < general.IClassConfig
% InterpolConfig: 
%
% @docupdate
%
% @author Daniel Wirtz @date 2013-01-23
%
% @new{0,7,dw,2013-01-23} Added this class.
%
% This class is part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.agh.ians.uni-stuttgart.de/research/software/kermor.html
% - \c Documentation http://www.agh.ians.uni-stuttgart.de/documentation/kermor/
% - \c License @ref licensing
    
    methods
        % Returns the number of configurations that can be applied
        %
        % Return values:
        % n: The number of configurations @type integer
        function n = getNumConfigurations(this)%#ok
            n = 1;
        end
        
        % Returns the number of configurations that can be applied
        %
        % Parameters:
        % nr: The configuration number @type integer
        % object: The class object for which to apply the configuration @type handle
        function applyConfiguration(this, nr, object)%#ok
            % to nothing
        end
        
        % Returns the number of configurations that can be applied
        %
        % Return values:
        % str:  @type integer
        function str = getConfigurationString(this, nr, asCell)%#ok
            str = '';
        end
        
        function str = getConfiguredPropertiesString(this)
            str = 'none';
        end
    end
    
end