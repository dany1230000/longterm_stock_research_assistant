enum EtfDataStatus {
  official,
  proxy,
  cached,
  mock,
  error,
  stale,
}

extension EtfDataStatusLabel on EtfDataStatus {
  String get label {
    switch (this) {
      case EtfDataStatus.official:
        return 'official';
      case EtfDataStatus.proxy:
        return 'proxy';
      case EtfDataStatus.cached:
        return 'cached';
      case EtfDataStatus.mock:
        return 'mock';
      case EtfDataStatus.error:
        return 'error';
      case EtfDataStatus.stale:
        return 'stale';
    }
  }
}

class LeveragedEtfProfile {
  const LeveragedEtfProfile({
    required this.symbol,
    required this.fundName,
    required this.shortName,
    required this.trackingIndex,
    required this.inceptionDate,
    required this.listingDate,
    required this.distributesIncome,
    required this.riskLevel,
    required this.managementFeePercent,
    required this.custodianFeePercent,
    required this.leverageObjective,
    required this.exposurePolicy,
    required this.primaryTradingMethod,
    required this.sourceUrl,
    required this.status,
    required this.lastFetchedAt,
  });

  final String symbol;
  final String fundName;
  final String shortName;
  final String trackingIndex;
  final DateTime inceptionDate;
  final DateTime listingDate;
  final bool distributesIncome;
  final String riskLevel;
  final double managementFeePercent;
  final double custodianFeePercent;
  final String leverageObjective;
  final String exposurePolicy;
  final String primaryTradingMethod;
  final String sourceUrl;
  final EtfDataStatus status;
  final DateTime lastFetchedAt;
}

class EtfAssetSummary {
  const EtfAssetSummary({
    required this.stock,
    required this.etf,
    required this.bond,
    required this.futures,
  });

  final double stock;
  final double etf;
  final double bond;
  final double futures;

  double valueFor(EtfAssetClass assetClass) {
    switch (assetClass) {
      case EtfAssetClass.stock:
        return stock;
      case EtfAssetClass.etf:
        return etf;
      case EtfAssetClass.bond:
        return bond;
      case EtfAssetClass.futures:
        return futures;
    }
  }
}

enum EtfAssetClass {
  stock,
  etf,
  bond,
  futures,
}

class EtfCashHoldingLine {
  const EtfCashHoldingLine({
    required this.item,
    required this.amount,
  });

  final String item;
  final double amount;

  double weightPct(double fundNetAssetValue) {
    if (fundNetAssetValue == 0) {
      return 0;
    }
    return amount / fundNetAssetValue * 100;
  }
}

class EtfStockHoldingLine {
  const EtfStockHoldingLine({
    required this.code,
    required this.name,
    required this.quantity,
    required this.weightPct,
  });

  final String code;
  final String name;
  final int quantity;
  final double weightPct;
}

class EtfFuturesHoldingLine {
  const EtfFuturesHoldingLine({
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
  final String contractMonth;
}

class EtfDailyHoldingSnapshot {
  const EtfDailyHoldingSnapshot({
    required this.tradeDate,
    required this.fundNetAssetValue,
    required this.navPerUnit,
    required this.outstandingUnits,
    required this.assetSummary,
    required this.cashHoldings,
    required this.stockHoldings,
    required this.futuresHoldings,
    required this.status,
    required this.lastFetchedAt,
    required this.sourceUpdatedAt,
    required this.sourceHash,
    this.errorMessage,
  });

  final DateTime tradeDate;
  final double fundNetAssetValue;
  final double navPerUnit;
  final int outstandingUnits;
  final EtfAssetSummary assetSummary;
  final List<EtfCashHoldingLine> cashHoldings;
  final List<EtfStockHoldingLine> stockHoldings;
  final List<EtfFuturesHoldingLine> futuresHoldings;
  final EtfDataStatus status;
  final DateTime lastFetchedAt;
  final DateTime sourceUpdatedAt;
  final String sourceHash;
  final String? errorMessage;

  double assetWeightPct(EtfAssetClass assetClass) {
    if (fundNetAssetValue == 0) {
      return 0;
    }
    return assetSummary.valueFor(assetClass) / fundNetAssetValue * 100;
  }

  double get cashAndMarginValue {
    return cashHoldings
        .where((line) =>
            line.item.contains('保證金') ||
            line.item.contains('現金') ||
            line.item.contains('附買回債券'))
        .fold<double>(0, (sum, line) => sum + line.amount);
  }

  double get otherReceivablesPayablesValue {
    return cashHoldings
        .where((line) =>
            !line.item.contains('保證金') &&
            !line.item.contains('現金') &&
            !line.item.contains('附買回債券'))
        .fold<double>(0, (sum, line) => sum + line.amount);
  }

  double get cashAndMarginWeightPct {
    if (fundNetAssetValue == 0) {
      return 0;
    }
    return cashAndMarginValue / fundNetAssetValue * 100;
  }

  double get otherReceivablesPayablesWeightPct {
    if (fundNetAssetValue == 0) {
      return 0;
    }
    return otherReceivablesPayablesValue / fundNetAssetValue * 100;
  }

  double get stockExposureWeightPct {
    return stockHoldings.fold<double>(
      0,
      (sum, holding) => sum + holding.weightPct,
    );
  }

  double get futuresExposureWeightPct {
    return futuresHoldings.fold<double>(
      0,
      (sum, holding) => sum + holding.weightPct,
    );
  }

  double get totalDeclaredExposureWeightPct {
    return stockExposureWeightPct + futuresExposureWeightPct;
  }

  bool isStale(DateTime now) {
    return _businessDaysBetween(tradeDate, now) > 1;
  }
}

class EtfIntradayNav {
  const EtfIntradayNav({
    required this.symbol,
    required this.name,
    required this.outstandingUnits,
    required this.outstandingUnitsDelta,
    required this.marketPrice,
    required this.estimatedNav,
    required this.estimatedPremiumDiscountPct,
    required this.previousBusinessDayNav,
    required this.previousBusinessDayNavText,
    required this.dataDate,
    required this.dataTime,
    required this.targetType,
    required this.userDelayMs,
    required this.sourceContract,
    required this.status,
    required this.lastFetchedAt,
  });

  final String symbol;
  final String name;
  final int? outstandingUnits;
  final int? outstandingUnitsDelta;
  final double? marketPrice;
  final double? estimatedNav;
  final double? estimatedPremiumDiscountPct;
  final double? previousBusinessDayNav;
  final String previousBusinessDayNavText;
  final DateTime? dataDate;
  final DateTime? dataTime;
  final String targetType;
  final int userDelayMs;
  final String? sourceContract;
  final EtfDataStatus status;
  final DateTime lastFetchedAt;
}

class FuturesQuote {
  const FuturesQuote({
    required this.symbol,
    required this.contractMonth,
    required this.txPrice,
    required this.weightedIndex,
    required this.nightSessionChange,
    required this.status,
    required this.lastFetchedAt,
    this.errorMessage,
  });

  final String symbol;
  final String contractMonth;
  final double? txPrice;
  final double? weightedIndex;
  final double? nightSessionChange;
  final EtfDataStatus status;
  final DateTime lastFetchedAt;
  final String? errorMessage;

  double? get txContractValue {
    final price = txPrice;
    if (price == null) {
      return null;
    }
    return price * 200;
  }

  double? get futuresBasisPoints {
    final price = txPrice;
    final index = weightedIndex;
    if (price == null || index == null) {
      return null;
    }
    return price - index;
  }

  double? get futuresBasisPct {
    final basis = futuresBasisPoints;
    final index = weightedIndex;
    if (basis == null || index == null || index == 0) {
      return null;
    }
    return basis / index * 100;
  }
}

class EtfAnalysisSummary {
  const EtfAnalysisSummary({
    required this.lines,
    required this.premiumDiscountLabel,
    required this.isStale,
  });

  final List<String> lines;
  final String premiumDiscountLabel;
  final bool isStale;

  factory EtfAnalysisSummary.fromSnapshot({
    required EtfDailyHoldingSnapshot snapshot,
    required EtfIntradayNav? intradayNav,
    required DateTime now,
  }) {
    final topStock =
        snapshot.stockHoldings.isEmpty ? null : snapshot.stockHoldings.first;
    final topFuture = snapshot.futuresHoldings.isEmpty
        ? null
        : snapshot.futuresHoldings.first;
    final premium = intradayNav?.estimatedPremiumDiscountPct;
    final stale = snapshot.isStale(now);
    final premiumLabel = _premiumDiscountLabel(premium);
    final lines = <String>[
      if (topFuture != null && topStock != null)
        '目前 00631L 主要曝險來自 ${topFuture.code} ${topFuture.name} 與 ${topStock.name} 現貨。',
      '期貨權重為 ${snapshot.futuresExposureWeightPct.toStringAsFixed(2)}%，股票權重為 ${snapshot.stockExposureWeightPct.toStringAsFixed(2)}%，合計曝險約 ${snapshot.totalDeclaredExposureWeightPct.toStringAsFixed(2)}%。',
      '官方內容物為每日揭露資料；盤中變化以預估淨值與折溢價觀察。',
      if (premium == null)
        '即時折溢價資料暫不可用，不進行盤中折溢價判讀。'
      else
        '目前預估折溢價為 ${premium.toStringAsFixed(2)}%，狀態標示為$premiumLabel，不構成買賣建議。',
      if (stale)
        '官方內容物已超過 1 個交易日未更新，資料狀態標示為 stale。'
      else
        '官方內容物日期仍在 1 個交易日檢查範圍內。',
    ];

    return EtfAnalysisSummary(
      lines: lines,
      premiumDiscountLabel: premiumLabel,
      isStale: stale,
    );
  }
}

class Etf00631LLabData {
  const Etf00631LLabData({
    required this.profile,
    required this.snapshot,
    required this.intradayNav,
    required this.futuresQuote,
    required this.analysis,
    required this.lastFetchedAt,
  });

  final LeveragedEtfProfile profile;
  final EtfDailyHoldingSnapshot snapshot;
  final EtfIntradayNav? intradayNav;
  final FuturesQuote futuresQuote;
  final EtfAnalysisSummary analysis;
  final DateTime lastFetchedAt;

  EtfDataStatus get status {
    if (snapshot.status == EtfDataStatus.error ||
        futuresQuote.status == EtfDataStatus.error) {
      return EtfDataStatus.error;
    }
    if (analysis.isStale) {
      return EtfDataStatus.stale;
    }
    if (profile.status == EtfDataStatus.proxy ||
        snapshot.status == EtfDataStatus.proxy ||
        intradayNav?.status == EtfDataStatus.proxy ||
        futuresQuote.status == EtfDataStatus.proxy) {
      return EtfDataStatus.proxy;
    }
    if (snapshot.status == EtfDataStatus.mock ||
        intradayNav?.status == EtfDataStatus.mock ||
        futuresQuote.status == EtfDataStatus.mock) {
      return EtfDataStatus.mock;
    }
    if (snapshot.status == EtfDataStatus.cached ||
        intradayNav?.status == EtfDataStatus.cached ||
        futuresQuote.status == EtfDataStatus.cached) {
      return EtfDataStatus.cached;
    }
    return EtfDataStatus.official;
  }
}

String _premiumDiscountLabel(double? premium) {
  if (premium == null) {
    return '即時資料暫不可用';
  }
  if (premium > 0.5) {
    return '偏高';
  }
  if (premium < -0.5) {
    return '偏低';
  }
  return '接近淨值';
}

int _businessDaysBetween(DateTime start, DateTime end) {
  var days = 0;
  var cursor = DateTime(start.year, start.month, start.day);
  final target = DateTime(end.year, end.month, end.day);

  while (cursor.isBefore(target)) {
    cursor = cursor.add(const Duration(days: 1));
    if (cursor.weekday != DateTime.saturday &&
        cursor.weekday != DateTime.sunday) {
      days += 1;
    }
  }

  return days;
}
