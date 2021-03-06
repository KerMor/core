classdef BaseModel < KerMorObject
% BaseModel: Base class for both full and reduced models.
%
% This class gathers all common functionalities of models in the
% KerMor framework.
% The most important method would be @code [t,y] =
% simulate(mu,inputidx) @endcode which computes the system's solution
% for given `\mu` and input number (if applicable).  Also a plot
% wrapper is provided that refers to the plotting methods within the
% model's system.
%
% @author Daniel Wirtz @date 19.03.2010
%
% @change{0,6,dw,2012-05-26} Adopted way of computing the jacobian and
% jsparsity pattern for ode solvers according to new possibility of having
% a (affine) linear models.BaseFirstOrderSystem.A component.
%
% @change{0,6,dw,2011-12-14} Introduced a \c ctime argument to the simulate and
% computeTrajectory methods. This motivates from several caching strategies that may be applied
% which lead to less computation time due to simple trajectory lookup. however, when comparing
% error estimators this effect irritates the results since subsequent calls to trajectory
% computations in the context of different estimators lead to different computation times.
%
% @change{0,6,dw,2011-11-25} Made T a dependent property and added consistency checks for T and
% dt
%
% @change{0,5,dw,2011-11-02} Modified the set.ODESolver method so that the MaxTimestep value is
% set to empty if implicit solvers are used. If again an explicit solver is used, a warning is
% issued if the models.BaseFirstOrderSystem.MaxTimestep value of the corresponding System is empty.
%
% @change{0,5,dw,2011-10-14} Removed the TimeDirty flag as it wasnt used properly/at all.
%
% @change{0,5,dw,2011-09-29}
% - New flag-field RealTimePlotting that calls the new plotSingle
% method in order to display the system as it is simulated.
% - Made ODESolver dependent to implement connection to
% RealTimePlotting.
% - New double field RealTimePlottingMinPause to enable timely display
% of in-simulation states.
%
% @change{0,3,sa,2011-05-10} Implemented setters for the rest of the
% properties
%
% @new{0,3,dw,2011-04-21} Integrated this class to the property default value changed
% supervision system @ref propclasses. This class now inherits from KerMorObject and has an
% extended constructor registering any user-relevant properties using
% KerMorObject.registerProps.
% 
% @change{0,3,dw,2011-04-15} Added a dependent GScaled property that returns the norm-inducing
% matrix G scaled with the current System.StateScaling property.
%
% @change{0,3,dw,2011-04-05} 
% - Removed the getConfigStr-Method and moved it to
% Utils.getObjectConfig
% - Added a setter for System checking for self-references
%
% @new{0,2,dw,2011-03-08} Implemented time scaling via addition of the
% property models.BaseModel.tau and dependent attributes
% models.BaseModel.dtscaled and models.BaseModel.Tscaled. This
% way model data can be entered in original units and the
% system calculates with the scaled time values. The main change is in
% @ref models.BaseModel.computeTrajectory where the ODE solver is
% called with the scaled time steps and the resulting timesteps are
% re-scaled to their original unit.
%
% @change{0,1,dw} Generalized scalar product via `<x,y>_G = x^tGy`,
% default `I_d` for `d\in\N`
%
% @new{0,1,dw} String output of all model settings via method
% getObjectConfig
%
% This class is part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.morepas.org/software/index.html
% - \c Documentation http://www.morepas.org/software/kermor/index.html
% - \c License @ref licensing    
    
    properties(SetObservable)
        % The actual dynamical system used in the model.
        %
        % @propclass{critical} No simulations without dynamical system.
        %
        % @default [] @type models.BaseFirstOrderSystem
        System = [];
        
        % The name of the Model.
        %
        % @propclass{optional}
        %
        % @type char @default ''
        Name = '';
                              
        % The custom scalar product matrix `\vG`
        %
        % In some settings the state variables have a special meaning (like
        % DOF's in FEM simulations) where the pure `L^2`-norm has less
        % meaning than a custom norm induced by a symmetric positive
        % definite matrix G. If `d\in\N` is the number of state
        % variables (i.e. dimensions of `\vx(t)`), then we must have
        % `\vG\in\R^{d\times d}`.
        %
        % Leave at default value `1` if `G=I_d` should be assumed.
        %
        % @propclass{optional}
        %
        % @default 1 @type matrix<double>
        G = 1;
        
        % Minimum pause between successive steps when RealTimePlotting is
        % enabled.
        %
        % @propclass{optional} Changes pause length between timesteps
        %
        % @default .1 @type double
        %
        % @see RealTimePlotting
        RealTimePlottingMinPause = .1;
        
        % Determines if the model is time dependent or static
        %
        % See also simulate
        %
        % @default false @type logical
        isStatic = false;
        
        % The default input to use if none is given
        %
        % The default is [], so use NO input (even if there are some)
        %
        % @type integer @default []
        DefaultInput = [];
        
        % The starting time for any simulation.
        %
        % @propclass{optional} Usually dynamical systems are simulated
        % starting from t=0
        %
        % @default 0 @type double
        t0 = 0
    end
    
    properties(SetAccess=private, Dependent)
        % Evaluation points `\{0=t_0,\ldots,t_n=T\}` of the model 
        Times;
        
        % The time steps Times in scaled time units `\tilde{t_i} = \frac{t_i}{\tau}`
        %
        % See also: tau
        %
        % @default Times @type rowvec<double>
        scaledTimes;
        
        % The scaled end time `\tilde{T} = \frac{T}{\tau}`
        %
        % See also: tau T
        %
        % @default T @type double
        Tscaled;
    end
    
    properties(Dependent, SetObservable)
        % Time scaling factor `\tau`
        %
        % If used, the values from T and dt are getting scaled by tau when
        % calling simulate.
        %
        % @propclass{scaling}
        %
        % @default 1 @type double
        tau;
        
        % The final timestep `T` up to which to simulate.
        %
        % NOTE: When changing this property any offline computations have
        % to be repeated in order to obtain a new reduced model.
        %
        % @propclass{important} Defines the end time `T` up to which the dynamical system has to be
        % simulated.
        %
        % @type double @default 1
        T;
        
        % The desired time-stepsize `\Delta t` for simulations.
        %
        % @attention - This property is influencing the resulting output-times at which the
        % dynamical system is computed. If you need to set a maximum time-step size due to CFL
        % conditions, for example, use the models.BaseFirstOrderSystem.MaxTimeStep property.
        % - When changing this property any offline computations have
        % to be repeated in order to obtain a new reduced model.
        %
        % @propclass{critical}
        %
        % @default 0.1 @type double
        %
        % See also: dtscaled
        dt;
        
        % The solver to use for the ODE.
        % Must be an instance of any solvers.BaseSolver subclass.
        %
        % See also: solvers BaseSolver ode23 ode45 ode113
        %
        % @propclass{important} Choose an appropriate ODE solver for your
        % system.
        %
        % @type solvers.BaseSolver @default solvers.MLWrapper(ode23)
        ODESolver;
        
        % Determines if the simulation should plot intermediate steps
        % during computation.
        %
        % Disabled by default.
        %
        % @propclass{optional} Additionally displays the system's plot
        % during simulations.
        %
        % @default false @type logical
        RealTimePlotting;
        
        % The default parameter value if none is given
        %
        % @type colvec<double> @default []
        DefaultMu = [];
    end
    
    properties(SetAccess=private)
        % The scaled timestep `\tilde{\Delta t} = \frac{\Delta t}{\tau}`
        %
        % @note Due to performance reasons this property is not computed
        % dependently but fitted any time dt or tau are changed.
        %
        % If tau is used, this value is `\tilde{dt} = dt/\tau`
        %
        % @default .1 (as in dt)
        % See also: tau dt
        dtscaled = .1;
        
        % Contains the GIT revision of this model when it was last saved.
        %
        % This field is automatically set upon saveobj.
        %
        % @type char @default ''
        gitRefOnSave = '';
        
        % A struct with fields according to the parameter names and the
        % parameter indices as their values.
        %
        % @type struct
        %ParamIdx;
    end
    
    properties(Dependent)
        % The size of the matrix containing the current full state space
        % trajectory depending on the spatial and temporal resolution.
        %
        % The unit is GB.
        %
        % @type double
        FullStateTrajectorySize;
    end
    
    properties(Access=private)
        ftau = 1;
        fdt = .1;
        fT = 1;
        frtp = false;
        fODEs;
        steplistener;
        ctime;
        fDefMu = [];
    end
    
    methods
        
        function this = BaseModel
            
            % Call superclass constructor first
            % (not necessary in this version as automatically called first, but one never knows..)
            this = this@KerMorObject;
            
            % Init defaults
            this.ODESolver = solvers.MLWrapper(@ode23);
            
            % Register default properties
            this.registerProps('System','T','ODESolver','dt','G',...
                'tau','RealTimePlottingMinPause','RealTimePlotting');
        end
        
        function delete(this)
           this.ODESolver = [];
           this.System = [];
        end
        
        function initDefaultParameter(this)
            % Reads the default values of the System's ModelParam list and
            % initializes the BaseModel.DefaultMu with it.
            mu = zeros(this.System.ParamCount,1);
            %p = struct;
            for k = 1:this.System.ParamCount
                mu(k) = this.System.Params(k).Default;
                %name = regexprep(this.System.Params(k).Name,'[^A-Za-z0-9_]', '_');
                %p.(name) = k;
            end
            this.fDefMu = mu;
            %this.ParamIdx = p;
        end
        
        function [t, y, sec, x] = simulate(this, mu, inputidx)
            % Simulates the system and produces the system's output.
            %
            % Both parameters are optional. (Which to provide will be
            % determined by the actual system anyways)
            %
            % Parameters:
            % mu: The concrete mu parameter sample to simulate for. @type
            % colvec<double>
            % inputidx: The index of the input function to use. @type
            % integer
            %
            % Return values:
            % t: The times at which the model was evaluated @type rowvec<double>
            % y: Depending on the existance of an output converter, this
            %    either returns the full trajectory or the processed output
            %    at times t. @type matrix<double>
            % sec: the seconds needed for simulation. @type double
            % x: The (scaled, if used) state space variables before output conversion.
            %
            % @todo: fix Input checks (set inidx=1 iff one input is
            % there, otherwise error)
            % @todo: switch return arguments sec & x + tests
            if nargin < 3
                inputidx = this.DefaultInput;
                if nargin < 2
                    mu = this.DefaultMu;
                end
            end
            % Transpose if necessary
            if size(mu,2) > 1 && size(mu,1) == 1
                mu =mu';
            end
            this.WorkspaceVariableName = inputname(1);
            
            if this.RealTimePlotting
                this.ctime = tic;
            end
            if this.isStatic
                % solve as series of static equations
                % works only for linear systems.
                [t, x, time] = this.solveStatic(mu, inputidx);
            else
                
                % Get scaled state trajectory
                [t, x, time] = this.computeTrajectory(mu, inputidx);
            end
            % Measure rest of time
            starttime = tic;
            
            % Convert to output
            y = this.System.computeOutput(x);
            
            % Scale times back to real units
            t = t*this.tau;
            
            sec = toc(starttime) + time;
            
            this.WorkspaceVariableName = '';
        end
        
        function [f, ax] = plot(this, t, y, varargin)
            % Plots the results of the simulation.
            % Override in subclasses for a more specific plot if desired.
            %
            % Parameters:
            % t: The simulation times `t_i` @type rowvec<double>
            % y: The simulation output matrix `y`, i.e. `y(t_i)` @type
            % matrix<double>
            % varargin: Any further arguments for customized plots
            %
            % Return values:
            % f: The figure handle @type handle
            % ax: The axes handle @type handle
            if isempty(varargin)
                f = figure;
                ax = gca(f);
            else
                ax = varargin{1};
                f = get(ax,'Parent');
            end
            y = Utils.preparePlainPlot(y);
            plot(ax,t,y);
            title(ax,sprintf('Output plot for model "%s"', this.Name));
            xlabel(ax,'Time'); ylabel(ax,'Output values');
        end
        
        function [f, ax] = plotState(this, t, x, varargin)
            % Plots the results of the simulation.
            % Override in subclasses for a more specific plot if desired.
            %
            % Parameters:
            % t: The simulation times `t_i` @type rowvec
            % x: The simulation state space matrix `x`, i.e. `x(t_i)` @type
            % matrix<double>
            % varargin: Any further arguments for customized plots
            %
            % Return values:
            % f: The figure handle @type handle
            % ax: The axes handle @type handle
            if isempty(varargin)
                f = figure;
                ax = gca(f);
            else
                ax = varargin{1};
                f = get(ax,'Parent');
            end
            x = Utils.preparePlainPlot(x);
            plot(ax,t,x);
            title(ax,sprintf('State space plot for model "%s"', this.Name));
            xlabel(ax,'Time'); ylabel(ax,'State space values');
        end
        
        function [f,ax] = plotSingle(this, t, y, varargin)
            % Plots a single solution.
            % Override in subclasses for specific plot behaviour.
            %
            % The default method is simply to use the full plot default
            % method.
            %
            % Parameters:
            % t: The current time `t` @type double
            % y: The system's output `y(t)` @type colvec<double>
            % varargin: Any arguments that should be passed on to inner plotting methods (model
            % dependent)
            [f,ax] = this.plot(t, y, varargin{:});
        end
        
        function plotInputs(this, pm)
            if nargin < 2
                pm = PlotManager;
                pm.LeaveOpen = true;
            end
            h = pm.nextPlot('inputs','Model inputs','t','u(t)');
            hold(h,'on');
            leg = {};
            cg = LineSpecIterator;
            for k=1:this.System.InputCount
                plot(h,this.Times,this.System.Inputs{k}(this.scaledTimes),'Color',cg.nextColor);
                leg{k} = sprintf('u_%d(t)',k);%#ok
            end
            legend(h,leg{:});
            pm.done;
        end
        
        function [t, x, ctime] = solveStatic(this, mu, inputidx)
            % Solves the linear system `A(t,\mu)*x + f(t,\mu) + B(t,\mu)*u(t) = 0`. 
            % Spatial dependence of f is neglected in the current
            % implementation (since this would require solving a nonlinear
            % system).
            if nargin < 3
                inputidx = [];
                if nargin < 2
                    mu = [];
                end
            end
            sys = this.System;
            % Stop the time
            st = tic;
            
            % Prepare the system by setting mu and inputindex.
            sys.prepareSimulation(mu, inputidx);
            t = this.scaledTimes;
            
            % Prepare the right-hand side
            rhs = zeros(size(sys.A.evaluate(1,0),1), length(t));
            if ~isempty(sys.B)
                if ~sys.B.TimeDependent
                    rhs = sys.B.evaluate(0, sys.mu)*sys.u(t);
                else
                    for tdx = 1:length(t)
                        rhs(:,tdx) = sys.B.evaluate(t(tdx), sys.mu)*sys.u(t(tdx));
                    end
                end
            end
            if ~isempty(sys.f)
                rhs = rhs + sys.f.evaluateMulti(zeros(sys.f.xDim,0), t, repmat(sys.mu,1,length(t)));
            end
            
            % solve the system A*x + rhs = 0 for x
            if ~sys.A.TimeDependent
                % precompute lu decomposition
                [l,u] = lu(sys.A.evaluate(1,0,sys.mu));
                x = -u\(l\rhs);
            else
                x = zeros(sys.A.xDim, length(t));
                for tdx = 1:length(t) 
                    x(:,tdx) = -sys.A.evaluate(1,t(tdx),sys.mu)\rhs(:,tdx);
                end
            end
            
            ctime = toc(st);
        end
        
        function [t, x, ctime] = computeTrajectory(this, mu, inputidx)
            % Computes a solution/trajectory for the given mu and inputidx in the SCALED state
            % space.
            %
            % Parameters:
            % mu: The parameter `\mu` for the simulation @type colvec<double>
            % inputidx: The integer index of the input function to use. If
            % more than one inputs are specified this is a necessary
            % argument. @type integer
            %
            % Return values:
            % t: The times at which the model was evaluated. Will equal the property Times
            % @type rowvec<double>
            % x: The state variables at the corresponding times t. @type matrix<double>
            % ctime: The time needed for computation. @type double
            %
            % @change{0,7,dw,2013-03-19} Fixed the MaxStep setting of the ODE solver when
            % time-scaling is used.
            if nargin < 3
                inputidx = this.DefaultInput;
                if nargin < 2
                    mu = this.DefaultMu;
                end
            end
            sys = this.System;
            
            % Stop the time
            st = tic;
            
            % Prepare the system by setting mu and inputindex.
            sys.prepareSimulation(mu, inputidx);
            
            % Check explicit solvers
            if isempty(this.System.MaxTimestep) && this.fODEs.SolverType ~= solvers.SolverTypes.Implicit
                warning('Attention: Using an non-implicit solver without System.MaxTimestep set. Please check.');
            end
            
            %% Solve ODE
            slv = this.ODESolver;
            slv.MaxStep = []; slv.InitialStep = [];
            if ~isempty(sys.MaxTimestep)
                % Remember: When scaling is used, these are the 
                slv.MaxStep = sys.MaxTimestep/this.tau;
                slv.InitialStep = .5*sys.MaxTimestep/this.tau;
            end
            
            % Assign jacobian information if available
            if isa(slv,'solvers.AJacobianSolver')
                slv.JPattern = sys.SparsityPattern;
                slv.JacFun = @sys.getJacobian;
            end
            
            % Assign mass matrix to solver if present
            slv.M = [];
            if ~isempty(sys.M)
                slv.M = sys.getMassMatrix;
            end
            
            % Call solver
            [t, x] = slv.solve(@sys.ODEFun, this.scaledTimes, sys.getX0(mu));
            
            if length(this.scaledTimes) == 2
                t = [t(1), t(end)];
                x = [x(:,1), x(:,end)];
            end
            
            % Get used time
            ctime = toc(st);
            fprintf('Finished after %5.3gs (RHS:%d, Jacobians:%d)\n',...
                ctime,sys.nfevals,sys.nJevals);
        end
        
        function mu = getRandomParam(this, num, seed)
            % Gets a random parameter sample from the system's parameter
            % domain P
            %
            % Parameters:
            % num: The number of random parameters to return. @type integer @default 1
            % seed: The seed for the number generator. Leave empty for cputime initialization.
            % @type integer @default 'round(cputime*100)'
            %
            % Return values:
            % mu: A matrix of random parameters within the specified range for this model.
            % @type matrix<double>
            %
            % @change{0,6,dw,2012-07-13} Moved this method from models.BaseFirstOrderSystem to here
            % for more convenience.
            if nargin < 3
                seed = round(cputime*100);
                if nargin < 2
                    num = 1;
                end
            end
            s = this.System;
            r = RandStream('mt19937ar','Seed',seed);
            if s.ParamCount > 0
                pmin = [s.Params(:).MinVal]';
                pmax = [s.Params(:).MaxVal]';
                mu = r.rand(s.ParamCount,num) .* repmat(pmax-pmin,1,num) + repmat(pmin,1,num);
            else
                mu = [];
            end
        end
    end
    
    methods(Access=protected)
        
        function this = saveobj(this)
            % Store the current GIT branch in the object.
            this.gitRefOnSave = KerMor.getGitBranch;
        end
    end
    
    methods(Static, Access=protected)
        function this = loadobj(this, s)
            if ~isa(this,'models.BaseModel') && nargin < 2
                error('The model class has changed but the loadobj method does not implement backwards-compatible loading behaviour.\nPlease implement the loadobj-method in your subclass and pass the loaded object struct as second argument.');
            end
            if nargin == 2
                this.System = s.System;
                this.Name = s.Name;
                this.G = s.G;
                this.RealTimePlottingMinPause = s.RealTimePlottingMinPause;
                this.ftau = s.ftau;
                this.fdt = s.fdt;
                this.fT = s.fT;
                this.frtp = s.frtp;
                this.fODEs = s.fODEs;
                this.steplistener = s.steplistener;
                this.ctime = s.ctime;
                this.dtscaled = s.dtscaled;
                this.gitRefOnSave = s.gitRefOnSave;                
                if isfield(s,'DefaultMu')
                    this.DefaultMu = s.DefaultMu;
                    this.DefaultInput = s.DefaultInput;
                end
            end
            this = loadobj@DPCMObject(this);
        end
    end
    
    methods(Access=protected, Sealed)
        function plotstep(this, src, ed)%#ok
            % Callback for the ODE solvers StepPerformed event that enables
            % during-simulation-plotting.
            y = this.System.computeOutput(ed.States);
            this.plotSingle(ed.Times * this.tau,y);
            drawnow;
            % Gets first set in "simulate"
            per = toc(this.ctime);
            pause(max(0,this.RealTimePlottingMinPause-per));
            this.ctime = tic;
        end
    end
    
    %% Getter & Setter
    methods
        function value = get.Times(this)
            value = this.t0:this.dt:this.T;
        end
        
        function value = get.scaledTimes(this)
            value = this.t0/this.ftau:this.dtscaled:this.Tscaled;
        end
        
        function value = get.Tscaled(this)
            if isempty(this.tau)
                value = this.T;
            else
                value = this.T/this.tau;
            end
        end
        
        function dt = get.dt(this)
            dt = this.fdt;
        end
        
        function tau = get.tau(this)
            tau = this.ftau;
        end
                
        function set.T(this, value)
            if ~isscalar(value) || value < 0
                error('T must be a positive real scalar.');
            elseif value < this.fdt
                warning('Timestep dt must be smaller or equal to T. Using dt=%g',value/2);
                this.fdt = value/2;
            end
            if value ~= this.fT
                this.fT = value;
            end
        end
        
        function set.dt(this, value)
            if ~isscalar(value) || value <= 0
                error('dt must be a positive real scalar.');
            elseif value > this.fT
                error('Timestep dt must be smaller or equal to T.');
            end
            if this.fdt ~= value
                this.dtscaled = value/this.ftau;
                this.fdt = value;
            end
        end
        
        function set.tau(this, value)
            if ~isreal(value) ||~isscalar(value)
                error('tau must be a positive real scalar.');
            end
            if this.ftau ~= value
                this.dtscaled = this.fdt/value;
                this.ftau = value;
            end
        end
        
        function set.System(this, value)
            % @note Usually an empty system is not allowed. But as this is a superclass for
            % both full and reduced models, one
            if ~isempty(value) && ~isa(value,'models.BaseFirstOrderSystem')
                error('The System property must be a subclass of models.BaseFirstOrderSystem.');
            end
            if (isequal(this,value))
                warning('KerMor:selfReference','Careful with self-referencing classes. See BaseFullModel class documentation for details.');
            end
            this.System = value;
        end
        
        function set.G(this, value)
            % @todo check for p.d. and symmetric, -> sparsity?
            if isempty(value)
                error('G must not be empty. Use G=1 for default euclidean scalar product and norms');
            elseif any(abs(value-value') > eps)
                error('G must be symmetric.');
            end
            this.G = value;
        end
        
        function set.ODESolver(this, value)
            this.checkType(value,'solvers.BaseSolver');
            % Add listener if new ODE solver is passed and real time
            % plotting is turned on.
            if this.frtp && this.fODEs ~= value
                if ~isempty(this.steplistener)
                    delete(this.steplistener);
                end
                this.steplistener = value.addlistener('StepPerformed',@this.plotstep);
            end
            this.fODEs = value;
        end
        
        function value = get.ODESolver(this)
            value = this.fODEs;
        end
        
        function set.Name(this, value)
            if ~ischar(value)
                error('name is acharacter field');
            end
            this.Name = value;
        end
        
        function value = get.RealTimePlotting(this)
            value = this.frtp;
        end
        
        function value = get.T(this)
            value = this.fT;
        end
        
        function set.RealTimePlotting(this, value)
            if ~islogical(value)
                error('Value must be boolean.');
            end
            if value
                if isempty(this.steplistener)
                    this.steplistener = this.ODESolver.addlistener('StepPerformed',@this.plotstep);
                end
            else
                if ~isempty(this.steplistener)
                    delete(this.steplistener);
                    this.steplistener = [];
                end
            end
            this.frtp = value;
        end
        
        function set.DefaultMu(this, mu)
            if size(mu,2) > 1
                error('Default param must be a column vector');
            end
            this.fDefMu = mu;
        end
        
        function mu = get.DefaultMu(this)
            if isempty(this.fDefMu)
                this.initDefaultParameter;
            end
            mu = this.fDefMu;
        end
        
        function value = get.FullStateTrajectorySize(this)
            value = NaN;
            if ~isempty(this.System)
                value = this.System.NumTotalDofs*8*length(this.Times)/1024^3;
            end
        end
    end
end

