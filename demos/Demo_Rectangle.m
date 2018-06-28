presentation = stage.core.Presentation(3);
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
Rectangle.width = 20;
Rectangle.height = 20;



currentOrientation = 90;
center = [0, 0];
barSpeed = 45;

Rectangle.azimuth = 0;
Rectangle.elevation = 0;
Rectangle.rectOrientation = currentOrientation;

startPosition = -80;

thetaC = stage.builtin.controllers.PropertyController(Rectangle, 'azimuth',@(state)center(1) + cosd(currentOrientation)*(startPosition + barSpeed*state.time));
phiC = stage.builtin.controllers.PropertyController(Rectangle, 'elevation',@(state)center(2) + sind(currentOrientation)*(startPosition + barSpeed*state.time));

presentation.addStimulus(Rectangle);
presentation.addController(thetaC);
presentation.addController(phiC);

presentation.play(canvas);

