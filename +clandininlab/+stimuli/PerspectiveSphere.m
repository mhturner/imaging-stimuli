classdef PerspectiveSphere < stage.core.Stimulus
    % A 3D sphere stimulus. Made out of a triangle strip.
    % Other children classes must make any textures to be associated with
    % this stimulus
    
    properties
        position = [0, 0, 0]            % Center position in 3D space [x, y, z]
        radius = 1                      % Semisphere radius in x, y, and z
        azimuth = 0                     % degrees, horizontal rotation. + is right
        elevation = 0                   % degrees, vertical rotation. + is up
        orientation = 0                 % degrees, roll rotation. + is clockwise
        color = [1, 1, 1]
        opacity = 1
        phiLimits = [0*pi, 1*pi]    % radians, vertical extent of semi-sphere
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
                numSteps = 100; %must be even
            else
                if mod(numSteps,2) %isodd
                    error('numSteps must be even')
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
            
            % makes a sphere using a single, long strip of  right
            % triangles
            
            %  .2  .4    <-- phi2
            %  |\  |
            %  | \ | ...
            %  |  \|  
            %  .1  .3    <--- phi1
            
            %phi = vertical angles (y). 0:pi gives full sphere
            phiStart = obj.phiLimits(1); phiEnd = obj.phiLimits(2); phiRange = phiEnd - phiStart;
            phi = linspace(phiStart,phiEnd,obj.numSteps);
            
            %theta = horizontal angles  (x,z). 0:2pi gives full sphere
            %pi is straight down -z axis
            thetaStart = obj.thetaLimits(1); thetaEnd = obj.thetaLimits(2); thetaRange = thetaEnd - thetaStart;
            theta = linspace(thetaStart,thetaEnd,obj.numSteps);

            %Step size along each angle (i.e. length of each triangle side)
            phiStep = mean(diff(phi));
            
            %vertically: one horizontal strip at a time
            phi = kron(phi,ones(1,obj.numSteps));
            %horizontally: sweep right then left. Repeat for each pair of
            %strips
            theta = repmat([theta, theta(end:-1:1)],1,(obj.numSteps)/2);

            stride = 12;
            obj.vertexData = zeros(1, size(phi,2) * 6 * 2);
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
        end
        
    end
    
    methods (Access = protected)
        function performDraw(obj)
            modelView = obj.canvas.modelView;
            modelView.push();
            modelView.translate(obj.position(1), obj.position(2), obj.position(3));
            modelView.rotate(obj.orientation, 0, 0, -1);
            modelView.rotate(obj.azimuth, 0, 1, 0);
            modelView.rotate(obj.elevation, -1, 0, 0);
            modelView.scale(obj.radius, obj.radius, obj.radius); %x,y,z
            
            c = obj.color;
            if length(c) == 1
                c = [c, c, c, obj.opacity];
            elseif length(c) == 3
                c = [c, obj.opacity];
            end
            
            % STRIDE here is 2 * (obj.numSteps)*(obj.numSteps)
            %   2 vertices defined in each iteration above. Do that for
            %   each phi (numSteps) and theta (numSteps)
            obj.canvas.drawArray(obj.vao, GL.TRIANGLE_STRIP, 0, 2*(obj.numSteps)*(obj.numSteps), c, [], obj.texture);
            
            modelView.pop();
        end
    end
    
    
end