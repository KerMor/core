classdef ConstMassMatrix < dscomponents.AMassMatrix
% ConstMassMatrix: 
%
%
%
% @author Daniel Wirtz @date 2011-12-06
%
% @new{0,6,dw,2011-12-06} Added this class.
%
% This class is part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.morepas.org/software/index.html
% - \c Documentation http://www.morepas.org/software/kermor/index.html
% - \c License @ref licensing
    
    properties(SetAccess=private)
        M;
    end
    
    properties(Access=private)
        l;
        u;
        q;
        p;
    end
    
    methods
        
        function this = ConstMassMatrix(M, varargin)
            this = this@dscomponents.AMassMatrix(varargin{:});
            if nargin > 0
                this.M = M;
                this.TimeDependent = false;
                if issparse(M)
                    [this.l, this.u, this.q, this.p] = lu(M);
                else
                    [this.l, this.u] = lu(M);
                    this.q = [];
                    this.p = [];
                end
                % Compute sparsity pattern straight away
                [i, j] = find(M);
                s = size(M,1);
                if issparse(M) || length(i) < numel(M)
                    this.SparsityPattern = sparse(i,j,ones(size(i)),s,s);
                end
            end
        end
        
        function M = evaluate(this, ~, ~)
            M = this.M;
        end
        
        function [L, U, q, p] = getLU(this, ~, ~)
            L = this.l;
            U = this.u;
            q = this.q;
            p = this.p;
        end
        
        function projected = project(this, V, W)
            algdims_correctedoffset = [];
            if ~isempty(this.AlgebraicEquationDims)
                nalgdims = length(this.AlgebraicEquationDims);
                algdims_correctedoffset = size(V,2)-nalgdims+1:size(V,2);
            end
            projected = dscomponents.ConstMassMatrix(W'*(this.M*V),algdims_correctedoffset);
            % Dont store V,W due to hard drive space saving (not really needed here)
            %projected = project@general.AProjectable(this, V, W, projected);
        end
        
        function copy = clone(this)
            copy = clone@dscomponents.AMassMatrix(this, ...
                dscomponents.ConstMassMatrix);
            copy.l = this.l;
            copy.u = this.u;
            copy.q = this.q;
            copy.p = this.p;
            copy.M = this.M;
        end
    end
    
end