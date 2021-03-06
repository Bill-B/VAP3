%ALL PLOTS
clc
clear

load('Misc/Cirrus_DVE3.mat');

%%
for panel = 1:1%length(FW.Panels)
    
%     DVE = FW.Panels(panel).DVE;

% DVE Size
xo = DVE.xo;
xsi = DVE.xsi;
eta = DVE.eta;
phi_LE = DVE.phiLE;
phi_TE = DVE.phiTE;
nu = DVE.roll;
epsilon = DVE.pitch;
psi = DVE.yaw;


%     clf
%     figure(1)
    hold on
    % DVE Normal Vector
%     quiver3(xo(:,1),xo(:,2),xo(:,3),DVE.norm(:,1),DVE.norm(:,2),DVE.norm(:,3),0,'g');
    
    for n = 1:length(DVE.Index);
            %computing left-leading edge point in local ref. frame
            tempA(1) = -xsi(n) - eta(n)*tand(phi_LE(n));
            tempA(2) = -eta(n);
            tempA(3) = 0;
            
            tempAA = star_glob(tempA,nu(n),epsilon(n),psi(n));
            x1 = tempAA+reshape(xo(n,:),1,3,1);
%             x1 = tempAA+xo(n,:);
            
            % 		computing left-trailing edge point in local ref. frame
            tempA(1) = xsi(n) - eta(n)*tand(phi_TE(n));
            tempA(2) = -eta(n);
            tempA(3) = 0;
            
            tempAA = star_glob(tempA,nu(n),epsilon(n),psi(n));
            x2 = tempAA+reshape(xo(n,:),1,3,1);
            
            %computing right-trailing edge point in local ref. frame
            tempA(1) = xsi(n) + eta(n)*tand(phi_TE(n));
            tempA(2) = eta(n);
            tempA(3) = 0;
            
            tempAA = star_glob(tempA,nu(n),epsilon(n),psi(n));
            x3 = tempAA+reshape(xo(n,:),1,3,1);
            
            %computing right-leading edge point in local ref. frame
            tempA(1) = -xsi(n) + eta(n)*tand(phi_LE(n));
            tempA(2) = eta(n);
            tempA(3) = 0;
            
            tempAA = star_glob(tempA,nu(n),epsilon(n),psi(n));
            x4 = tempAA+reshape(xo(n,:),1,3,1);
            
            fillX = [x1(1) x2(1) x3(1) x4(1) x1(1)];
            fillY = [x1(2) x2(2) x3(2) x4(2) x1(2)];
            fillZ = [x1(3) x2(3) x3(3) x4(3) x1(3)];
            
            fill3(fillX,fillY,fillZ,'b','FaceAlpha',0.25,'EdgeColor','b')
        end
    
    clear x1 x2 x3 x4 tempA tempAA
    
    
%     hold off
    axis equal
    grid on
    
end
