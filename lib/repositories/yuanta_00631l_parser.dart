import 'dart:convert';

import '../models/leveraged_etf_lab.dart';

class Yuanta00631LParser {
  static const basicInformationUrl =
      'https://www.yuantaetfs.com/product/detail/00631L/Basic_information';
  static const ratioUrl =
      'https://www.yuantaetfs.com/product/detail/00631L/ratio';
  static const twseIntradayNavFormatUrl =
      'https://dsp.twse.com.tw/public/static/downloads/tradingDepartment/'
      'ETF%20%E7%94%B3%E8%B4%96%E8%B3%87%E8%A8%8A%E5%8F%8A%E5%8D%B3%E6%99%82%E6%B7%A8%E5%80%BC%E6%8F%AD%E9%9C%B2%E5%B0%88%E5%8D%80%E4%BB%8B%E6%8E%A5%E6%A0%BC%E5%BC%8F%E8%AA%AA%E6%98%8E_20250109142554.pdf';

  static LeveragedEtfProfile parseProfile(
    String source, {
    required DateTime lastFetchedAt,
    EtfDataStatus status = EtfDataStatus.official,
  }) {
    final text = _normalize(source);
    final fundName = _textBetween(text, '#', '00631L') ??
        '元大ETF傘型證券投資信託基金之台灣50單日正向2倍證券投資信託基金';
    final shortName = _textAfter(text, 'Fund Simple Name：') ??
        _textAfter(text, 'Fund Simple Name:') ??
        '元大台灣50單日正向2倍基金';

    return LeveragedEtfProfile(
      symbol: '00631L',
      fundName: fundName.trim(),
      shortName: shortName.trim().isEmpty ? '元大台灣50單日正向2倍基金' : shortName.trim(),
      trackingIndex: _textAfter(text, 'Benchmark Index') ?? '臺灣50指數',
      inceptionDate: _parseDate(_textAfter(text, 'Inception Date')) ??
          DateTime(2014, 10, 23),
      listingDate: _parseDate(_textAfter(text, 'Listing Date')) ??
          DateTime(2014, 10, 31),
      distributesIncome:
          (_textAfter(text, 'Dividends') ?? 'NO').toUpperCase().contains('YES'),
      riskLevel: _textAfter(text, 'Risk Level') ?? 'RR5',
      managementFeePercent:
          _parsePercent(_textAfter(text, 'Management Fee')) ?? 1,
      custodianFeePercent:
          _parsePercent(_textAfter(text, 'Custodian Fee')) ?? 0.04,
      leverageObjective: '追蹤臺灣50指數單日正向 2 倍報酬',
      exposurePolicy: '整體曝險部位約為基金淨資產價值 180% 至 220%',
      primaryTradingMethod: '主要投資上市股票與證券相關商品，並以做多期貨為主要交易',
      sourceUrl: basicInformationUrl,
      status: status,
      lastFetchedAt: lastFetchedAt,
    );
  }

  static EtfDailyHoldingSnapshot parseDailyHoldingSnapshot(
    String source, {
    required DateTime lastFetchedAt,
    EtfDataStatus status = EtfDataStatus.official,
  }) {
    final text = _normalize(source);
    final fundAssetSection = _section(text, 'Fund Asset', 'Asset Holdings');
    final cashSection = _section(text, 'Cash', '基金權重-股票');
    final stockSection = _section(text, '基金權重-股票', '基金權重-期貨');
    final futuresSection = _section(text, '基金權重-期貨', 'Yuanta Group');

    final tradeDate = _parseDate(_textAfter(text, 'Trade Date:'));
    final fundNetAssetValue = _moneyAfter(text, 'Fund Net Asset Value (NTD)');
    final navPerUnit = _moneyAfter(text, 'Net Asset Value Per Unit (NTD)');
    final outstandingUnits = _integerAfter(text, 'Outstanding Units (shares)');
    final hasRequired = tradeDate != null &&
        fundNetAssetValue != null &&
        navPerUnit != null &&
        outstandingUnits != null;

    return EtfDailyHoldingSnapshot(
      tradeDate: tradeDate ?? DateTime(1970),
      fundNetAssetValue: fundNetAssetValue ?? 0,
      navPerUnit: navPerUnit ?? 0,
      outstandingUnits: outstandingUnits ?? 0,
      assetSummary: EtfAssetSummary(
        stock: _moneyAfter(fundAssetSection, 'Stock') ?? 0,
        etf: _moneyAfter(fundAssetSection, 'ETF') ?? 0,
        bond: _moneyAfter(fundAssetSection, 'Bond') ?? 0,
        futures: _moneyAfter(fundAssetSection, 'Futures') ?? 0,
      ),
      cashHoldings: _parseCashLines(cashSection),
      stockHoldings: _parseStockLines(stockSection),
      futuresHoldings: _parseFuturesLines(futuresSection),
      status: hasRequired ? status : EtfDataStatus.error,
      lastFetchedAt: lastFetchedAt,
      sourceUpdatedAt: tradeDate ?? lastFetchedAt,
      sourceHash: _sourceHash(source),
      errorMessage: hasRequired ? null : '官方每日內容物欄位不完整',
    );
  }

  static EtfIntradayNav? parseTwseIntradayNavJson(
    String source, {
    required DateTime lastFetchedAt,
    EtfDataStatus status = EtfDataStatus.official,
  }) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final msgArray = decoded['msgArray'];
    if (msgArray is! List) {
      return null;
    }

    Map<String, dynamic>? item;
    for (final candidate in msgArray) {
      if (candidate is Map<String, dynamic> && candidate['a'] == '00631L') {
        item = candidate;
        break;
      }
    }

    if (item == null) {
      return null;
    }

    final dataDate = _parseCompactDate(_stringValue(item['i']));
    final dataTime = _parseDataTime(dataDate, _stringValue(item['j']));
    final previousNavText = _stringValue(item['h']) ?? '';
    final marketPrice = _parseDouble(_stringValue(item['e']));
    final estimatedNav = _parseDouble(_stringValue(item['f']));
    final premiumDiscountPct = resolvePremiumDiscountPct(
      premiumDiscountPct: _parseDouble(_stringValue(item['g'])),
      marketPrice: marketPrice,
      estimatedNav: estimatedNav,
    );

    return EtfIntradayNav(
      symbol: _stringValue(item['a']) ?? '',
      name: _stringValue(item['b']) ?? '',
      outstandingUnits: _parseInt(_stringValue(item['c'])),
      outstandingUnitsDelta: _parseInt(_stringValue(item['d'])),
      marketPrice: marketPrice,
      estimatedNav: estimatedNav,
      estimatedPremiumDiscountPct: premiumDiscountPct,
      previousBusinessDayNav: _parseDouble(previousNavText),
      previousBusinessDayNavText: previousNavText,
      dataDate: dataDate,
      dataTime: dataTime,
      targetType: _stringValue(item['k']) ?? '',
      userDelayMs: _parseInt(_stringValue(decoded['userDelay'])) ?? 15000,
      sourceContract: 'twse_a_k_json',
      isStale: false,
      status: status,
      lastFetchedAt: lastFetchedAt,
    );
  }

  static List<EtfCashHoldingLine> _parseCashLines(String section) {
    const items = [
      '保證金',
      '現金',
      '附買回債券',
      '應收利息',
      '應付申購預收款',
    ];

    return [
      for (final item in items)
        if (_moneyAfter(section, item) != null)
          EtfCashHoldingLine(
            item: item,
            amount: _moneyAfter(section, item)!,
          ),
    ];
  }

  static List<EtfStockHoldingLine> _parseStockLines(String section) {
    final rows = _parseLabeledRows(section, includeContractMonth: false);
    return rows
        .map(
          (row) => EtfStockHoldingLine(
            code: row.code,
            name: row.name,
            quantity: row.quantity,
            weightPct: row.weightPct,
          ),
        )
        .toList();
  }

  static List<EtfFuturesHoldingLine> _parseFuturesLines(String section) {
    final rows = _parseLabeledRows(section, includeContractMonth: true);
    return rows
        .map(
          (row) => EtfFuturesHoldingLine(
            code: row.code,
            name: row.name,
            quantity: row.quantity,
            weightPct: row.weightPct,
            contractMonth: row.contractMonth ?? '',
          ),
        )
        .toList();
  }

  static List<_LabeledHoldingRow> _parseLabeledRows(
    String section, {
    required bool includeContractMonth,
  }) {
    final lines = _nonEmptyLines(section);
    final rows = <_LabeledHoldingRow>[];

    for (var i = 0; i < lines.length; i += 1) {
      final code = _readValue(lines, i, '商品代碼');
      if (code == null || _isTableLabel(code)) {
        continue;
      }

      final name = _findNextValue(lines, i + 1, '商品名稱');
      final quantity = _parseInt(_findNextValue(lines, i + 1, '商品數量'));
      final weight = _parseDouble(_findNextValue(lines, i + 1, '商品權重'));
      final contractMonth =
          includeContractMonth ? _findNextValue(lines, i + 1, '商品年月') : null;

      if (name == null || quantity == null || weight == null) {
        continue;
      }

      rows.add(
        _LabeledHoldingRow(
          code: code,
          name: name,
          quantity: quantity,
          weightPct: weight,
          contractMonth: contractMonth,
        ),
      );
    }

    return rows;
  }

  static String _normalize(String source) {
    return source
        .replaceAll(RegExp(r'<[^>]+>'), '\n')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{2,}'), '\n');
  }

  static String _section(String text, String start, String end) {
    final startIndex = text.indexOf(start);
    if (startIndex < 0) {
      return text;
    }
    final endIndex = text.indexOf(end, startIndex + start.length);
    if (endIndex < 0) {
      return text.substring(startIndex);
    }
    return text.substring(startIndex, endIndex);
  }

  static List<String> _nonEmptyLines(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static String? _textAfter(String text, String label) {
    final lines = _nonEmptyLines(text);
    for (var i = 0; i < lines.length; i += 1) {
      final value = _readValue(lines, i, label);
      if (value != null && !_isTableLabel(value)) {
        return value;
      }
    }
    return null;
  }

  static String? _textBetween(String text, String start, String end) {
    final startIndex = text.indexOf(start);
    if (startIndex < 0) {
      return null;
    }
    final endIndex = text.indexOf(end, startIndex + start.length);
    if (endIndex < 0) {
      return null;
    }
    return text.substring(startIndex + start.length, endIndex).trim();
  }

  static double? _moneyAfter(String text, String label) {
    final labelIndex = text.indexOf(label);
    if (labelIndex < 0) {
      return null;
    }
    final end = labelIndex + 220 < text.length ? labelIndex + 220 : text.length;
    final window = text.substring(
      labelIndex,
      end,
    );
    final match = RegExp(r'NTD\s*\$?\s*(-?[\d,]+(?:\.\d+)?)').firstMatch(
      window,
    );
    return _parseDouble(match?.group(1));
  }

  static int? _integerAfter(String text, String label) {
    final labelIndex = text.indexOf(label);
    if (labelIndex < 0) {
      return null;
    }
    final end = labelIndex + 160 < text.length ? labelIndex + 160 : text.length;
    final window = text.substring(
      labelIndex,
      end,
    );
    final match = RegExp(r'(-?[\d,]+)').firstMatch(window.replaceFirst(
      label,
      '',
    ));
    return _parseInt(match?.group(1));
  }

  static String? _findNextValue(
    List<String> lines,
    int start,
    String label, {
    int maxDistance = 10,
  }) {
    final end =
        start + maxDistance < lines.length ? start + maxDistance : lines.length;
    for (var i = start; i < end; i += 1) {
      final value = _readValue(lines, i, label);
      if (value != null && !_isTableLabel(value)) {
        return value;
      }
    }
    return null;
  }

  static String? _readValue(List<String> lines, int index, String label) {
    final line = lines[index];
    if (line == label || line == '$label:') {
      if (index + 1 >= lines.length || _isTableLabel(lines[index + 1])) {
        return null;
      }
      return lines[index + 1].trim();
    }
    if (line.startsWith('$label ')) {
      return line.substring(label.length).trim();
    }
    if (line.startsWith('$label:')) {
      return line.substring(label.length + 1).trim();
    }
    return null;
  }

  static bool _isTableLabel(String value) {
    const labels = {
      '商品代碼',
      '商品名稱',
      '商品數量',
      '商品權重',
      '商品年月',
      'Trade Date:',
      'Holdings',
      'Cash',
    };
    return labels.contains(value.trim());
  }

  static DateTime? _parseDate(String? value) {
    if (value == null) {
      return null;
    }
    final match = RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})').firstMatch(
      value,
    );
    if (match == null) {
      return null;
    }
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static DateTime? _parseCompactDate(String? value) {
    if (value == null || value.length != 8) {
      return null;
    }
    return DateTime(
      int.parse(value.substring(0, 4)),
      int.parse(value.substring(4, 6)),
      int.parse(value.substring(6, 8)),
    );
  }

  static DateTime? _parseDataTime(DateTime? date, String? value) {
    if (date == null || value == null) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length != 3) {
      return null;
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static double? _parsePercent(String? value) {
    return _parseDouble(value?.replaceAll('%', ''));
  }

  static double? _parseDouble(String? value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.replaceAll(',', '').trim());
  }

  static int? _parseInt(String? value) {
    if (value == null) {
      return null;
    }
    return int.tryParse(value.replaceAll(',', '').trim());
  }

  static String? _stringValue(Object? value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  static String _sourceHash(String source) {
    return source.hashCode.toUnsigned(32).toRadixString(16);
  }
}

class _LabeledHoldingRow {
  const _LabeledHoldingRow({
    required this.code,
    required this.name,
    required this.quantity,
    required this.weightPct,
    required this.contractMonth,
  });

  final String code;
  final String name;
  final int quantity;
  final double weightPct;
  final String? contractMonth;
}
