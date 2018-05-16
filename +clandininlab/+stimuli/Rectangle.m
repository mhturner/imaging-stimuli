classdef Rectangle < stage.core.Stimulus
    % A rectangle on the surface of a 3D semisphere. Made out of a triangle strip.
    
    properties
        position = [0, 0, 0]            % Center position in 3D space [x, y, z]
        radius = 1                      % Semisphere radius in x, y, and z
        width = 40                      % degrees
        height = 40                     % degrees
        color = [1, 1, 1]
        opacity = 1      
        azimuth = 0                     % degrees, horizontal rotation. + is right
        elevation = 0                   % degrees, vertical rotation. + is up
        rectOrientation = 0             % degrees, + is clockwise
    end
    properties (Access = protected)
        
    end
    
    properties (SetAccess = private)
        numSteps    % Number of steps to take along each angular direction for each triangle
        mask    % Stimulus mask
        vbo     % Vertex buffer object
        vao     % Vertex array object
        vertexData
    end

    methods
        
        function obj = Rectangle(numSteps)
           % Constructs a rectangle painted on a sphere
            if nargin < 1
                numSteps = 200; %must be even
            else
                if mod(numSteps,2) %isodd
                    error('numSteps must be even')
                end
            end
            obj.numSteps = numSteps;
        end
        
        function init(obj, canvas)
            init@stage.core.Stimulus(obj, canvas);
            if ~isempty(obj.mask)
                obj.mask.init(canvas);
            end
            obj.getVertexData();
            obj.vbo = stage.core.gl.VertexBufferObject(canvas, GL.ARRAY_BUFFER, single(obj.vertexData), GL.STATIC_DRAW);

            obj.vao = stage.core.gl.VertexArrayObject(canvas);
            obj.vao.setAttribute(obj.vbo, 0, 4, GL.FLOAT, GL.FALSE, 6*4, 0);
            obj.vao.setAttribute(obj.vbo, 1, 2, GL.FLOAT, GL.FALSE, 6*4, 4*4);
        end
        
        function setMask(obj, mask)
            % Assigns a mask to the stimulus.
            obj.mask = mask;
        end
        
        function getVertexData(obj)
            thetaStart = -obj.width/2; thetaEnd = obj.width/2;
            theta = linspace(thetaStart,thetaEnd, obj.numSteps);
            phiStart = -obj.height/2; phiEnd = obj.height/2;
            phi = linspace(phiStart, phiEnd, obj.numSteps);
            
            %Step size along each angle (i.e. length of each triangle side)
            phiStep = mean(diff(phi));
            
            %vertically: one horizontal strip at a time
            phi = kron(phi,ones(1,obj.numSteps))';
            %horizontally: sweep right then left. Repeat for each pair of
            %strips
            theta = repmat([theta, theta(end:-1:1)],1,(obj.numSteps)/2)';
            
            %coords in theta, phi
            coords = zeros(size(phi,1) * 2, 2);
            coords(1:2:end,:) = [theta, phi];
            coords(2:2:end,:) = [theta, phi + phiStep];
            
            %rotate theta, phi coords according to bar orienation
            R = [cosd(obj.rectOrientation) -sind(obj.rectOrientation);...
                 sind(obj.rectOrientation) cosd(obj.rectOrientation)];
            C = coords * R;
            %Shift center of rectangle in theta, phi space
            C(:,1) = C(:,1) + (180); %flip it around so it's in the center of the sphere down the -z axis
            C(:,2) = C(:,2) + (90);
            %Convert to rad
            C = deg2rad(C);
            
            %map out vertices and convery from theta/phi 2 space to surface
            %of sphere (3 space)
            stride = 6;
            obj.vertexData = zeros(1, size(phi,1) * 6 * 2);
            obj.vertexData(1:stride:end) = sin(C(:,1)) .* sin(C(:,2)); % x
            obj.vertexData(2:stride:end) = cos(C(:,2)); % y
            obj.vertexData(3:stride:end) = cos(C(:,1)) .* sin(C(:,2)); % z
            obj.vertexData(4:stride:end) = 1;
            obj.vertexData(5:stride:end) = (reshape([theta,theta]',1,size(theta,1)*2)-thetaStart) / obj.width; %mask U
            obj.vertexData(6:stride:end) = (reshape([phi,phi+phiStep]',1,size(theta,1)*2)-phiStart)/ obj.height; %mask V
        end
        
    end
    
    methods (Access = protected)
        function performDraw(obj)
            modelView = obj.canvas.modelView;
            modelView.push();
            modelView.translate(obj.position(1), obj.position(2), obj.position(3));
            modelView.rotate(obj.azimuth, 0, -1, 0);
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
            obj.canvas.drawArray(obj.vao, GL.TRIANGLE_STRIP, 0, 2*(obj.numSteps)*(obj.numSteps), c, obj.mask, []);
            
            modelView.pop();
        end
    end
    
end