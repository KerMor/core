classdef ARBFKernel < kernels.BaseKernel
    % Abstract class for radial basis function / rotation- and translation invariant kernels
    %
    % All rbf kernels have the form `\K(x,y) := \phi(\noG{x-y}), \vx\in\R^d` for some
    % real-valued scalar function `\phi: [0, \infty] \longrightarrow \R` and a given
    % norm-inducing matrix `\vG`.
    %
    % When combinations of Kernels are used, this interface will have to be changed to a property.
    % Up to now, the class CombinationKernel cannot dynamically adopt to the interface for the case
    % that all contained kernels implement this interface.
    %
    % @author Daniel Wirtz @date 2011-08-09
    %
    % @change{0,7,dw,2013-01-16} Moved the Gamma property to here as it is a common setting for
    % all RBF kernels.
    %
    % @new{0,5,dw,2011-10-17} 
    % - Added this class.
    % - Implemented the general evaluate function for rotation invariant
    % kernels.
    %
    % This class is part of the framework
    % KerMor - Model Order Reduction using Kernels:
    % - \c Homepage http://www.morepas.org/software/index.html
    % - \c Documentation http://www.morepas.org/software/kermor/index.html
    % - \c License @ref licensing
    %
    % @todo: change property to check for interface implementation,
    % implement in other suitable kernels
    
    properties(SetObservable)
        % Univariate scaling
        %
        % @propclass{critical} Greatly influences the kernels behaviour.
        %
        % @type double @default 1
        Gamma = 1;
    end
    
    methods
        function this = ARBFKernel
            this = this@kernels.BaseKernel;
            this.IsRBF = true;
        end
        
        function K = evaluate(this, x, y)
            % Evaluates the rotation and translation invariant kernel.
            %
            % Default implementation, computes the squared difference norm, takes the square
            % root and calls evaluateScalar with it.
            %
            % If `y_j` is set, the dimensions of `x_i` and `y_j` must be equal for all `i,j`.
            %
            % Parameters:
            % x: First set `x_i \in \R^d` of `n` vectors @type matrix<double>
            % y: Second set `y_j \in \R^d` of `m` vectors. If y is empty `y_i = x_i` and `n=m`
            % is assumed. @type matrix<double>
            %
            % Return values:
            % K: The evaluation matrix `\K(x, y) \in \R^{n\times m}` of the radial basis
            % function, with entries `\K(x_i,y_j)` at `i,j`.
            %
            % @attention Should your implementation effectively use the squared value directly,
            % consider overriding this method in your subclass for speed (avoid subsequent
            % squarerooting and squaring)
            K = this.evaluateScalar(sqrt(this.getSqDiffNorm(x, y)));
        end
        
        function bool = eq(A ,B)
            bool = eq@kernels.BaseKernel(A, B) && A.Gamma == B.Gamma;
        end
        
        function copy = clone(this, copy)
            copy = clone@kernels.BaseKernel(this, copy);
            copy.Gamma = this.Gamma;
        end
    end
    
    methods(Sealed)
        function r = getSqDiffNorm(this, x, y)
            % Returns the weighted \b squared norm `r` of the difference `\noG{x-y}^2/\gamma^2`.
            %
            % The evaluation respects and projection matrix `\vP` that might be set at
            % kernels.BaseKernel. In this case the matrix `\vG` must match the projected sizes of
            % the argument vectors.
            %
            % @note Evaluation of the squared norm is preferred over computing the squareroot
            % afterwards, as most kernels need the squared value anyways.
            %
            % If `y_j` is set, the dimensions of `x_i` and `y_j` must be equal for all `i,j`.
            %
            % Parameters:
            % x: First set `x_i \in \R^d` of `n` vectors @type matrix<double>
            % y: Second set `y_j \in \R^d` of `m` vectors. If y is empty `y_i = x_i` and `n=m`
            % is assumed. @type matrix<double>
            %
            % Return values:
            % r: The matrix `\vR \in \R^{n\times m}` with entries `R_{ij} =
            % \norm{x_i-y_j}{G}^2/\gamma^2`
            %
            % See also: kernels.BaseKernel.P kernels.ARBFKernel.G
            if ~isempty(this.fP)
                x = x(this.fP,:);
            end
            sx = this.fG*x;
            n1sq = sum(x.*sx,1);
            n1 = size(x,2);
            if isempty(y)
                n2sq = n1sq;
                n2 = n1;
                y = x;
            else
                if ~isempty(this.fP)
                    y = y(this.fP,:);
                end
                n2sq = sum(y.*(this.fG*y),1);
                n2 = size(y,2);
            end;
            r = ((ones(n2,1)*n1sq)' + ones(n1,1)*n2sq - 2*sx'*y);
            % Fix for MatLab 2015a - some values might be slightly
            % negative, leading to complex values when the square root is
            % taken. Example: approx.algorithms.VKOGA.test_VKOGA2D1D has a 
            % different evaluation of the sx'*y part over R2013b and R2015a
            r(r<0) = 0;
        end
    end
    
    %% Getter & setter
    methods
        function set.Gamma(this, value)
            % @todo check why penalty factor was set here to 1/value! ?!?
            if ~isreal(value) || ~isscalar(value) || value <= 0
                error('Only positive scalar values allowed for Gamma.');
            end
            this.Gamma = value;
        end
    end
    
    methods(Abstract)
        % Allows the evaluation of the function `\phi(r)` for scalar `r` directly.
        %
        % Implementations must accept matrix valued `r` and evaluate by component-based means.
        %
        % Parameters:
        % r: The radius matrix `\vR\in\R^{n\times m}` @type matrix<double>
        %
        % Return values:
        % phir: The evaluation matrix `\phi(R)\in\R^{n\times m}` with entries `\phi(R)_{ij} =
        % \phi(r_{ij})`.
        % 
        phir = evaluateScalar(this, r);
    end
    
end

