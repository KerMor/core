% @todo message-system �ber alle berechnungen hinaus (ungew�hliche dinge
% berichten, exit flags etc)
%
% @todo laufzeittests f�r reduzierte modelle
%
% @todo interface f�r ModelData/Snapshots -> entweder arbeiten auf der
% Festplatte oder in 4D-Array .. (f�r gro�e simulationen) -> globalconf hat
% string f�r globales datenverzeichnis!
%
% @todo mehr tests / anwendungen f�r mehrere inputs aber keine parameter!
%
% @todo Verbose-Level benutzen / anpassen
%
% @todo test f�r rotationssensitive kerne!
%
% @todo: snapshotgenerierung -> mit fehlersch�tzer ausw�hlen! (3-4
% zuf�llig, dann approx, fehler -> neuen snapshot beim gr��ten fehler etc)
%
% @todo: moving least squares (mit gewichtsfkt) f�r general.regression ..
% -> book scattered data approx
%
% @todo: fft-approximation (?)
%
% @todo: Kern mit `\Phi(x,y) = (1-||x-y||_2)_+` oder so
%
% @todo: p-partitioning
%
% @todo: adaptive svr (impl. `\nu`-SVR, dann snapshots adden bis tol
% erreicht)
%
% @todo: zusammenlegen von funktionen / erstellen eines general-modules f�r
% KerMor/rbmatlab?
%
% @todo: try..catch langsam?
%
% @todo zeitabh�ngige outputconvertierung?
% testing.MUnit auch f�r "nicht-packages"
%
% @todo: datenhaltung auf festplatte (mu,inputidx-indiziert) (?) => 
%   - berechnung kernmatrix in teilen...
%   - hashfunktion bernard / ggf eigene interface-fkt f�r eindeutige dirnames
%
% @todo: parfor f�r sampling / comp-wise approximation? (snaphshot-generation/approx)
%
% @todo benchmarks von
% http://portal.uni-freiburg.de/imteksimulation/downloads/benchmark
% einlesbar machen / einbauen!
%
% @todo Beispiele von ODE's aus Matlab-Docs?
%
% @todo Fehlersch�tzer auf Output beschr�nken/erweitern!
%
% @todo Mehr ODE-Solver (implizit) einbauen, ggf. eigenen RK23 oder so.
%
% @todo LaGrange-koeffizientenfunktionen bei kerninterpolation berechnen!
% ist insgesamt billiger falls `N<<n` 
% @todo: test f�r newton-iteration!
%
% @todo Implementierung Balanced Truncation (mit base class) f�r
% LinearCoreFuns, dann implementierung balanced truncation f�r empirical
% gramians nach paper Lall et al. -> neue subspace reduction method f�r
% nonlin-systems mit inputs! (geht ggf. auch f�r systeme ohne inputs? probieren!)
%
% @todo vielleicht so etwas wie "isValid" f�r jede modellkomponente, das
% vor start von teuren berechnungen pr�ft ob alles so durchgeht und keine
% inkompatibilit�ten auftreten (z.B. krylov - LinearCoreFun)
%
% @todo check ob es eine m�glichkeit gibt zu pr�fen ob alle unterklassen
% von projizierbaren klassen die project-methode der oberklasse aufrufen!?
% k�nnte sonst zu komischen fehlern f�hren..

% DONE Allgemeineres Skalarprodukt def. �ber `<x,y>_G = x^tGy`, default Id
% DONE Allgemeinere Projektion mit `V,W` und nicht mit `V,V^t`
% DONE fehler in ODE mit reinformulieren! 
% DONE getConfig-methode: string-ausgabe aller einstellungen (sofern
% textuell sinnvoll m�glich!) eines Modells

% preferences
setpref('Internet','SMTP_Server','localhost');

% get current directory;
disp('Starting up KerMor in directory:');
p = fileparts( which('startup_kermor'));
disp(p);

% Environment
setenv('KERMORTEMP','/datastore');
setenv('KERMORHOME',p);

% For PCAfixspace
addpath('/afs/.mathe/project/agh/home/dwirtz/rbmatlab/general/vecmat');

% add further paths to MATLABPATH
addpath(p);
cd(p);
addpath(fullfile(p,'examples'));
clear('p');