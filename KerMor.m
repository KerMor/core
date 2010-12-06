classdef KerMor < handle
    % Global configuration class for all KerMor run-time settings.
    %
    %
    % To-Do's for KerMor:
    %
    % @todo message-system �ber alle berechnungen hinaus (ungew�hliche dinge
    % berichten, exit flags etc)
    %
    % @todo laufzeittests f�r reduzierte modelle
    %
    % @todo interface f�r ModelData/Snapshots -> entweder arbeiten auf der
    % Festplatte oder in 4D-Array .. (f�r gro�e simulationen) -> KerMor hat
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
    % @todo Beispiele von ODE's aus Matlab-Docs? (verficiation)
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
    %
    % @todo check warum der error estimator nach einem save vom reduzierten
    % modell nicht gespeichert wird.
    %
    % @todo 16.09.2010: f�r skalarprodukt-kerne eigenes interface
    % implementieren und dann ggf. f�r W=V korrekt projezieren + TEST
    % schreiben!
    %
    % @todo cacher aus RBMatlab portieren/�bertragen!
    %
    % @todo speichermanagement: gro�e matrizen / etc virtuell auf festplatte
    % laden/speichern
    %
    % @todo t-partitioning f�r KerMor? ideen mit markus austauschen!
    %
    % @todo check ob die Norm von kernexpansionen mit offset-term b �hnlich
    % bleibt!
    %
    % @todo MUnit erweitern um benchmark-mode, so das anstelle von "test_"
    % prefix-fkt alle mit "bench_" ausgef�hrt werden; (r�ckgabe ist in dem fall
    % ggf ein struct mit algorithmus und zeiten)
    %
    % @todo eigene POD-Basen f�r verschiedene Teile des systems denen andere
    % physik zugrunde liegt (i.e. f(x) => [f_1(x); f_2(x)]), mit einzelner
    % auswertung? dazu m�sste man indexmatrizen einrichten die die
    % verschiedenen teile von f bezeichnen... (Motivation: "Application of POD
    % and DEIM for MOR of Nonl. Miscible Viscous Flow, Chaturantabut/Sorensen)
    %
    % @todo fehlersch�tzer gegen die volle, nicht projizierte
    % kernelapproximation einrichten? damit kann man den aktuell besch�tzten
    % fehler besser bekommen..
    %
    % @todo sekantenabsch�tzung per kernregression vorab f�r 1D berechnen? dann
    % entf�llt das newton-problem l�sen. interpolation z.B. geht auch f�r
    % fehlerabsch�tzung um die rigorosit�t zu erhalten.
    %
    % @todo timedirty �berarbeiten / rausnehmen etc, sollte auch einzelaufrufe
    % zu offX checken.
    %
    % @todo: umstellen von simulate(mu,inputidx) auf simulate +
    % setMu,setInputidx -> faster evaluation
    
    % DONE Allgemeineres Skalarprodukt def. �ber `<x,y>_G = x^tGy`, default Id
    % DONE Allgemeinere Projektion mit `V,W` und nicht mit `V,V^t`
    % DONE fehler in ODE mit reinformulieren!
    % DONE getConfig-methode: string-ausgabe aller einstellungen (sofern
    % textuell sinnvoll m�glich!) eines Modells
    
    properties
        % The default directory to use for simulation data storage
        DataStoreDirectory = '/datastore';
        
        % The Verbose Mode for KerMor.
        % The higher Verbose is set, the more output is produced.
        Verbose = 1;
    end
    
    methods(Static)
        function theinstance = Instance
            persistent instance;
            if isempty(instance)
                instance = KerMor;
            end
            theinstance = instance;
        end
        
        function setVerbose(value)
            k = KerMor.Instance;
            k.Verbose = value;
        end
    end
    
    methods(Access=private)
        function this = KerMor
        end
    end
    
end