% @TODO message-system �ber alle berechnungen hinaus (ungew�hliche dinge
% berichten, exit flags etc)
% @TODO laufzeittests f�r reduzierte modelle
% @TODO interface f�r ModelData/Snapshots -> entweder arbeiten auf der
% Festplatte oder in 4D-Array .. (f�r gro�e simulationen)
% @TODO mehr tests / anwendungen f�r mehrere inputs aber keine parameter!
% @TODO Verbose-Level benutzen / anpassen
% @TODO test f�r rotationssensitive kerne!
% @TODO: snapshotgenerierung -> mit fehlersch�tzer ausw�hlen! (3-4
% zuf�llig, dann approx, fehler -> neuen snapshot beim gr��ten fehler etc)
% @TODO: moving least squares (mit gewichtsfkt) f�r general.regression ..
% -> book scattered data approx
% @TODO: fft-approximation (?)
% @TODO: Kern mit `\Phi(x,y) = (1-||x-y||_2)_+` oder so
% @TODO: p-partitioning
% @TODO: adaptive svr (impl. \nu-SVR, dann snapshots adden bis tol
% erreicht)
% @TODO: zusammenlegen von funktionen / erstellen eines general-modules f�r
% KerMor/rbmatlab?
% @TODO: try..catch langsam?
% test: zeitabh�ngige outputconvertierung?
% testing.MUnit auch f�r "nicht-packages"
% datenhaltung auf festplatte (mu,inputidx-indiziert) (?) => 
%   - berechnung kernmatrix in teilen...
%   - hashfunktion bernard / ggf eigene interface-fkt f�r eindeutige dirnames
% parfor f�r sampling / comp-wise approximation? (snaphshot-generation/approx)
 

% preferences
setpref('Internet','SMTP_Server','localhost');

% get current directory;
disp('Starting up KerMor in directory:');
p = fileparts( which('startup_kermor'));
disp(p);

% add further paths to MATLABPATH
addpath(p);

% For PCAfixspace
addpath('/afs/.mathe/project/agh/home/dwirtz/rbmatlab/general/vecmat');

cd(p);
clear('p');