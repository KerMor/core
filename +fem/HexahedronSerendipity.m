classdef HexahedronSerendipity < fem.BaseFEM
    % Triquatratic: Quadratic ansatz functions on cube with 20 nodes per
    % cube
    %
    
    methods
        function this = HexahedronSerendipity(geo)
            if nargin < 1
                geo = fem.geometry.Cube20Node;
            end
            this = this@fem.BaseFEM(geo);
        end
   
        function Nx = N(~, x)
            % Triquadratic basis functions
            %
            % N corner index
            % 1 2 3 4 5 6 7 8 9  10 11 12 13 14 15 16 17 18 19 20
            % 1   2     3   4             5     6        7     8  <-Corners
            % Combinatorial corner index
            % 1 2 3 4 6 7 8 9 10 12 16 18 19 20 21 22 24 25 26 27
            % (Missing 5,11,13,14,15,17,23)
            Nx = [(1-x(1,:)).*(1-x(2,:)).*(1-x(3,:)).*(-x(1,:)-x(2,:)-x(3,:)-2)/8;... % C1
                (1-x(1,:).^2).*(1-x(2,:)).*(1-x(3,:))/4;... % E2
                (1+x(1,:)).*(1-x(2,:)).*(1-x(3,:)).*(x(1,:)-x(2,:)-x(3,:)-2)/8;... % C3
                (1-x(2,:).^2).*(1-x(1,:)).*(1-x(3,:))/4;... % E4
                (1-x(2,:).^2).*(1+x(1,:)).*(1-x(3,:))/4;... % E5
                (1-x(1,:)).*(1+x(2,:)).*(1-x(3,:)).*(-x(1,:)+x(2,:)-x(3,:)-2)/8;... % C6
                (1-x(1,:).^2).*(1+x(2,:)).*(1-x(3,:))/4;... % E7
                (1+x(1,:)).*(1+x(2,:)).*(1-x(3,:)).*(x(1,:)+x(2,:)-x(3,:)-2)/8;... % C8
                (1-x(3,:).^2).*(1-x(1,:)).*(1-x(2,:))/4;... % E9    
                (1-x(3,:).^2).*(1+x(1,:)).*(1-x(2,:))/4;... % E10
                (1-x(3,:).^2).*(1-x(1,:)).*(1+x(2,:))/4;... % E11
                (1-x(3,:).^2).*(1+x(1,:)).*(1+x(2,:))/4;... % E12
                (1-x(1,:)).*(1-x(2,:)).*(1+x(3,:)).*(-x(1,:)-x(2,:)+x(3,:)-2)/8;... % C13
                (1-x(1,:).^2).*(1-x(2,:)).*(1+x(3,:))/4;... % E14
                (1+x(1,:)).*(1-x(2,:)).*(1+x(3,:)).*(x(1,:)-x(2,:)+x(3,:)-2)/8;... %C15
                (1-x(2,:).^2).*(1-x(1,:)).*(1+x(3,:))/4;... % E16
                (1-x(2,:).^2).*(1+x(1,:)).*(1+x(3,:))/4;... % E17
                (1-x(1,:)).*(1+x(2,:)).*(1+x(3,:)).*(-x(1,:)+x(2,:)+x(3,:)-2)/8;... % C18
                (1-x(1,:).^2).*(1+x(2,:)).*(1+x(3,:))/4;... % E19
                (1+x(1,:)).*(1+x(2,:)).*(1+x(3,:)).*(x(1,:)+x(2,:)+x(3,:)-2)/8]; % C20
        end

        function dNx = gradN(~, x)
            dNx = [[-(1-x(2,:)).*(1-x(3,:)).*(-x(1,:)-x(2,:)-x(3,:)-2)-(1-x(1,:)).*(1-x(2,:)).*(1-x(3,:)) -(1-x(1,:)).*(1-x(3,:)).*(-x(1,:)-x(2,:)-x(3,:)-2)-(1-x(1,:)).*(1-x(2,:)).*(1-x(3,:)) -(1-x(1,:)).*(1-x(2,:)).*(-x(1,:)-x(2,:)-x(3,:)-2)-(1-x(1,:)).*(1-x(2,:)).*(1-x(3,:))]/8;... % 1
                [-2*x(1,:).*(1-x(2,:)).*(1-x(3,:)) -(1-x(1,:).^2).*(1-x(3,:)) -(1-x(1,:).^2).*(1-x(2,:))]/4;...    
                [(1-x(2,:)).*(1-x(3,:)).*(x(1,:)-x(2,:)-x(3,:)-2)+(1+x(1,:)).*(1-x(2,:)).*(1-x(3,:)) -(1+x(1,:)).*(1-x(3,:)).*(x(1,:)-x(2,:)-x(3,:)-2)-(1+x(1,:)).*(1-x(2,:)).*(1-x(3,:)) -(1+x(1,:)).*(1-x(2,:)).*(x(1,:)-x(2,:)-x(3,:)-2)-(1+x(1,:)).*(1-x(2,:)).*(1-x(3,:))]/8;...
                [-(1-x(2,:).^2).*(1-x(3,:)) -2*x(2,:).*(1-x(1,:)).*(1-x(3,:))  -(1-x(2,:).^2).*(1-x(1,:))]/4;...
                [(1-x(2,:).^2).*(1-x(3,:)) -2*x(2,:).*(1+x(1,:)).*(1-x(3,:))  -(1-x(2,:).^2).*(1+x(1,:))]/4;...
                [-(1+x(2,:)).*(1-x(3,:)).*(-x(1,:)+x(2,:)-x(3,:)-2)-(1-x(1,:)).*(1+x(2,:)).*(1-x(3,:)) (1-x(1,:)).*(1-x(3,:)).*(-x(1,:)+x(2,:)-x(3,:)-2)+(1-x(1,:)).*(1+x(2,:)).*(1-x(3,:)) -(1-x(1,:)).*(1+x(2,:)).*(-x(1,:)+x(2,:)-x(3,:)-2)-(1-x(1,:)).*(1+x(2,:)).*(1-x(3,:))]/8;...
                [-2*x(1,:).*(1+x(2,:)).*(1-x(3,:))  (1-x(1,:).^2).*(1-x(3,:)) -(1-x(1,:).^2).*(1+x(2,:))]/4;...
                [(1+x(2,:)).*(1-x(3,:)).*(x(1,:)+x(2,:)-x(3,:)-2)+(1+x(1,:)).*(1+x(2,:)).*(1-x(3,:)) (1+x(1,:)).*(1-x(3,:)).*(x(1,:)+x(2,:)-x(3,:)-2)+(1+x(1,:)).*(1+x(2,:)).*(1-x(3,:)) -(1+x(1,:)).*(1+x(2,:)).*(x(1,:)+x(2,:)-x(3,:)-2)-(1+x(1,:)).*(1+x(2,:)).*(1-x(3,:))]/8;...
                [-(1-x(3,:).^2).*(1-x(2,:)) -(1-x(3,:).^2).*(1-x(1,:)) -2*x(3,:).*(1-x(1,:)).*(1-x(2,:))]/4;...
                [(1-x(3,:).^2).*(1-x(2,:)) -(1-x(3,:).^2).*(1+x(1,:)) -2*x(3,:).*(1+x(1,:)).*(1-x(2,:))]/4;... %E10

                [-(1-x(3,:).^2).*(1+x(2,:))  (1-x(3,:).^2).*(1-x(1,:)) -2*x(3,:).*(1-x(1,:)).*(1+x(2,:))]/4;...
                [(1-x(3,:).^2).*(1+x(2,:))  (1-x(3,:).^2).*(1+x(1,:)) -2*x(3,:).*(1+x(1,:)).*(1+x(2,:))]/4;...
                [-(1-x(2,:)).*(1+x(3,:)).*(-x(1,:)-x(2,:)+x(3,:)-2)-(1-x(1,:)).*(1-x(2,:)).*(1+x(3,:)) -(1-x(1,:)).*(1+x(3,:)).*(-x(1,:)-x(2,:)+x(3,:)-2)-(1-x(1,:)).*(1-x(2,:)).*(1+x(3,:)) (1-x(1,:)).*(1-x(2,:)).*(-x(1,:)-x(2,:)+x(3,:)-2)+(1-x(1,:)).*(1-x(2,:)).*(1+x(3,:))]/8;...
                [-2*x(1,:).*(1-x(2,:)).*(1+x(3,:)) -(1-x(1,:).^2).*(1+x(3,:))  (1-x(1,:).^2).*(1-x(2,:))]/4;...
                [(1-x(2,:)).*(1+x(3,:)).*(x(1,:)-x(2,:)+x(3,:)-2)+(1+x(1,:)).*(1-x(2,:)).*(1+x(3,:)) -(1+x(1,:)).*(1+x(3,:)).*(x(1,:)-x(2,:)+x(3,:)-2)-(1+x(1,:)).*(1-x(2,:)).*(1+x(3,:)) (1+x(1,:)).*(1-x(2,:)).*(x(1,:)-x(2,:)+x(3,:)-2)+(1+x(1,:)).*(1-x(2,:)).*(1+x(3,:))]/8;...
                [-(1-x(2,:).^2).*(1+x(3,:)) -2*x(2,:).*(1-x(1,:)).*(1+x(3,:))   (1-x(2,:).^2).*(1-x(1,:))]/4;...
                [(1-x(2,:).^2).*(1+x(3,:)) -2*x(2,:).*(1+x(1,:)).*(1+x(3,:))   (1-x(2,:).^2).*(1+x(1,:))]/4;...
                [-(1+x(2,:)).*(1+x(3,:)).*(-x(1,:)+x(2,:)+x(3,:)-2)-(1-x(1,:)).*(1+x(2,:)).*(1+x(3,:)) (1-x(1,:)).*(1+x(3,:)).*(-x(1,:)+x(2,:)+x(3,:)-2)+(1-x(1,:)).*(1+x(2,:)).*(1+x(3,:)) (1-x(1,:)).*(1+x(2,:)).*(-x(1,:)+x(2,:)+x(3,:)-2)+(1-x(1,:)).*(1+x(2,:)).*(1+x(3,:))]/8;...
                [-2*x(1,:).*(1+x(2,:)).*(1+x(3,:))  (1-x(1,:).^2).*(1+x(3,:))  (1-x(1,:).^2).*(1+x(2,:))]/4;...
                [(1+x(2,:)).*(1+x(3,:)).*(x(1,:)+x(2,:)+x(3,:)-2)+(1+x(1,:)).*(1+x(2,:)).*(1+x(3,:)) (1+x(1,:)).*(1+x(3,:)).*(x(1,:)+x(2,:)+x(3,:)-2)+(1+x(1,:)).*(1+x(2,:)).*(1+x(3,:)) (1+x(1,:)).*(1+x(2,:)).*(x(1,:)+x(2,:)+x(3,:)-2)+(1+x(1,:)).*(1+x(2,:)).*(1+x(3,:))]/8];
        end
    end
    
    methods(Static)
        function res = test_QuadraticBasisFun
            q = fem.HexahedronSerendipity;
            res = fem.BaseFEM.test_BasisFun(q);
            
            % test for correct basis function values on nodes
            [X,Y,Z] = ndgrid(-1:1:1,-1:1:1,-1:1:1);
            p = [X(:) Y(:) Z(:)]';
            % Remove 7 (inner points not used here)
            p(:,[5,11,13,14,15,17,23]) = [];
            res = res && isequal(q.N(p),eye(20));
        end
    end
    
end
