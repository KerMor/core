classdef GaussKernel < kernels.BellFunction
    % Radial Basis Function Kernel
    %   
    % Uses the notation
    % ``\K(x,y) = e^{\frac{||x-y||^2}{\gamma^2}},``
    % so be careful with the `\gamma` constant.
    %
    % @author Daniel Wirtz @date 11.03.2011
    %
    % @change{0,5,dw,2011-10-16} Exported the evaluate function to
    % kernels.ARBFKernel, but re-implemented the customized
    % evaluate function as the norm squared is already computed fast and
    % first taking the square root and then squaring again would introduce
    % unecessary overhead.
    %
    % @change{0,3,dw,2011-04-26} Fixed the x0 computation for the new Gamma property version; so far
    % a square was missing, rendering the LipschitzEstimator modified newton method useless.
    %
    % @change{0,3,dw,2011-04-15} Changed the Gamma property to compute into the kernel evaluation
    % being squared instead of linear. This way the Gamma becomes a more geometrical meaning
    %
    % @change{0,2,dw,2011-03-11} Added new speed tests for one and two
    % argument calls to 'evaluate'. The tests are run 'iter' times and the
    % mean value is plotted to the output.
    
    methods
        function this = GaussKernel(Gamma)
            % Creates a new GaussKernel
            %
            % Parameters:
            % Gamma: The Gamma property to use. @default 1 @type double
            this = this@kernels.BellFunction;
            this.registerProps('Gamma');%,'Sigma'
            
            if nargin == 1
                this.Gamma = Gamma;
            end
            this.updateGammaDependants;
            this.addlistener('Gamma','PostSet',@this.updateGammaDependants);
        end
        
        function K = evaluate(this, x, y)
            % Evaluates the gaussian.
            %
            % If `y_j` is set, the dimensions of `x_i` and `y_j` must be equal for all `i,j`.
            %
            % Parameters:
            % x: First set `x_i \in \R^d` of `n` vectors @type matrix<double>
            % y: Second set `y_j \in \R^d` of `m` vectors. If y is empty `y_i = x_i` and `n=m`
            % is assumed. @type matrix<double>
            %
            % Return values:
            % K: An evaluation matrix `K \in \R^{n\times m}` of the evaluated gaussians with
            % entries `K_{i,j} = e^{-\norm{x_i-y_j}{G}^2/\gamma^2}`.
            K = exp(-this.getSqDiffNorm(x, y)/this.Gamma^2);
        end
                
        function Nablax = getNabla(this, x, y)
            % Method for first derivative evaluation
            if size(x,2) > 1 && size(y,2) > 1
                error('One argument must be a vector.');
            end
            if ~isempty(this.fP)
                error('Not yet implemented correctly.');
%                 xl = x(this.P,:);
%                 yl = y(this.P,:);
%             else
%                 xl = x; yl = y;
            end
            hlp = bsxfun(@minus,x,y);
            hlp = -2*hlp/this.Gamma^2;
            Nablax = bsxfun(@times,hlp,this.evaluate(x, y));
        end 
        
%         function K = evaluateIntel(this, x, varargin)
%             % Experimental function that automatically calls the mex openmp
%             % implementation code if the vectors are small enough.
%             %
%             % @todo write c code more efficient (use blas/lapack?)
%             
%             % Evaluate MEX function if sizes are small!
%             if numel(x) < 500000
%                  K = this.evaluateMex(x,varargin{:});
%                  return;
%             end
%             
%             n1sq = sum(x.^2,1);
%             n1 = size(x,2);
% 
%             if nargin == 2;
%                 n2sq = n1sq;
%                 n2 = n1;
%                 y = x;
%             else
%                 y = varargin{1};
%                 n2sq = sum(y.^2,1);
%                 n2 = size(y,2);
%             end;
%             K = (ones(n2,1)*n1sq)' + ones(n1,1)*n2sq - 2*x'*y;
%             K(K<0) = 0;
%             K = exp(-K/this.Gamma^2);
%         end
                
        function dx = evaluateD1(this, r)
            % Method for first derivative evaluation
            dx = -2*r/this.Gamma^2 .* exp(-r.^2/this.Gamma^2);
        end
        
        function ddx = evaluateD2(this, r)
            % Method for second derivative evaluation
            ddx = (2/this.Gamma^2) * (2*r.^2/this.Gamma^2-1) .* exp(-r.^2/this.Gamma^2);
        end
        
        function phi = evaluateScalar(this, r)
            % Implements the required method from the IRotationInvariant
            % interface
            phi = exp(-r.^2/this.Gamma^2);
        end
        
        function g = setGammaForDistance(this, dist, ep)
            % Computes the `\gamma` value for which the Gaussian is smaller
            % than `\epsilon` in a distance of dist, i.e.
            % ``e^{-\frac{d^2}{\gamma}} < \epsilon``
            % Returns the computed value AND sets the kernel's Gamma
            % property to this value.
            %
            % Parameters:
            % dist: The target distance at which the gaussian is smaller
            % than ep
            % ep: The `\epsilon` value. If not given, `\epsilon`=eps
            % (machine precision) is assumed.
            %
            % Return values:
            % g: The computed gamma
            if nargin == 2
                ep = eps;
            end
            g = dist/sqrt(-log(ep));
            this.Gamma = g;
            
            if KerMor.App.Verbose > 3
                fprintf('Setting Gamma = %12.20f\n',g);
            end
        end
        
        function copy = clone(this)
            copy = kernels.GaussKernel;
            copy.Gamma = this.Gamma;
            copy = clone@kernels.BellFunction(this, copy);
        end
    end
    
    methods(Access=private)
        function updateGammaDependants(this, ~, ~)
            % Adjust the BellFunctions' x0 value
            this.r0 = this.Gamma/sqrt(2);
        end
    end
    
    methods(Static,Access=protected)
        function obj = loadobj(obj)
            if ~isa(obj, 'kernels.GaussKernel')
                newinst = kernels.GaussKernel;
                newinst.Gamma  = obj.Gamma;
                newinst.updateGammaDependants;
                obj = loadobj@kernels.BellFunction(newinst, obj);
            else
                obj = loadobj@kernels.BellFunction(obj);
            end
            obj.addlistener('Gamma','PostSet',@this.updateGammaDependants);
        end
    end
        
    methods(Static)
        function res = test_InterpolGamma            
            ki = general.interpolation.KernelInterpol;
            ki.UseNewtonBasis = false;
            kexp = kernels.KernelExpansion;
            k = kernels.GaussKernel;
            kexp.Kernel = k;
            dx = .2;
            x = -3:dx:3;
            fx = sin(x*pi);
            plot(x,fx);
            epsteps = 0.05:.05:.95;
            dlog = zeros(3,length(epsteps));
            for epidx=1:length(epsteps)
                ep = epsteps(epidx);
                k.setGammaForDistance(dx,ep);
                for idx = 1:length(x)
                    x2 = x;
                    x2(idx) = [];
                    fx2 = fx;
                    fx2(idx) = [];
                    
                    kexp.Centers.xi = x2;
                    ki.init(kexp);
                    kexp.Ma = ki.interpolate(fx2);
                    
                    fxi = kexp.evaluate(x);
                    diff(idx) = abs(fx(idx) - fxi(idx));%#ok
                end
                dlog(1,epidx) = ep;
                dlog(2,epidx) = min(diff);
                dlog(3,epidx) = max(diff);
            end            
            disp(dlog);
            [~, idx] = min(dlog(2,:));
            fprintf('Min distance: %f at ep=%f\n',dlog(2,idx),dlog(1,idx));
            res = true;
        end
        
        function [res, pm] = test_GaussKernel(pm)
            if nargin < 1
                pm = PlotManager(false,2,3);
                pm.LeaveOpen = true;
            end
            c = 0;
            x = (-1.2:.01:1.2)+c;
            [X,Y] = meshgrid(x);
            x2 = [X(:)'; Y(:)'];
            k = kernels.GaussKernel;
            kexp = kernels.KernelExpansion;
            kexp.Kernel = k;
            kexp.Centers.xi = c;
            kexp.Ma = 1;
            conf = [1 2 3];
            for n = 1:length(conf)
                d = conf(n);
                g = k.setGammaForDistance(d,eps);
                tag = strrep(sprintf('g_1d_d%d_g%g',d,g),'.','_');
                h = pm.nextPlot(tag,sprintf('Gauss kernel with dist=%d,\\gamma=%g on 1D data',d,g));
                plot(h,x,kexp.evaluate(x));
            end
            kexp.Centers.xi = [c; c];
            for n = 1:length(conf)
                d = conf(n);
                g = k.setGammaForDistance(d,eps);
                tag = strrep(sprintf('g_2d_d%d_g%g',d,g),'.','_');
                h = pm.nextPlot(tag,sprintf('Gauss kernel with dist=%d,\\gamma=%g on 2D data',d,g));
                surf(h,X,Y,reshape(kexp.evaluate(x2),length(x),[]),'EdgeColor','none');
            end
            if nargin < 1
                pm.done;
            end
            res = true;
        end
    end
    
end

