classdef PerspectiveSphere < stage.core.Stimulus
    % A 3D sphere stimulus. Made out of a triangle strip.
    % Other children classes must make any textures to be associated with
    % this stimulus
    
    properties
        position = [0, 0, 0]            % Center position in 3D space [x, y, z]
        radius = 1                      % Semisphere radius in x and z
        height = 1                      % Semisphere radius in y
        angularPosition = 0             % degrees, horizontal rotation
        orientation = 0                 % degrees, vertical rotation
        color = [1, 1, 1]
        opacity = 1
        phiLimits = [0.2*pi, 0.8*pi]    % radians, vertical extent of semi-sphere
        thetaLimits = [0.5*pi, 1.5*pi]  % radians, horizontal extent of semi-sphere
        
    end
    properties (Access = protected)
        texture
    end
    
    properties (SetAccess = private)
        numSteps    % Number of steps to take along each angular direction for each triangle
        vbo     % Vertex buffer object
        vao     % Vertex array object
        vertexData
    end

    methods
        
        function obj = PerspectiveSphere(numSteps)
            % Constructs a 3D sphere stimulus
            if nargin < 1
                numSteps = 101; %must be odd
            else
                if ~mod(numSteps,2) %iseven
                    error('numSteps must be odd')
                end
            end
            obj.numSteps = numSteps;

        end
        
        function init(obj, canvas)
            init@stage.core.Stimulus(obj, canvas);
            obj.getVertexData();
            obj.vbo = stage.core.gl.VertexBufferObject(canvas, GL.ARRAY_BUFFER, single(obj.vertexData), GL.STATIC_DRAW);

            obj.vao = stage.core.gl.VertexArrayObject(canvas);
            obj.vao.setAttribute(obj.vbo, 0, 4, GL.FLOAT, GL.FALSE, 6*4, 0);
            obj.vao.setAttribute(obj.vbo, 1, 2, GL.FLOAT, GL.FALSE, 6*4, 4*4);
        end
        
        function getVertexData(obj,shiftX,shiftY,nCycles)
            %shiftX and shiftY add to mapping of u,v textures
            %nCycles tells the mapping how many cycles of the texture are
            %painted on the semisphere. For non-repeating textures like
            %images, nCycles should be 1
            if nargin < 2
                shiftX = 0;
            end
            if nargin < 3
                shiftY = 0;
            end
            if nargin < 4
                nCycles = 1;
            end
            
            % makes a sphere using a single, long triangle strip
            %phi = vertical angles (y). 0:pi gives full sphere
            phiStart = obj.phiLimits(1); phiEnd = obj.phiLimits(2); phiRange = phiEnd - phiStart;
            phi = linspace(phiStart,phiEnd,obj.numSteps);
            phi = phi(1:end-1); %trim last to avoid wrap-around. Last step will take care of this
            
            %theta = horizontal angles  (x,z). 0:2pi gives full sphere
            %pi is straight down -z axis
            thetaStart = obj.thetaLimits(1); thetaEnd = obj.thetaLimits(2); thetaRange = thetaEnd - thetaStart;
            theta = linspace(thetaStart,thetaEnd,obj.numSteps);
            theta = theta(1:end-1); %trim last

            %Step size along each angle (i.e. length of each triangle side)
            phiStep = mean(diff(phi));
            thetaStep = mean(diff(theta));
            
            %vertically: one horizontal strip at a time
            phi = kron(phi,ones(1,obj.numSteps-1));
            %horizontally: sweep right then left. Repeat for each pair of
            %strips
            theta = repmat([theta, theta(end:-1:1)],1,(obj.numSteps-1)/2);

            stride = 24;
            obj.vertexData = zeros(1, size(phi,2) * 6 * 4);
            obj.vertexData(1:stride:end) = sin(theta) .* sin(phi); %x
            obj.vertexData(2:stride:end) = cos(phi); %y
            obj.vertexData(3:stride:end) = cos(theta) .* sin(phi); %z
            obj.vertexData(4:stride:end) = 1; %?
            obj.vertexData(5:stride:end) = nCycles * ((theta-thetaStart) / thetaRange) + shiftX; %texture U
            obj.vertexData(6:stride:end) = nCycles * ((phi-phiStart)/ phiRange) + shiftY; %texture V
            
            %next vertex: step on vertical angle (phi)
            obj.vertexData(7:stride:end) = sin(theta) .* sin(phi+phiStep); %x
            obj.vertexData(8:stride:end) = cos(phi+phiStep); %y
            obj.vertexData(9:stride:end) = cos(theta) .* sin(phi+phiStep); %z
            obj.vertexData(10:stride:end) = 1;
            obj.vertexData(11:stride:end) = nCycles * ((theta-thetaStart) / thetaRange) + shiftX;
            obj.vertexData(12:stride:end) = nCycles * (((phi-phiStart) + phiStep) / phiRange) + shiftY;

            %next vertex: step on horizontal angle (theta)
            obj.vertexData(13:stride:end) = sin(theta+thetaStep) .* sin(phi); %x
            obj.vertexData(14:stride:end) = cos(phi); %y
            obj.vertexData(15:stride:end) = cos(theta+thetaStep) .* sin(phi); %z
            obj.vertexData(16:stride:end) = 1;
            obj.vertexData(17:stride:end) = nCycles * (((theta-thetaStart)+thetaStep) / thetaRange) + shiftX;
            obj.vertexData(18:stride:end) = nCycles * ((phi-phiStart) / phiRange) + shiftY;

            %next vertex: step on theta & phi (diagonal)
            obj.vertexData(19:stride:end) = sin(theta+thetaStep) .* sin(phi+phiStep); %x
            obj.vertexData(20:stride:end) = cos(phi+phiStep); %y
            obj.vertexData(21:stride:end) = cos(theta+thetaStep) .* sin(phi+phiStep); %z
            obj.vertexData(22:stride:end) = 1;
            obj.vertexData(23:stride:end) = nCycles * (((theta-thetaStart)+thetaStep) / thetaRange) + shiftX;
            obj.vertexData(24:stride:end) = nCycles * (((phi-phiStart)+phiStep) / phiRange) + shiftY;
        end
        
    end
    
end