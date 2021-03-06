classdef KernelExpansion < KerMorObject & general.AProjectable & dscomponents.IGlobalLipschitz
% KernelExpansion: Base class for state-space kernel expansions
%
% The KernelExpansion class represents a function `f` in the space induced
% by a given kernel `\K` as ``f(x) = \sum\limits_{i=1}^N c_i\K(x,x_i)``
% 
% This class has been introduced in order to allow standalone use of kernel
% expansions in approximation contexts outside of the intended model
% reduction scheme.
%
% @author Daniel Wirtz @date 2011-07-07
%
% @change{0,6,dw,2012-04-25} Removed the RotationInvariant property from the
% kernel expansions and introduced kernels.BaseKernel.IsRBF and
% kernels.BaseKernel.IsScProd to indicate the properties on a per-kernel
% basis.
%
% @change{0,5,dw,2011-07-28} Fixed the evaluate method, it had an argument
% Centers.xi too much.
%
% @new{0,5,dw,2011-07-07} Added this class.
%
% Changes from former class CompwiseKernelCoreFun:
%
% @change{0,4,dw,2011-05-03}
% - Removed the off property as proper RKHS functions dont have an offset
% - No more setter for Ma property - too slow even during offline phase
%
% @new{0,3,dw,2011-04-21} Integrated this class to the property default
% value changed supervision system @ref propclasses. This class now
% inherits from KerMorObject and has an extended constructor registering
% any user-relevant properties using KerMorObject.registerProps.
%
% @change{0,3,sa,2011-04-16} Implemented Setter for the property 'off'
%
% This class is part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.morepas.org/software/index.html
% - \c Documentation http://www.morepas.org/software/kermor/index.html
% - \c License @ref licensing
    
    properties(SetObservable, Dependent)
        % The Kernel to use for system variables
        %
        % @propclass{critical} Correct choice of the system kernel greatly influences the function
        % behaviour.
        %
        % @default kernels.GaussKernel @type kernels.BaseKernel
        %
        % See also: kernels
        Kernel;
    end
    
    properties(Dependent)
        % The norms of the coefficient matrix of the kernel expansion
        %
        % @type rowvec
        Ma_norms;
        
        % Returns the norm `||f||^2_{\H^q}` of `f` in the RKHS `\H^q,\quad q\in\N`
        %
        % For `q=1` this equals the ComponentNorms output.
        %
        % @type double
        NativeNorm;
        
        % Returns the native space norms `||f_j||^2_\H` for each component function
        % `j \equiv`'size(Ma,1)'
        %
        % @type colvec<double>
        ComponentNorms;
        
        % Returns the M upper bound for this KernelExpansion, which is `M :=
        % \max\limits_{j=1}^d\sum\limits_{i=1}^m |c^d_i|`
        MBnd;
        
        % Flag that indicates if a base other than the direct translate base is used for this
        % kernel expansion
        %
        % @type logical @default false
        HasCustomBase;
        
        % The size of the kernel expansion
        Size;
    end
    
    properties(SetObservable)
        % The kernel centers used in the approximation.
        %
        % This is the union of all center data used within the kernel
        % function as a struct 
        % with the following fields:
        % - 'xi' The state variable centers
        % - 'ti' The times at which the state xi is taken
        % - 'mui' The parameter used to obtain the state xi
        %
        % The only required field is xi, others can be set to [] if not
        % used.
        %
        % @propclass{data} The expansion centers.
        %
        % @default struct('xi',[]) @type struct
        Centers = struct('xi',[]);
        
        % The coefficient data for each dimension.
        %
        % @propclass{data} The expansion coefficients.
        %
        % @type matrix<double> @default []
        Ma = [];
        
        % This property lets the user store a custom base, for which the
        % coefficients are set. The custom base tells which linear
        % combinations of center elements belong to which base.
        %
        % In KerMor, this is typically set by the interpolating algorithms
        % like approx.algorithm.VKOGA or
        % general.interpolation.KernelInterpol
        %
        % @propclass{optional} A custom base for which the coefficients are
        % set.
        %
        % @type matrix<double> @default 1
        Base = 1;
    end
    
    properties(SetAccess=private, GetAccess=protected)
        % The inner (state) kernel object
        %
        % @type kernels.BaseKernel @default kernels.GaussKernel;
        fSK;
    end
    
    methods
        function this = KernelExpansion
            % Default constructor. 
            %
            % Initializes default kernels.
            
            % Set custom projection to true as the project method is
            % overridden
            this = this@KerMorObject;
            
            this.fSK = kernels.GaussKernel;
            
            % DONT CHANGE THIS LINE unless you know what you are doing or
            % you are me :-)
%             this.updateRotInv;
            
            this.registerProps('Kernel','Centers','Base');
        end
        
        function fx = evaluate(this, x, varargin)
            % Evaluates the kernel expansion.
            %
            % Parameters:
            % x: The state space vector(s) to evaluate at @type matrix
            % varargin: Dummy variable to also allow calls to this class
            % with `t_i,\mu_i` parameters as in ParamTimeKernelExpansion.
            %
            % Return values:
            % fxi: The evaluation `f(x) = \sumi c_i \K(x,x_i)`
            fx = this.Ma * (this.Base \ this.getKernelVector(x)');
        end
        
        function phi = getKernelVector(this, x, varargin)
            % Evaluates the kernel expansion.
            %
            % Parameters:
            % x: The state space vector(s) to evaluate at @type matrix
            % varargin: Dummy variable to also allow calls to this class
            % with `t_i,\mu_i` parameters as in ParamTimeKernelExpansion.
            %
            % Return values:
            % phi: The kernel vector `\varphi(x) =\left(\K(x,x_i)\right)_{i}`.
            phi = this.fSK.evaluate(x, this.Centers.xi);
        end
        
        function row = getKernelMatrixColumn(this, idx, x, varargin)
            % Evaluates the kernel expansion.
            %
            % Parameters:
            % idx: The column index @type integer
            % x: The state space vector(s) to evaluate at @type matrix
            % @default this.Centers.xi
            % varargin: Dummy variable to also allow calls to this class
            % with `t_i,\mu_i` parameters as in ParamTimeKernelExpansion.
            %
            % Return values:
            % phi: The kernel vector `\varphi(x) =\left(\K(x,x_i)\right)_{i}`.
            if nargin < 3
                x = this.Centers.xi;
            end
            row = this.fSK.evaluate(x, x(:,idx));
        end
                
        function J = getStateJacobian(this, x, varargin)
            % Evaluates the jacobian matrix of this function at the given point.
            %
            % As this is a component-wise kernel expansion, the jacobian is easily computed using
            % the coefficient vectors and the state variable nablas.
            %
            % Parameters:
            % x: The state vector at which the jacobian is required.
            % varargin: Dummy parameter to satisfy the interface calls for
            % kernels.ParamTimeKernelExpansion classes, which also give a
            % `t` and `\mu` parameter.
            %
            % See also: kernels.BaseKernel
            J = this.Ma * (this.Base \ this.fSK.getNabla(x, this.Centers.xi)');
        end
        
        function K = getKernelMatrix(this)
            % Computes the kernel matrix for the currently set center data.
            %
            % Convenience method, equal to call evaluateAtCenters with
            % passing the center data as arguments. However, this method is
            % (possibly, depends on kernel implementation) faster as it
            % calls the kernels kernels.BaseKernel.evaluate -method with
            % one argument.
            %
            % See also: evaluateAtCenters
            K = [];
            if ~isempty(this.Centers)
                K = this.fSK.evaluate(this.Centers.xi,[]);
%                 cent = this.Centers.xi;
%                 if isa(cent,'data.FileMatrix')
%                     cent = cent.toMemoryMatrix;
%                 end
%                 K = this.fSK.evaluate(cent,[]);
            end
        end
        
        function v = scalarProductWith(this, f)
            if ~isa(f,'kernels.KernelExpansion')
                error('f argument must be another KernelExpansion');
            end
            if size(this.Centers.xi,1) ~= size(f.Centers.xi,1)
                error('Function input dimension mismatch');
            end
            if size(this.Ma,1) ~= size(f.Ma,1)
                error('Function output dimension mismatch');
            end
            v = sum(sum(this.Ma .* f.evaluate(this.Centers.xi),2));
        end
        
        function normalize(this)
            this.Ma = this.Ma / this.NativeNorm;
        end
        
        function setCentersFromATD(this, atd, idx)
            % Sets the centers according to the indices 'idx' of the data.ApproxTrainData
            %
            % Parameters:
            % atd: The approximation training data instance @type
            % data.ApproxTrainData
            % idx: The indices of the entries in the approx train data to
            % use @type rowvec<integer>
            this.Centers.xi = atd.xi(:,idx);
        end
        
        function kexp = toTranslateBase(this)
            % Returns the same kernel expansion with the canonical translate base used.
            %
            % If no custom base is used, a simple copy will be returned.
            %
            % Using a non-standard base may be the result of a Newton-base type approximation
            % algorithm. However, evaluating the kernel expansion in a different base is less
            % effective. If the coefficients of the direct translates are not too bad (i.e.
            % large values with opposite signs), using the direct translate base might give the
            % same results at an improved evaluation speed.
            %
            % Return values:
            % kexp: A cloned instance with the direct translate base. @type
            % kernels.KernelExpansion
            kexp = this.clone;
            if kexp.HasCustomBase
                kexp.Ma = kexp.Ma/kexp.Base;
                kexp.Base = 1;
            end
        end
        
        function subexp = getSubExpansion(this, arg)
            subexp = this.clone;
            if isscalar(arg)
                sel = 1:arg;
            else
                sel = arg;
            end
            subexp.Ma = subexp.Ma(:,sel);
            subexp.Centers.xi = subexp.Centers.xi(:,sel);
            if isfield(this.Centers,'ti') && ~isempty(this.Centers.ti)
                subexp.Centers.ti = this.Centers.ti(sel);
            end
            if isfield(this.Centers,'mui') && ~isempty(this.Centers.mui)
                subexp.Centers.mui = this.Centers.mui(:,sel);
            end
            if subexp.HasCustomBase
                subexp.Base = subexp.Base(sel,sel);
            end
        end
        
        function c = getGlobalLipschitz(this, t, mu)%#ok          
            c = sum(this.Ma_norms) * this.Kernel.getGlobalLipschitz;
        end
        
        function target = project(this, V, W)
            target = this.clone;
            k = target.Kernel;
            % For rotation invariant kernel expansions the snapshots can be
            % transferred into the subspace without loss.
            if k.IsRBF
                target.Centers.xi = W' * this.Centers.xi;
                PG = V'*(k.G*V);
                if all(all(abs(PG - eye(size(PG,1))) < 100*eps))
                    PG = 1;
                end
                target.Kernel.G = PG;
            elseif k.IsScProd
                target.Centers.xi = V' * (k.G * this.Centers.xi);
                target.Kernel.G = 1;
            end
            target.Ma = W'*this.Ma;
        end
        
        function copy = clone(this, copy)
            if nargin == 1
                copy = kernels.KernelExpansion;
            end
            % Copy local variables
            copy.Centers = this.Centers;
            copy.Ma = this.Ma;
            copy.Base = this.Base;
            copy.fSK = this.fSK.clone;
        end
        
        function clear(this)
            % Removes all centers and coefficients from the expansion and leaves the associated
            % kernels untouched.
            this.Ma = [];
            this.Centers.xi = [];
        end
        
        function sum = plus(A, B)
            % Adds two kernel expansions and will clone the frist
            % argument's class as result type
            sum = compose(A, B, 1);
        end
        
        function diff = minus(A, B)
            % Adds two kernel expansions and will clone the frist
            % argument's class as result type
            diff = compose(A, B, -1);
        end
        
        function neg = uminus(this)
            neg = this.clone;
            neg.Ma = -this.Ma;
        end
        
        function exportToDirectory(this, dir)
            if nargin < 2
                dir = pwd;
            end
            Utils.ensureDir(dir);
            k = this.Kernel;
            if isa(k,'kernels.GaussKernel')
                kdata = [1 k.Gamma];
            elseif isa(k,'kernels.Wendland')
                kdata = [2 k.Gamma k.d k.k];
            else
                error('Cannot export a kernel of type %s yet.',class(this.Kernel));
            end
            Util.saveRealVector(kdata,'kernel.bin',dir);
            Util.saveRealMatrix(this.Centers.xi,'centers.bin',dir);
            Util.saveRealMatrix(this.Ma,'coeffs.bin',dir);
        end
        
        function json = toJSON(this, filename)
            json = '{';
            %sprintf('{%s,"centers":%s}',coef,cent);
            json = [json '"coeffs":' Util.matrixToJSON(this.Ma)];
            json = [json ', "centers":' Util.matrixToJSON(this.Centers.xi)];
            if this.HasCustomBase
                json = [json ', "base":' Util.matrixToJSON(this.Base)];
            end
            json = [json '}'];
            if nargin > 1
                fh = fopen(filename,'w+');
                fprintf(fh,'%s',json);
                fclose(fh);
            end
        end
        
        function res = test_getStateJacobianInstance(this)
            n = 5;
            xdim = size(this.Centers.xi,1);
            meanx = mean(this.Centers.xi,2);
            rs = RandStream('mt19937ar','Seed',round(rand*1000));
            allX = bsxfun(@plus,meanx,rs.rand(xdim,n));
            allX = [this.Centers.xi(:,1) allX];
            res = true;
            for k = 1:n
                x = allX(:,k);
                dx = ones(xdim,1)*sqrt(eps(class(x))).*max(abs(x),1);
                X = repmat(x,1,xdim);
                Jc = (this.evaluate(X+diag(dx))-this.evaluate(X))*diag(1./dx);
                J = this.getStateJacobian(x);
                maxrel = max(max(abs((J-Jc)./Jc)));
                if maxrel > 1e-2
                    fprintf('%s: Max relative error: %g\n',class(this.Kernel),maxrel);
                    res = false;
                end
            end
        end
    end
    
    %% Getter & Setter
    methods    
        function set.Centers(this, value)
            C = {'xi','ti','mui'};            
            if isempty(value) || any(isfield(value, C))
                this.Centers = value;
%                 if ~isfield(value,'xi')
%                     warning('REQUIRED_FIELD:Empty','xi is a required field, which is left empty');
%                 end
            else
                error('Value passed is not a valid struct. Only the field names xi, ti, mui are allowed');
            end            
        end
        
        function k = get.Kernel(this)
            k = this.fSK;
        end
        
        function value = get.Size(this)
            value = 0;
            if ~isempty(this.Centers)
                value = size(this.Centers.xi,2);
            end
        end
    
        function set.Kernel(this, value)
            if isa(value,'kernels.BaseKernel')
                this.fSK = value;
%                 this.updateRotInv;
            else
                error('Kernel must be a subclass of kernels.BaseKernel.');
            end
        end
        
        function m = get.Ma_norms(this)
            m = sqrt(sum(this.Ma.^2,1));
        end
        
        function n = get.ComponentNorms(this)
            if this.HasCustomBase
                c = this.Ma/this.Base;
            else
                c = this.Ma;
            end
            n = sqrt(sum(c' .* (this.getKernelMatrix * c'),1))';
        end
        
        function n = get.NativeNorm(this)
            % Returns the native norm of the kernel expansion
            
            % doesnt use ComponentNorms as this way we save "sqrt(x).^2"
            if this.HasCustomBase
                c = this.Ma/this.Base;
            else
                c = this.Ma;
            end
            n = sqrt(sum(sum(c' .* (this.getKernelMatrix * c'))));
        end
        
        function M = get.MBnd(this)
            if this.HasCustomBase
                c = this.Ma/this.Base;
            else
                c = this.Ma;
            end
            M = max(sum(abs(c),2));
        end
        
        function v = get.HasCustomBase(this)
            v = ~isempty(this.Base) && (numel(this.Base) > 1 || this.Base ~= 1);
        end
    end
    
    methods(Access=private)
        function c = compose(A, B, sgn)
            if ~isa(A,'kernels.KernelExpansion') || ~isa(B,'kernels.KernelExpansion')
                error('Both arguments must be at least kernels.KernelExpansion subclasses');
            end
            if A.Kernel ~= B.Kernel
                error('Cannot add kernel expansions: different state space kernels');
            elseif ~isempty(A.Ma) && ~isempty(B.Ma) && size(A.Ma,1) ~= size(B.Ma,1)
                error('Cannot add kernel expansions: different output dimensions');
            elseif ~isempty(A.Centers.xi) && ~isempty(B.Centers.xi) && size(A.Centers.xi,1) ~= size(B.Centers.xi,1)
                error('Cannot add kernel expansions: different statespace center dimensions');
            end
            c = A.clone;
            c.Centers.xi = [A.Centers.xi B.Centers.xi];
            c.Ma = [A.Ma sgn*B.Ma];
        end
    end
    
    methods(Static)
        function res = test_getStateJacobian
            rs = RandStream('mt19937ar','Seed',0);
            ke = kernels.KernelExpansion;
            k1 = kernels.GaussKernel(1);
            k2 = kernels.Wendland;
            
            s = [1 1 2 2 3 3];
            d = [1 20 1 20 1 20];
            gam = 4 + (1:6);
            n = 6;
            nc = round(rs.rand(1,6)*100);
            
            res = true;
            for k = 1:n
                ke.Centers.xi = rs.rand(d(k),nc(k));
                ke.Ma = rs.rand(d(k)+1,nc(k));
                
                k1.Gamma = gam(k);
                ke.Kernel = k1;
                res = res & ke.test_getStateJacobianInstance;
                
                k2.Gamma = gam(k);
                k2.d = d(k);
                k2.k = s(k);
                ke.Kernel = k2;
                res = res & ke.test_getStateJacobianInstance;
            end
        end
    end
    
    methods(Static,Access=protected)
        function this = loadobj(this, from)
            % As the constant properties are transient, they have to be re-computed upon loading.
            %
            % Any subclasser MUST call this superclasses loadobj function explicitly!
            if nargin > 1
                this.Kernel = from.Kernel;
                this.Ma = from.Ma;
                this.Centers = from.Centers;
                if isfield(from,'Base')
                    this.Base = from.Base;
                end
                this = loadobj@KerMorObject(this, from);
            elseif ~isa(this, 'kernels.KernelExpansion')
                newinst = kernels.KernelExpansion;
                newinst.Kernel = this.fSK;
                newinst.Ma = this.Ma;
                newinst.Centers = this.Centers;
                if isfield(this,'Base')
                    newinst.Base = this.Base;
                end
                this = loadobj@KerMorObject(newinst, this);
            end
        end
    end
    
end