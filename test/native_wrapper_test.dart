import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:csv_parser/native.dart';


void main() {

  test("empty csv", () {
    var content = new Uint8List.fromList("".codeUnits);

    Result result = csvToJson(content);
    expect(result.error, null);

    expect(jsonEncode(result.data), """{"header":[],"rows":[]}""");
  });

  test("non UTF CSV", () {
    final file =
        File("test/data/Zermatt_Bergbahnen_AG_-_Agenda_Items_2019_Upload.csv");
    var content = file.readAsBytesSync();

    Result result = csvToJson(content);
    expect(result.error, null);
    expect(jsonEncode(result.data),
        """{"header":["TITLE","DESCRIPTION","AGENDAITEMTYPE","MAJORITY","NOTARYREQUIRED"],"rows":[["Begruessung, Bestimmung des Protokollfuehrers und der Stimmenzaehler","","information","Simple Majority (more than 1/2)","FALSE"],["Geschaeftsbericht mit Jahresbericht und Jahresrechnung 1. Juni 2018 bis 31. Mai 2019, Konzernrechnung, Kenntnisnahme der Berichte der Revisionsstelle und des Konzernpruefers der BDO AG","Der Verwaltungsrat beantragt, den Geschaeftsbericht mit Jahresbericht, Jahresrechnung und Konzernrechnung zu genehmigen sowie die Berichte der Revisionsstelle zur Kenntnis zu nehmen.","decision","Simple Majority (more than 1/2)","FALSE"],["Verwendung des Bilanzgewinnes und Dividendenausschuettung","Jahresgewinn 2018/2019: CHF 1'949'848, Gewinnvortrag CHF  21'269'063, Bilanzgewinn zur Verfuegung der Generalversammlung CHF 23'218'911. Der Verwaltungsrat beantragt, den Bilanzgewinn von CHF 23'218'911 wie folgt zu verwenden: Ausrichtung einer Dividende von 8%, CHF 4.00 pro Aktie CHF 2'516'800 Vortrag auf neue Rechnung CHF 20'702'111.","decision","Simple Majority (more than 1/2)","FALSE"],["Entlastung der Mitglieder des Verwaltungsrates","Der Verwaltungsrat beantragt, seinen Mitgliedern Entlastung zu erteilen.","decision","Simple Majority (more than 1/2)","FALSE"],["Wahlen","Der Verwaltungsrat beantragt die Wiederwahl der bisherigen Verwaltungsraete Franz Julen, Gerold Biner, Andreas Perren, Roland Zegg, Patrick ZÕBrun, Jean-Michel Cina und Hermann Biner.","decision","Simple Majority (more than 1/2)","FALSE"],["Wahlen","Der Verwaltungsrat beantragt die Wiederwahl von Franz Julen fuer das Amt des Verwaltungsratspraesidenten.","decision","Simple Majority (more than 1/2)","FALSE"],["Wahl der Revisionsstelle","Der Verwaltungsrat beantragt, die BDO AG, Bern fuer ein weiteres Jahr als Revisionsstelle zu waehlen.","decision","Simple Majority (more than 1/2)","FALSE"],["Verschiedenes","","information","Simple Majority (more than 1/2)","FALSE"]]}""");
  });

  test("path replacement works", () {
    var libPath = '/opt/projects/work_aequitec/app/libs/csv_parser/test';

    expect(libPath.contains('/libs/csv_parser'), true);
    var replacedLibPath = libPath.replaceFirst(
        new RegExp(r'\/libs\/csv_parser.+'), '/libs/csv_parser/assets/binary/');

    expect(replacedLibPath,
        '/opt/projects/work_aequitec/app/libs/csv_parser/assets/binary/');

    libPath = '/opt/projects/work_aequitec/app/libs/csv_parser';

    expect(libPath.contains('/libs/csv_parser'), true);
    replacedLibPath = libPath.replaceFirst(
        new RegExp(r'\/libs\/csv_parse.+'), '/libs/csv_parser/assets/binary/');

    expect(replacedLibPath,
        '/opt/projects/work_aequitec/app/libs/csv_parser/assets/binary/');

    var appPath = '/opt/projects/work_aequitec/app/flutter_app/test';

    expect(appPath.contains('flutter_app'), true);

    var replacedAppPath = appPath.replaceFirst(
        new RegExp(r'flutter_ap.+'), 'libs/csv_parser/assets/binary/');

    expect(replacedAppPath,
        '/opt/projects/work_aequitec/app/libs/csv_parser/assets/binary/');
  });
}
