presentation = stage.core.Presentation(10);
windowSize = [2*912, 1140]./2;
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
Rectangle.color = [1 1 1];

Rectangle.width = 10;
Rectangle.height = 20;
Rectangle.rectOrientation = 45;

Rectangle.elevation = 30;
Rectangle.azimuth = -45;

thetaSpeed = 20;
thetaStart = Rectangle.azimuth;

phiSpeed = 0;
phiStart = Rectangle.elevation;

thetaC = stage.builtin.controllers.PropertyController(Rectangle, 'azimuth',@(state)thetaStart + thetaSpeed*state.time);
phiC = stage.builtin.controllers.PropertyController(Rectangle, 'elevation',@(state)phiStart + phiSpeed*state.time);

presentation.addStimulus(Rectangle);
presentation.addController(thetaC);
presentation.addController(phiC);
presentation.play(canvas);

