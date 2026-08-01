%% animate_msd.m

clear; clc; close all;

%% Parameters & ODE solution 
m = 1;      
c = 2;      
k = 16; 

y0 = 1;     
v0 = 0;    

tEnd = 10;                       
odefun = @(t, x) [x(2); -(c/m)*x(2) - (k/m)*x(1)];
[tRaw, X] = ode45(odefun, [0 tEnd], [y0; v0]);
yRaw = X(:,1);

% Interpolate to a uniform 30 fps grid
fps = 30;
t = 0:(1/fps):tEnd;
y = interp1(tRaw, yRaw, t, 'spline');

%% Geometry setup (shared by animation + composite)
geom.ceilingY   = 2;
geom.restLen    = 1.2;      
geom.massSize   = 0.5;
geom.dashX      = 0.4;     
geom.cylTop     = geom.ceilingY - 0.2;
geom.cylHeight  = 0.5;
geom.cylBottom  = geom.cylTop - geom.cylHeight;
geom.cylWidth   = 0.25;
geom.pistonTop  = geom.cylBottom + 0.15;   
geom.pistonWidth = 0.08;

%% Live animation with video export 
fig = figure('Name', 'animate_msd', 'Color', 'w');
ax = axes(fig); hold(ax, 'on'); axis(ax, 'equal');
xlim(ax, [-1.5 1.5]); ylim(ax, [-2.5 2.5]);
ylabel(ax, 'Displacement, y (m)');
set(ax, 'XTick', []); grid(ax, 'on');

v = VideoWriter('msd_animation.mp4', 'MPEG-4');
v.FrameRate = fps;
open(v);

screenshotTargets = [0, 1, 5];   
screenshotDone = false(size(screenshotTargets));

for i = 1:length(t)
    cla(ax);
    drawSystemFrame(ax, geom, y(i));
    title(ax, sprintf('Mass-Spring-Damper Animation  (t = %.2f s)', t(i)));
    drawnow;

    writeVideo(v, getframe(fig));

    
    for s = 1:length(screenshotTargets)
        if ~screenshotDone(s) && t(i) >= screenshotTargets(s)
            exportgraphics(fig, sprintf('frame_t%d.png', screenshotTargets(s)), 'Resolution', 200);
            screenshotDone(s) = true;
        end
    end
end
close(v);

%% Composite 2x4 grid (Figure 15)
compositeTimes = [0 1 2 3 4 5 6 8];

figComp = figure('Name', 'Composite Timeline', 'Color', 'w', 'Position', [100 100 1400 700]);
for j = 1:length(compositeTimes)
    axC = subplot(2, 4, j);
    hold(axC, 'on'); axis(axC, 'equal');
    xlim(axC, [-1.5 1.5]); ylim(axC, [-2.5 2.5]);
    set(axC, 'XTick', [], 'YTick', []);

    [~, idx] = min(abs(t - compositeTimes(j)));
    drawSystemFrame(axC, geom, y(idx));
    title(axC, sprintf('t = %d s', compositeTimes(j)));
end
sgtitle(figComp, 'Mass-Spring-Damper: Composite Animation Timeline');
exportgraphics(figComp, 'composite_frames.png', 'Resolution', 200);

%% Local function

function drawSystemFrame(ax, geom, yVal)
% Draws one static frame of the mass-spring-damper system into axes ax
% for the current displacement yVal. Reused by both the live animation
% and the composite grid so every figure looks identical in style.

    massTopY = geom.ceilingY - geom.restLen - yVal;

    % fixed ceiling
    plot(ax, [-0.6 0.6], [geom.ceilingY geom.ceilingY], 'k', 'LineWidth', 4);
    yline(ax, geom.ceilingY - geom.restLen, '--', 'Color', [0.6 0.6 0.6]);

    % spring (zigzag from ceiling to mass)
    [sx, sy] = zigzagSpring(0, geom.ceilingY, 0, massTopY, 8, 0.18);
    plot(ax, sx, sy, 'b', 'LineWidth', 1.5);

    % dashpot: two overlapping rectangles (cylinder + piston rod) 
    rectangle(ax, 'Position', [geom.dashX - geom.cylWidth/2, geom.cylBottom, geom.cylWidth, geom.cylHeight], 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'k', 'LineWidth', 1.2);

    pistonBottom = massTopY;
    pistonHeight = max(geom.pistonTop - pistonBottom, 0.05);
    rectangle(ax, 'Position', [geom.dashX - geom.pistonWidth/2, pistonBottom, geom.pistonWidth, pistonHeight], 'FaceColor', [0.85 0.33 0.1], 'EdgeColor', 'k', 'LineWidth', 1);

    % --- mass block ---
    rectangle(ax, 'Position', [-geom.massSize/2, massTopY - geom.massSize, geom.massSize, geom.massSize], 'FaceColor', [0.2 0.6 0.9], 'Curvature', 0.1);
end

function [xz, yz] = zigzagSpring(x1, y1, x2, y2, nZig, width)
% Generates zigzag coordinates for drawing a spring between two points
    n = 2*nZig + 2;
    xz = zeros(1, n);
    yz = linspace(y1, y2, n);
    xz(1) = x1; xz(end) = x2;
    for j = 2:n-1
        if mod(j,2) == 0
            xz(j) = x1 + width;
        else
            xz(j) = x1 - width;
        end
    end
end