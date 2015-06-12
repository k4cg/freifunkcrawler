# freifunkcrawler
Bash-Skript zum Sammeln der Anzahl der verbundenen Clients eines oder mehrerer Freifunk Router. PHP-Skript zum Anzeigen der gesammelten Daten als Diagramm.

## Verwendung

### Einrichtung (Abrufen der Daten)

Alle Dateien z.B. in ein Unterverzeichnis `stats` eines htdocs ablegen.

Konfigurationsdatei `freifunkconfig.ini.example.php` nach `freifunkconfig.ini.php` kopieren und persönliche Einstellungen vornehmen.

Das Skript zur Initialisierung mit dem Parameter `init` aufrufen:

`bash freifunkcrawler.sh init`

Anschliessend kann man das Skript `freifunkcrawler.sh` (ohne Parameter!) regelmäßig (z.B. alle halbe Stunde) via Cron-Job ausführen.

`*/15  *  *   *   *     bash /var/www/gpunktschmitz.de/www/stats/freifunkcrawler.sh`

*Die Daten auf dem (Franken-)Netmon werden nur alle 10 Minuten aktualisiert, daher bringt eine niedrigere Aufrufrate keine aktuelleren Daten.*

### Aufruf (Anzeigen der gesammelten Daten)

Um sich die Statistik anzeigen zu lassen ruft man einfach die `freifunk.php`-Datei auf (diese kann auch beliebig umbenannt werden, z.b. `index.php`).

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

### Routerabfrage beenden/aussetzen

Möchte man einen Router nicht mehr abfragen, so kann man eine Datei namens `disabled` in das Verzeichnis legen. Somit bleiben die historischen Daten bestehen und die Daten des Router werden nicht mehr aktualisiert.

# Autoren

[Guenther Schmitz](https://github.com/gpunktschmitz) - http://www.gpunktschmitz.de

# Lizenz
## alle PHP- und Bash-Skripte:
CC0 1.0 Universal <http://creativecommons.org/publicdomain/zero/1.0/>

## Chart.js (js/Chart.min.js):<br />
MIT <https://github.com/nnnick/Chart.js/blob/master/LICENSE.md>
