import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:csv_parser/csv_parser.dart';

List testFiles() {
  return [
    ['BeKB_agenda.csv', 5, 15],
    ["CapShare Random Test Data.csv", 21, 117],
    ['fixedInApp_BeKB.csv', 5, 15],
    ["share_register_template.csv", 38, 4],
    ["temp.csv", 16, 4],
    ["UploadLegalEntity.csv", 13, 3],
    ["UploadNaturalPerson.csv", 20, 7],
    ["UploadRegister.csv", 21, 10],
    ["Zermatt_Bergbahnen_AG_-_Agenda_Items_2019_Upload.csv", 5, 8],
  ];
}
void main() {
  test("Transcode test files as expected", () {
    var files = testFiles();
    files.forEach((td) {
      String path = td[0];
      int colCount = td[1];
      int rowsCount = td[2];
      final file = File("test/data/" + path);
      var content = file.readAsBytesSync();

      prints(content.lengthInBytes);

      var csvData = CSVData.fromRawCSV(content);
      expect(csvData.error, null);
      expect(csvData.header.length, colCount, reason: path);
      expect(csvData.rows.length, rowsCount, reason: path);
    });
  });

  test("Test CSVData - creates valid CSV file", () {
    List<AgendaItem> testData = [
      AgendaItem("title 1", "test description 1", "agenda type", "2/3", false),
      AgendaItem("title 2", "test description 2", "agenda type", "1/3", true),
      AgendaItem("title 3", "test description 3", "agenda type", "2/3", false),
      AgendaItem("title 4", "test description 4", "agenda type", "2/4", true),
      AgendaItem("title 5", "test description 5", "agenda type", "5/5", false)
    ];

    var csvData = CSVData.fromHeaderAndRows(AgendaItemCSVHandler.toCSVHeader(),
        testData.map((e) => e.toCSVRow()).toList());
    var rawCSV = csvData.toRawCSV();
    expect(rawCSV.data, """TITLE,DESCRIPTION,AGENDAITEMTYPE,MAJORITY,NOTARYREQUIRED
title 1,test description 1,agenda type,2/3,FALSE
title 2,test description 2,agenda type,1/3,TRUE
title 3,test description 3,agenda type,2/3,FALSE
title 4,test description 4,agenda type,2/4,TRUE
title 5,test description 5,agenda type,5/5,FALSE
""");

  });

  test("Test CSVData - can be constructed from CSV file content", () {
    final file =
        File("./test/data/Zermatt_Bergbahnen_AG_-_Agenda_Items_2019_Upload.csv");
    var content = file.readAsBytesSync();

    var csvData = CSVData.fromRawCSV(content);
    expect(csvData.error, null);
    expect(csvData.header.length, 5);

    List<AgendaItem> result =
        csvData.rows.map((e) => AgendaItemCSVHandler.fromCSV(e)).toList();
    expect(result.length, csvData.rows.length);

    var newCSVData = CSVData.fromRows(result.cast());

    expect(newCSVData.header.length, csvData.header.length);
    expect(csvData.rows.length, csvData.rows.length);
    var json = newCSVData.toJson();
    expect(json,
        """{"header":["TITLE","DESCRIPTION","AGENDAITEMTYPE","MAJORITY","NOTARYREQUIRED"],"rows":[["Begruessung, Bestimmung des Protokollfuehrers und der Stimmenzaehler","","information","Simple Majority (more than 1/2)","FALSE"],["Geschaeftsbericht mit Jahresbericht und Jahresrechnung 1. Juni 2018 bis 31. Mai 2019, Konzernrechnung, Kenntnisnahme der Berichte der Revisionsstelle und des Konzernpruefers der BDO AG","Der Verwaltungsrat beantragt, den Geschaeftsbericht mit Jahresbericht, Jahresrechnung und Konzernrechnung zu genehmigen sowie die Berichte der Revisionsstelle zur Kenntnis zu nehmen.","decision","Simple Majority (more than 1/2)","FALSE"],["Verwendung des Bilanzgewinnes und Dividendenausschuettung","Jahresgewinn 2018/2019: CHF 1\'949\'848, Gewinnvortrag CHF  21\'269\'063, Bilanzgewinn zur Verfuegung der Generalversammlung CHF 23\'218\'911. Der Verwaltungsrat beantragt, den Bilanzgewinn von CHF 23\'218\'911 wie folgt zu verwenden: Ausrichtung einer Dividende von 8%, CHF 4.00 pro Aktie CHF 2\'516\'800 Vortrag auf neue Rechnung CHF 20\'702\'111.","decision","Simple Majority (more than 1/2)","FALSE"],["Entlastung der Mitglieder des Verwaltungsrates","Der Verwaltungsrat beantragt, seinen Mitgliedern Entlastung zu erteilen.","decision","Simple Majority (more than 1/2)","FALSE"],["Wahlen","Der Verwaltungsrat beantragt die Wiederwahl der bisherigen Verwaltungsraete Franz Julen, Gerold Biner, Andreas Perren, Roland Zegg, Patrick ZÕBrun, Jean-Michel Cina und Hermann Biner.","decision","Simple Majority (more than 1/2)","FALSE"],["Wahlen","Der Verwaltungsrat beantragt die Wiederwahl von Franz Julen fuer das Amt des Verwaltungsratspraesidenten.","decision","Simple Majority (more than 1/2)","FALSE"],["Wahl der Revisionsstelle","Der Verwaltungsrat beantragt, die BDO AG, Bern fuer ein weiteres Jahr als Revisionsstelle zu waehlen.","decision","Simple Majority (more than 1/2)","FALSE"],["Verschiedenes","","information","Simple Majority (more than 1/2)","FALSE"]]}""");
  });
}

class AgendaItem implements CSVRow {
  String title;
  String description;
  String agendaItemType;
  String majority;
  bool notaryRequired;

  AgendaItem(String title, String description, String agendaItemType,
      String majority, bool notaryRequired) {
    this.title = title;
    this.description = description;
    this.agendaItemType = agendaItemType;
    this.majority = majority;
    this.notaryRequired = notaryRequired;
  }

  @override
  List<String> toCSVRow() {
    return this.toCSV();
  }

  @override
  List<String> toCSVHeader() {
    return AgendaItemCSVHandler.toCSVHeader();
  }
}

extension AgendaItemCSVHandler on AgendaItem {
  static AgendaItem fromCSV(List<Object> csv) => AgendaItem(
      csv[0] as String,
      csv[1] as String,
      csv[2] as String,
      csv[3] as String,
      (csv[4] as String).toLowerCase() == 'true');

  static List<String> toCSVHeader() => <String>[
        "TITLE",
        "DESCRIPTION",
        "AGENDAITEMTYPE",
        "MAJORITY",
        "NOTARYREQUIRED",
      ];

  List<String> toCSV() => <String>[
        title ?? '',
        description ?? '',
        agendaItemType ?? '',
        majority ?? '',
        notaryRequired.toString().toUpperCase() ?? '',
      ];
}
