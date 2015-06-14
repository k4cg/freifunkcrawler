# freifunkcrawler
Bash-Skript zum Sammeln der Anzahl der verbundenen Clients eines oder mehrerer Freifunk Router. PHP-Skript zum Anzeigen der gesammelten Daten als Diagramm.

## Verwendung

### Einrichtung (Abrufen der Daten)

Alle Dateien z.B. in ein Unterverzeichnis `stats` eines htdocs ablegen.

Konfigurationsdatei `freifunkconfig.ini.example.php` nach `freifunkconfig.ini.php` kopieren und persönliche Einstellungen vornehmen.

    title=freifunkstats
    dataDir=./freifunkdata
    totalDir=Total
    netmonUrl=https://netmon.freifunk-franken.de/api/rest/router/
    urlRequester=curl
    inlineJavaScript=false
    chownUser=
    chownGroup=
    
* `title`: HTML-Titel des PHP-Skripts
* `dataDir`: Datenstammverzeichnis für die abgefragten Daten; kann realtiv zum ausführenden Skript (mit einem `.` als erstes Zeichen) oder absolut (mit einem `/` als erstes Zeichen) angegeben werden
* `totalDir`: Unterverzeichnis von `dataDir` in das die Summenwerte gespeichert werden
* `netmonUrl`: Url zur XML-API des Netmon
* `urlRequester`: Programm zum Abrufen der `netmonUrl` (`curl` oder `php`, da manche Webhoster z.B. kein `curl` anbieten)
* `inlineJavaScript`: `false` bindet die JavaScript-Datei ein; `true` bettet den Inhalt der JavaScript-Datei in `freifunk.php` ein
* `chownUser` und `chownGroup`: Wenn das Bash-Skript von einem anderen Benutzer ausgeführt und der Webserver unter einem anderen Benutzer läuft, der dann auf die Datendateien keinen Zugriff hätte, kann man hier entsprechende Werte angeben. Nach dem Speichern der Datendateien werden die Zugriffsrechte entsprechend gesetzt.

Das Skript zur Initialisierung mit dem Parameter `init` aufrufen:

`bash freifunkcrawler.sh init`

Anschliessend kann man das Skript `freifunkcrawler.sh` (ohne Parameter!) regelmäßig (z.B. alle halbe Stunde) via Cron-Job ausführen.

`*/15  *  *   *   *     bash /var/www/gpunktschmitz.de/www/stats/freifunkcrawler.sh`

*Die Daten auf dem (Franken-)Netmon werden nur alle 10 Minuten aktualisiert, daher bringt eine niedrigere Aufrufrate keine aktuelleren Daten.*

### Aufruf (Anzeigen der gesammelten Daten)

Um sich die Statistik anzeigen zu lassen ruft man einfach die `freifunk.php`-Datei auf (diese kann auch beliebig umbenannt werden, z.B. `index.php`).

Eine Anzeige ist erst dann möglich, wenn mindestens zwei Aufrufe des Skripts gemacht wurden (die Initialisierung zählt als ein Mal).

### Datenstruktur (wie es funktioniert)

Das Skript `freifunkcrawler.sh` legt mit dem ersten Aufruf mit dem Parameter `init` für jeden Router ein Verzeichnis im "data folder" an.

    freifunkdata\
                \44
                \966
                \967
                \968
                \969
                \970

Die Anzahl der verbundenen Clients wird im jeweiligen Router-Verzeichnis in eine Datei im Datumsformat `YYYY-MM-DD` abgespeichert.

### Router benennen

Möchte man im Diagramm anstelle der Routernummer einen Namen anzeigen so erstellt man eine Datei `hostname` im jeweiligen Router-Verzeichnis mit dem anzuzeigenden Namen als Inhalt. Der Name wird dann beim Mouse-Over-Effekt angezeigt.

### neue Router hinzufügen

Um neue Router abzufragen muss lediglich im Datenverzeichnis ein Verzeichnis mit der Routernummer angelegt werden. Das Skript fragt die Anzahl der verbundenen Clients für alle Unterverzeichnisse ab.

### Routerabfrage beenden/aussetzen

Möchte man einen Router nicht mehr abfragen, so kann man eine Datei namens `disabled` in das Verzeichnis legen. Somit bleiben die historischen Daten bestehen und die Daten des Router werden nicht mehr aktualisiert. Um die Abfrage wieder zu aktivieren muss die Datei `disabled` gelöscht werden.

# Autoren

[Guenther Schmitz](https://github.com/gpunktschmitz) - http://www.gpunktschmitz.de

# Lizenz
## alle PHP- und Bash-Skripte:
CC0 1.0 Universal <http://creativecommons.org/publicdomain/zero/1.0/>

## Chart.js (js/Chart.min.js):<br />
MIT <https://github.com/nnnick/Chart.js/blob/master/LICENSE.md>
