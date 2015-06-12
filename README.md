# freifunkcrawler
Bash-Skript zum Sammeln der Anzahl der verbundenen Clients eines oder mehrerer Freifunk Router. PHP-Skript zum Anzeigen der gesammelten Daten als Diagramm.

## Verwendung

### Einrichtung

Alle Dateien z.B. in ein Unterverzeichnis `stats` eines htdocs ablegen.

Konfigurationsdatei `freifunkconfig.ini.example.php` nach `freifunkconfig.ini.php` kopieren und persönliche Einstellungen vornehmen.

Das Skript zur Initialisierung mit dem Parameter `init` aufrufen:
`bash freifunkcrawler.sh init`  

Anschliessend kann man das Skript `freifunkcrawler.sh` (ohne Parameter!) regelmäßig (z.B. alle halbe Stunde) via Cron-Job ausführen.

Die Daten auf dem (Franken-)Netmon werden nur alle 10 Minuten aktualisiert, daher bringt eine niedrigere Aufrufrate keine aktuelleren Daten.

# Autoren
[Guenther Schmitz](https://github.com/gpunktschmitz) - http://www.gpunktschmitz.de

# Lizenz
## alle PHP- und Bash-Skripte:
CC0 1.0 Universal <http://creativecommons.org/publicdomain/zero/1.0/>

## Chart.js (js/Chart.min.js):<br />
MIT <https://github.com/nnnick/Chart.js/blob/master/LICENSE.md>
