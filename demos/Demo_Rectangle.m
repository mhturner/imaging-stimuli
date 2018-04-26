presentation = stage.core.Presentation(10);
windowSize = [912, 1140]./2;
window = stage.core.Window(windowSize, false);
canvas = stage.core.Canvas(window);

%Set projection matrix
projection = stage.core.gl.MatrixStack();
projection.flyPerspective(windowSize);
canvas.setProjection(projection); %set perspective

%Backround
Background = clandininlab.stimuli.PerspectiveSphere;
Background.color = 0.5;
presentation.addStimulus(Background);

Rectangle = clandininlab.stimuli.Rectangle();
Rectangle.color = [1 0 0];

Rectangle.radius = 1;
Rectangle.opacity = 0.5;

Rectangle.position = [0 0 0];
Rectangle.azimuth = 0;
Rectangle.elevation = 0;
Rectangle.orientation = 0;
Speed_degPerSecond = 0;

mask = stage.core.Mask.createCircularAperture(0.5, 1024);
Rectangle.setMask(mask);

controller = stage.builtin.controllers.PropertyController(Rectangle, 'azimuth', @(state)Speed_degPerSecond*state.time);

presentation.addStimulus(Rectangle);
presentation.addController(controller);

presentation.play(canvas);
%%
presentation = stage.core.Presentation(10);
windowSize = [912, 1140]./2;
window = stage.core.Window(windowSize, false);
canvas = stage.core.Canvas(window);

%Set projection matrix
projection = stage.core.gl.MatrixStack();
projection.flyPerspective(windowSize);
canvas.setProjection(projection); %set perspective

%Backround
Background = stage.builtin.stimuli.Cylinder;
Background.color = 0.5;
presentation.addStimulus(Background);

imagesDir = '~/Dropbox/ClandininLab/imaging-stimuli/resources/images/';
butterflyImage = imread(fullfile(imagesDir, 'butterfly.jpg'));

Cyl = stage.builtin.stimuli.Cylinder();
Cyl.setImageMatrix(butterflyImage);

Cyl.radius = 1;
Cyl.height = 1;

Cyl.position = [0 0 -2];
% Rectangle.azimuth = 0;
% Rectangle.elevation = 0;
Cyl.orientation = 0;
Speed_degPerSecond = 0;

controller = stage.builtin.controllers.PropertyController(Cyl, 'orientation', @(state)Speed_degPerSecond*state.time);

presentation.addStimulus(Cyl);
% presentation.addController(controller);

presentation.play(canvas);
%%
windowSize = [912, 1140]./2;
window = stage.core.Window(windowSize, false);
canvas = stage.core.Canvas(window);

projection = stage.core.gl.MatrixStack();
projection.perspective(90, canvas.width/canvas.height);
canvas.setProjection(projection);

cylinder = stage.builtin.stimuli.Cylinder();
cylinder.position = [0 0 0];
cylinder.opacity = 0.5;

imagesDir = fullfile(fileparts(mfilename('fullpath')), 'Images');
butterflyImage = imread(fullfile(imagesDir, 'butterfly.jpg'));
cylinder.setImageMatrix(butterflyImage);

cylinderAngularController = stage.builtin.controllers.PropertyController(cylinder, 'angularPosition', @(state)360*state.time/8);

presentation = stage.core.Presentation(10);
presentation.addStimulus(cylinder);
presentation.addController(cylinderAngularController);

presentation.play(canvas);
    
    


