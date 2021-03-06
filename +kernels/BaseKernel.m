classdef BaseKernel < KerMorObject & ICloneable
    % Base class for all KerMor Kernels
    %
    % All Kernels have to inherit from this class.
    %
    % @author Daniel Wirtz @date 12.03.2010
    %
    % @change{0,7,dw,2014-01-24} Removed getDefaultConfig. Exactly a year
    % since added :-)
    %
    % @new{0,7,dw,2013-01-24} Added a new interface getDefaultConfig to each kernel to provide
    % a default configuration when no custom set is provided. See IClassConfig
    %
    % @change{0,3,dw,2011-04-21} Removed the RotationInvariant property as it is now replaced by the
    % IRotationInvariant interface.
    %
    % @todo implement HOCT4-Kernels
    % http://onlinelibrary.wiley.com/doi/10.1111/j.1365-2966.2010.16577.x/full
    
    properties(SetObservable)
        % The matrix `\vG` that induces the state space scalar product
        % `\spG{x}{y}` and norm `\noG{x-y}` to use.
        %
        % Must be a positive definite, symmetric matrix `\vG`.
        %
        % @propclass{critical} If a custom norm is used (i.e. after
        % subspace projection) tihs must be set in order to obtain correct
        % evaluations.
        %
        % @type matrix<double> @default 1
        G = 1;
        
        % Projection/selection matrix `\vP` for argument components
        %
        % Set this value to the indices of the components of any argument passed to the kernel
        % that should be effectively used. This property is mainly used with parameter kernels
        % in order to extract relevant entries. Leave to [] if all values should be used.
        %
        % Subclasses must take care to use this property if set.
        %
        % @propclass{data} Depends on the kernel setting and problem setup.
        %
        % @default [] @type matrix<double>
        P = [];
    end
        
    properties(SetAccess=protected)
        % Flag that determines if the current kernel is a radial basis function, i.e. its
        % evaluation is of the form `\K(x,y) = \phi(\noG{x-y})` for some scalar function
        % `\phi`.
        %
        % Set in subclasses according to current kernel.
        %
        % @type logical @default false
        IsRBF = false;
        
        % Flag that determines if the current kernel bases on scalar product evaluations, i.e.
        % are of the form `\K(x,y) = \phi(\spG{x}{y})` for some scalar function `\phi`.
        %
        % Set in subclasses according to current kernel.
        %
        % @type logical @default false
        IsScProd = false;
    end
    
    properties(SetAccess=private, GetAccess=protected)
        fG = 1;
        fP = [];
    end
    
    methods
        function this = BaseKernel
            this = this@KerMorObject;
            this.registerProps('P', 'G');
        end
        
        function fcn = getLipschitzFunction(this)
            % Method that allows error estimators to obtain a lipschitz
            % constant estimation function from this kernel.
            % 
            % The default is simply each kernel's global lipschitz constant
            % function. However, subclasses may override this method in
            % order to return a better (maybe local) lipschitz constant
            % estimation function. See the BellFunction implementation, for
            % example.
            %
            % See also: kernels.BellFunction error.BaseEstimator
            fcn = @this.getGlobalLipschitz;
        end
        
        function bool = eq(A, B)
            % Checks if a kernel equals another kernel
            bool = eq@KerMorObject(A,B) && isequal(A.fP, B.fP) && ...
                isequal(A.fG, B.fG) && A.IsRBF == B.IsRBF && A.IsScProd == B.IsScProd;
        end
        
        function copy = clone(this, copy)
            copy.G = this.G;
            copy.P = this.P;
            copy.IsRBF = this.IsRBF;
            copy.IsScProd = this.IsScProd;
        end
    end
    
    %% Getter & Setter
    methods
        function G = get.G(this)
            G = this.fG;
        end
        
        function P = get.P(this)
            P = this.fP;
        end
        
    end
        
    methods(Abstract)
        % Evaluation method for the current kernel.
        %
        % Parameters:
        % x: First set `x_i \in \R^d` of `n` vectors @type matrix<double>
        % y: Second set `y_j \in \R^d` of `m` vectors. If y is empty `y_i = x_i` and `n=m`
        % is to be assumed. @type matrix<double>
        %
        % Return values:
        % K: The evaluation matrix `\K(x,y) \in \R^{n\times m}` of the kernel `\K`, with
        % entries `\K(x_i,y_j)` at `i,j`.
        K = evaluate(this, x, y);
        
        % Computes the partial derivatives with respect to each component of the first argument.
        %
        % Parameters:
        % x: The point where to evaluate the partial derivatives. Must be a single column `d\times 1` vector.
        % y: The corresponding center points at which the partial derivatives with respect to the
        % first argument are to be computed. Can be either a column vector `d\times 1` or a matrix `d\times n` containing
        % `n` multiple centers.
        %
        % Return values:
        % Nabla: A `d \times n` matrix of partial derivatives with respect to the first argument
        % evaluated using all second arguments.
        Nabla = getNabla(this, x, y)
        
        % Returns the global lipschitz constant of this kernel.
        %
        % Exprimental state as not implemented & checked for all kernels.
        c = getGlobalLipschitz(this);
    end
    
end

