function [valCL, valCD, valPREQ, valVINF, valLD] = fcnVISCOUS_WING(valCL, valCDI, valWEIGHT, valAREA, valDENSITY, valKINV, vecDVENFREE, vecDVENIND, ...
    vecDVELFREE, vecDVELIND, vecDVESFREE, vecDVESIND, vecDVEPANEL, vecDVELE, vecDVEWING, vecN, vecM, vecDVEAREA, ...
    matCENTER, vecDVEHVCRD, vecAIRFOIL, flagVERBOSE, vecSYM, valVSPANELS, matVSGEOM, valFPANELS, matFGEOM, valFTURB, ...
    valFPWIDTH, valINTERF, vecDVEROLL)

q_inf = valWEIGHT/(valCL*valAREA);
valVINF = sqrt(2*q_inf/valDENSITY);
di = valCDI*valAREA*q_inf;

% Summing freestream and induced forces of each DVE
vecDVECN = (vecDVENFREE + vecDVENIND);
vecDVECL = (vecDVELFREE + vecDVELIND);
vecDVECY = (vecDVESFREE + vecDVESIND);

[ledves, ~, ~] = find(vecDVELE > 0);
lepanels = vecDVEPANEL(ledves);

vecCNDIST = [];
vecCLDIST = [];
vecCYDIST = [];
matXYZDIST = [];
vecLEDVEDIST = [];
vecREDIST = [];
vecAREADIST = [];

for i = 1:max(vecDVEWING)
    
    %% Getting the CL, CY, CN distribution
    idxdve = ledves(vecDVEWING(ledves) == i);
    idxpanel = lepanels(vecDVEWING(ledves) == i);
    
    m = vecM(idxpanel);
    if any(m - m(1))
        disp('Problem with wing chordwise elements.');
        break
    end
    
    m = m(1);
    len = length(vecCLDIST); % start point for this panel in the vectors
    
    % Matrix of how much we need to add to an index to get the next chordwise element
    % It is done this way because n can be different for each panel. Unlike in the wake,
    % we can't just add a constant value to get to the same spanwise location in the next
    % row of elements
    tempm = repmat(vecN(idxpanel), 1, m).*repmat([0:m-1],length(idxpanel),1);
    
    rows = repmat(idxdve,1,m) + tempm;
    
    % This will NOT work with rotors, it does not take into
    % account freestream! UINF^2*AREA should be the denominator
    vecCNDIST = [vecCNDIST; (sum(vecDVECN(rows),2).*2)./(sum(vecDVEAREA(rows),2))];
    vecCLDIST = [vecCLDIST; (sum(vecDVECL(rows),2).*2)./(sum(vecDVEAREA(rows),2))];
    vecCYDIST = [vecCYDIST; (sum(vecDVECY(rows),2).*2)./(sum(vecDVEAREA(rows),2))];
    
    % The average coordinates for this row of elements
    matXYZDIST = [matXYZDIST; mean(permute(reshape(matCENTER(rows,:)',3,[],m),[2 1 3]),3)];
    
    % The leading edge DVE for the distribution
    vecLEDVEDIST = [vecLEDVEDIST; idxdve];
    
    %% Wing/horizontal stabilizer lift and drag
    
    vecREDIST = [vecREDIST; valVINF.*2.*sum(vecDVEHVCRD(rows),2)./valKINV];
    vecAREADIST = [vecAREADIST; sum(vecDVEAREA(rows),2)];
    
    for j = 1:length(idxpanel)
        pan = idxpanel(j);
        airfoil = dlmread(strcat('airfoils/airfoil',num2str(vecAIRFOIL(pan)),'.dat'),'', 1, 0);
        
        HiRe = airfoil(end,4);
        LoRe = airfoil(1,4);
        
        cl = vecCNDIST(len + j);
        
        if vecREDIST(len + j) > HiRe
            if flagVERBOSE == 1
                fprintf('\nRe higher than airfoil Re data')
            end
            Re2 = airfoil(end,4);
            temp_var = airfoil(airfoil(:,4) == Re2, 2);
            cl_max = temp_var(end);
        elseif vecREDIST(len + j) < LoRe
            if flagVERBOSE == 1
                fprintf('\nRe lower than airfoil Re data');
            end
            Re2 = airfoil(1,4);
            temp_var = airfoil(airfoil(:,4) == Re2, 2);
            cl_max = temp_var(end);
        else
            re1 = airfoil(airfoil(:,4) < vecREDIST(len + j), 4);
            re1 = re1(end);
            cl_max1 = airfoil(airfoil(:,4) < vecREDIST(len + j), 2);
            cl_max1 = cl_max1(end);
            
            temp_var = airfoil(airfoil(:,4) > vecREDIST(len + j),4);
            re2 = temp_var(1);
            temp_var = airfoil(airfoil(:,4) == (temp_var(1)), 2);
            cl_max2 = temp_var(end);
            
            cl_max = interp1([re1 re2],[cl_max1 cl_max2], vecREDIST(len + j));
        end
        
        % correcting the section cl if we are above cl_max
        if cl > cl_max
            if flagVERBOSE == 1
                fprintf('\nStall of Wing %d Section %d, cl = %f Re = %0.0f', i, j, cl, vecREDIST(len + j))
            end
            vecCNDIST(len + j) = 0.825*cl_max; % setting the stalled 2d cl
        end
        
        F = scatteredInterpolant(airfoil(:,4), airfoil(:,2), airfoil(:,3),'nearest');
        vecCDPDIST(len + j, 1) = F(vecREDIST(len + j), cl);
        
        % Octave:
        % vecCDPDIST(len + j, 1) = griddata(airfoil(:,4), airfoil(:,2), airfoil(:,3), vecREDIST(len + j), cl, 'nearest');
        
    end
end

dprof = sum(vecCDPDIST.*q_inf.*vecAREADIST);

% This function does not account for symmetry well, it is all or nothing with symmetry,
% but it really should be wing-by-wing
if any(vecSYM) == 1
    dprof = 2.*dprof;
end

%% Vertical tail drag

dvt = 0;
for ii = 1:valVSPANELS
    Re = valVINF*matVSGEOM(ii,2)/valKINV;
    
    % Load airfoil data
    airfoil = dlmread(strcat('airfoils/airfoil',num2str(matVSGEOM(ii,4)),'.dat'),'', 1, 0);
    
    % determining the drag coefficient corresponding to lift
    % coefficient of 0
    
    % MATLAB:
    F = scatteredInterpolant(airfoil(:,4), airfoil(:,2), airfoil(:,3),'nearest');
    cdvt = F(Re, 0);
    % Octave:
    % cdvt = griddata(Temp.Airfoil(:,4), Temp.Airfoil(:,2), Temp.Airfoil(:,3), Re, 0, 'nearest');
    
    dvt = dvt + cdvt*matVSGEOM(ii,3);
end

dvt = dvt*q_inf;

%% Fuselage drag

dfuselage = 0;

tempSS = valVINF*valFPWIDTH/valKINV;

for ii = 1:valFPANELS
    Re_fus = (ii-0.5)*tempSS;
    if ii < valFTURB
        cdf = 0.664/sqrt(Re_fus); % Laminar
    else
        cdf = 0.0576/(Re_fus^0.2); % Turbulent
    end
    
    dfuselage = dfuselage + cdf*matFGEOM(ii,2)*pi*valFPWIDTH;
end

dfuselage = dfuselage*q_inf;

%% Total Drag

dtot = di + dprof + dvt + dfuselage;

dint = dtot*(valINTERF/100);

dtot = dtot + dint;

valCD = dtot/(q_inf*valAREA);


%% Adjusting CL for stall

valCL = sum(vecCNDIST.*vecAREADIST.*cos(vecDVEROLL(vecLEDVEDIST)))/valAREA*2;

%% Final calculations

valVINF = sqrt((2.*valWEIGHT)./(valDENSITY.*valAREA.*valCL));
valLD = valCL./valCD;
valPREQ = dtot.*valVINF;


end

