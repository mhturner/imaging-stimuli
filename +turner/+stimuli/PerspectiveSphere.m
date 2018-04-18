classdef PerspectiveSphere < stage.core.Stimulus
    % A 3D sphere stimulus. Made out of a triangle strip.
    % Other children classes must make any textures to be associated with
    % this stimulus
    
    properties
        position = [0, 0, 0]    % Center position in 3D space [x, y, z]
        radius = 1              % Radius in x and z
        height = 1              % Radius in y
        angularPosition = 0     % degrees, horizontal
        orientation = 0         % degrees, vertical
        color = [1, 1, 1]
        opacity = 1
        texture
    end
    
    properties (SetAccess = private)
        numSides    % Number of side of the regular polygon base
        vbo     % Vertex buffer object
        vao     % Vertex array object
        vertexData
    end

    methods
        
        function obj = PerspectiveSphere(numSides)
            % Constructs a 3D sphere stimulus
            if nargin < 1
                numSides = 101;
            end
            obj.numSides = numSides;

        end
        
        function init(obj, canvas)
            init@stage.core.Stimulus(obj, canvas);
            obj.getVertexData();
            obj.vbo = stage.core.gl.VertexBufferObject(canvas, GL.ARRAY_BUFFER, single(obj.vertexData), GL.STATIC_DRAW);

            obj.vao = stage.core.gl.VertexArrayObject(canvas);
            obj.vao.setAttribute(obj.vbo, 0, 4, GL.FLOAT, GL.FALSE, 6*4, 0);
            obj.vao.setAttribute(obj.vbo, 1, 2, GL.FLOAT, GL.FALSE, 6*4, 4*4);

        end
        
        function getVertexData(obj,shiftX,shiftY)
            if nargin < 2
                shiftX = 0;
            end
            if nargin < 3
                shiftY = 0;
            end
            % makes a sphere using a single, long triangle strip
            i = (0:obj.numSides)/obj.numSides;
            phi = i * 1 * pi;  %vertical angles (y)
            theta = i * 2 * pi; %horizontal angles  (x,z)
            
            phiStep = mean(diff(phi));
            thetaStep = mean(diff(theta));

            [PHI, THETA] = meshgrid([phi],[theta theta(1)]); %wrap around horizontally to prevent weird sawtooth artifact at edge
            phi = PHI(:);
            theta = THETA(:);

            stride = 24;
            obj.vertexData = zeros(1, size(phi,1) * 6 * 4);
            obj.vertexData(1:stride:end) = sin(theta) .* sin(phi); %x
            obj.vertexData(2:stride:end) = cos(phi); %y
            obj.vertexData(3:stride:end) = cos(theta) .* sin(phi); %z
            obj.vertexData(4:stride:end) = 1; %?
            obj.vertexData(5:stride:end) = theta / (2*pi) + shiftX; %texture U
            obj.vertexData(6:stride:end) = phi / (pi) + shiftY; %texture V
            
            %next vertex: step on vertical angle (phi)
            obj.vertexData(7:stride:end) = sin(theta) .* sin(phi+phiStep); %x
            obj.vertexData(8:stride:end) = cos(phi+phiStep); %y
            obj.vertexData(9:stride:end) = cos(theta) .* sin(phi+phiStep); %z
            obj.vertexData(10:stride:end) = 1;
            obj.vertexData(11:stride:end) = theta / (2*pi) + shiftX;
            obj.vertexData(12:stride:end) = (phi + phiStep) / (pi) + shiftY;

            %next vertex: step on horizontal angle (theta)
            obj.vertexData(13:stride:end) = sin(theta+thetaStep) .* sin(phi); %x
            obj.vertexData(14:stride:end) = cos(phi); %y
            obj.vertexData(15:stride:end) = cos(theta+thetaStep) .* sin(phi); %z
            obj.vertexData(16:stride:end) = 1;
            obj.vertexData(17:stride:end) = (theta+thetaStep) / (2*pi) + shiftX;
            obj.vertexData(18:stride:end) = phi / (pi) + shiftY;

            %next vertex: step on theta & phi (diagonal)
            obj.vertexData(19:stride:end) = sin(theta+thetaStep) .* sin(phi+phiStep); %x
            obj.vertexData(20:stride:end) = cos(phi+phiStep); %y
            obj.vertexData(21:stride:end) = cos(theta+thetaStep) .* sin(phi+phiStep); %z
            obj.vertexData(22:stride:end) = 1;
            obj.vertexData(23:stride:end) = (theta+thetaStep) / (2*pi) + shiftX;
            obj.vertexData(24:stride:end) = (phi+phiStep) / (pi) + shiftY;
        end
        
    end
    
end