import 'dart:math' as math;

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

enum PremiumDiscountLevel {
  unavailable,
  normal,
  watch,
  elevated,
  extreme,
  stale,
}

class PremiumDiscountAssessment {
  const PremiumDiscountAssessment({
    required this.level,
    required this.premiumDiscountPct,
  });

  factory PremiumDiscountAssessment.evaluate({
    required double? premiumDiscountPct,
    required EtfDataStatus sourceStatus,
    required bool isStale,
  }) {
    if (premiumDiscountPct == null ||
        sourceStatus == EtfDataStatus.error ||
        sourceStatus == EtfDataStatus.mock) {
      return PremiumDiscountAssessment(
        level: PremiumDiscountLevel.unavailable,
        premiumDiscountPct: premiumDiscountPct,
      );
    }

    if (isStale || sourceStatus == EtfDataStatus.stale) {
      return PremiumDiscountAssessment(
        level: PremiumDiscountLevel.stale,
        premiumDiscountPct: premiumDiscountPct,
      );
    }

    final distance = premiumDiscountPct.abs();
    if (distance <= 0.20) {
      return PremiumDiscountAssessment(
        level: PremiumDiscountLevel.normal,
        premiumDiscountPct: premiumDiscountPct,
      );
    }
    if (distance <= 0.50) {
      return PremiumDiscountAssessment(
        level: PremiumDiscountLevel.watch,
        premiumDiscountPct: premiumDiscountPct,
      );
    }
    if (distance <= 1.00) {
      return PremiumDiscountAssessment(
        level: PremiumDiscountLevel.elevated,
        premiumDiscountPct: premiumDiscountPct,
      );
    }
    return PremiumDiscountAssessment(
      level: PremiumDiscountLevel.extreme,
      premiumDiscountPct: premiumDiscountPct,
    );
  }

  final PremiumDiscountLevel level;
  final double? premiumDiscountPct;

  bool get isPremium => (premiumDiscountPct ?? 0) > 0;
  bool get isDiscount => (premiumDiscountPct ?? 0) < 0;

  String get label {
    switch (level) {
      case PremiumDiscountLevel.unavailable:
        return '即時資料不可用';
      case PremiumDiscountLevel.stale:
        return '資料可能過期';
      case PremiumDiscountLevel.normal:
        return '正常';
      case PremiumDiscountLevel.watch:
        return isDiscount ? '折價觀察' : '溢價觀察';
      case PremiumDiscountLevel.elevated:
        return isDiscount ? '折價偏深' : '溢價偏高';
      case PremiumDiscountLevel.extreme:
        return isDiscount ? '折價極端' : '溢價極端';
    }
  }

  String get tone {
    switch (level) {
      case PremiumDiscountLevel.unavailable:
      case PremiumDiscountLevel.stale:
        return 'neutral';
      case PremiumDiscountLevel.normal:
        return 'normal';
      case PremiumDiscountLevel.watch:
        return 'watch';
      case PremiumDiscountLevel.elevated:
        return 'elevated';
      case PremiumDiscountLevel.extreme:
        return 'extreme';
    }
  }

  String get description {
    final premium = premiumDiscountPct;
    if (level == PremiumDiscountLevel.unavailable || premium == null) {
      return '即時淨值資料不可用，暫時無法判斷折溢價狀態。非買賣建議。';
    }
    if (level == PremiumDiscountLevel.stale) {
      return '即時淨值資料可能過期，請以資料時間與官方來源為準。非買賣建議。';
    }

    final value = _signedPercentText(premium);
    final relation = premium >= 0 ? '市價高於預估淨值' : '市價低於預估淨值';
    if (level == PremiumDiscountLevel.normal) {
      return '目前$relation $value，折溢價接近預估淨值。這是價格偏離提示，非買賣建議。';
    }
    return '目前$relation $value，屬於$label。這是價格偏離提示，非買賣建議。';
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

class EtfHoldingsHistoryPoint {
  const EtfHoldingsHistoryPoint({
    required this.tradeDate,
    required this.txWeightPct,
    required this.tsmcWeightPct,
    required this.stockExposurePct,
    required this.futuresExposurePct,
    required this.cashAndMarginPct,
    required this.navPerUnit,
    required this.fundNetAssetValue,
    required this.outstandingUnits,
    required this.status,
    required this.sourceHash,
  });

  final DateTime tradeDate;
  final double txWeightPct;
  final double tsmcWeightPct;
  final double stockExposurePct;
  final double futuresExposurePct;
  final double cashAndMarginPct;
  final double navPerUnit;
  final double fundNetAssetValue;
  final int outstandingUnits;
  final EtfDataStatus status;
  final String sourceHash;
}

class EtfHoldingsHistory {
  const EtfHoldingsHistory({
    required this.points,
    required this.status,
    required this.sourceStatusLabel,
    required this.sourceUrl,
    required this.lastFetchedAt,
    required this.isStale,
    this.errorMessage,
  });

  factory EtfHoldingsHistory.empty({
    DateTime? lastFetchedAt,
    EtfDataStatus status = EtfDataStatus.mock,
    String sourceStatusLabel = 'mock',
    String? errorMessage,
  }) {
    return EtfHoldingsHistory(
      points: const [],
      status: status,
      sourceStatusLabel: sourceStatusLabel,
      sourceUrl: '',
      lastFetchedAt: lastFetchedAt ?? DateTime.now(),
      isStale: true,
      errorMessage: errorMessage,
    );
  }

  final List<EtfHoldingsHistoryPoint> points;
  final EtfDataStatus status;
  final String sourceStatusLabel;
  final String sourceUrl;
  final DateTime lastFetchedAt;
  final bool isStale;
  final String? errorMessage;

  bool get hasData => points.isNotEmpty;

  EtfHoldingsHistoryTrendSummary trendSummary({int limit = 30}) {
    return EtfHoldingsHistoryTrendSummary.fromPoints(points, limit: limit);
  }
}

class EtfHoldingsHistoryTrendSummary {
  const EtfHoldingsHistoryTrendSummary({
    required this.points,
    required this.recentSeven,
    required this.latest,
    required this.previous,
    required this.first,
    required this.changeLines,
  });

  factory EtfHoldingsHistoryTrendSummary.fromPoints(
    List<EtfHoldingsHistoryPoint> points, {
    int limit = 30,
  }) {
    final ordered = [...points]
      ..sort((a, b) => b.tradeDate.compareTo(a.tradeDate));
    final selected = ordered.take(limit).toList();
    final latest = selected.isEmpty ? null : selected.first;
    final previous = selected.length > 1 ? selected[1] : null;
    final first = selected.isEmpty ? null : selected.last;
    return EtfHoldingsHistoryTrendSummary(
      points: selected,
      recentSeven: ordered.take(7).toList(),
      latest: latest,
      previous: previous,
      first: first,
      changeLines: latest == null
          ? const []
          : [
              _changeLine(
                key: 'txWeightPct',
                latest: latest,
                previous: previous,
                first: first,
                valueOf: (point) => point.txWeightPct,
                isPercent: true,
              ),
              _changeLine(
                key: 'tsmcWeightPct',
                latest: latest,
                previous: previous,
                first: first,
                valueOf: (point) => point.tsmcWeightPct,
                isPercent: true,
              ),
              _changeLine(
                key: 'stockExposurePct',
                latest: latest,
                previous: previous,
                first: first,
                valueOf: (point) => point.stockExposurePct,
                isPercent: true,
              ),
              _changeLine(
                key: 'futuresExposurePct',
                latest: latest,
                previous: previous,
                first: first,
                valueOf: (point) => point.futuresExposurePct,
                isPercent: true,
              ),
              _changeLine(
                key: 'cashAndMarginPct',
                latest: latest,
                previous: previous,
                first: first,
                valueOf: (point) => point.cashAndMarginPct,
                isPercent: true,
              ),
              _changeLine(
                key: 'navPerUnit',
                latest: latest,
                previous: previous,
                first: first,
                valueOf: (point) => point.navPerUnit,
                isPercent: false,
              ),
              _changeLine(
                key: 'outstandingUnits',
                latest: latest,
                previous: previous,
                first: first,
                valueOf: (point) => point.outstandingUnits.toDouble(),
                isPercent: false,
              ),
            ],
    );
  }

  final List<EtfHoldingsHistoryPoint> points;
  final List<EtfHoldingsHistoryPoint> recentSeven;
  final EtfHoldingsHistoryPoint? latest;
  final EtfHoldingsHistoryPoint? previous;
  final EtfHoldingsHistoryPoint? first;
  final List<EtfHoldingsHistoryChangeLine> changeLines;

  bool get hasDayOverDay => previous != null;
  bool get hasFirstToLatest =>
      latest != null && first != null && latest != first;
}

class EtfHoldingsHistoryChangeLine {
  const EtfHoldingsHistoryChangeLine({
    required this.key,
    required this.latestValue,
    required this.dayOverDayChange,
    required this.firstToLatestChange,
    required this.isPercent,
  });

  final String key;
  final double latestValue;
  final double? dayOverDayChange;
  final double? firstToLatestChange;
  final bool isPercent;
}

EtfHoldingsHistoryChangeLine _changeLine({
  required String key,
  required EtfHoldingsHistoryPoint latest,
  required EtfHoldingsHistoryPoint? previous,
  required EtfHoldingsHistoryPoint? first,
  required double Function(EtfHoldingsHistoryPoint point) valueOf,
  required bool isPercent,
}) {
  final latestValue = valueOf(latest);
  return EtfHoldingsHistoryChangeLine(
    key: key,
    latestValue: latestValue,
    dayOverDayChange: previous == null ? null : latestValue - valueOf(previous),
    firstToLatestChange: first == null ? null : latestValue - valueOf(first),
    isPercent: isPercent,
  );
}

enum HoldingChangeNoticeLevel {
  unavailable,
  normal,
  watch,
  elevated,
  stale,
}

class HoldingChangeNotice {
  const HoldingChangeNotice({
    required this.level,
    required this.title,
    required this.message,
  });

  final HoldingChangeNoticeLevel level;
  final String title;
  final String message;
}

class HoldingsChangeAssessment {
  const HoldingsChangeAssessment({
    required this.notices,
    required this.statusLabel,
  });

  factory HoldingsChangeAssessment.evaluate({
    required EtfHoldingsHistory history,
    required EtfDailyHoldingSnapshot snapshot,
    required DateTime now,
  }) {
    final notices = <HoldingChangeNotice>[];

    if (snapshot.isStale(now)) {
      notices.add(
        const HoldingChangeNotice(
          level: HoldingChangeNoticeLevel.stale,
          title: '官方內容物可能過期',
          message: '官方 holdings 超過 1 個交易日未更新，請以資料時間與官方來源為準。這是資料狀態提醒，非買賣建議。',
        ),
      );
    }

    final points = [...history.points]
      ..sort((a, b) => b.tradeDate.compareTo(a.tradeDate));
    if (points.length < 2) {
      notices.add(
        HoldingChangeNotice(
          level: HoldingChangeNoticeLevel.unavailable,
          title: history.hasData ? '歷史資料仍在累積' : '尚無足夠歷史紀錄',
          message:
              '需要至少 2 個官方 holdings 交易日，才會比較 TX、台積電、現金與保證金、曝險比例變化。這是資料狀態提醒，非買賣建議。',
        ),
      );
      return HoldingsChangeAssessment(
        notices: notices,
        statusLabel: _holdingNoticeStatusLabel(notices),
      );
    }

    final latest = points[0];
    final previous = points[1];
    final txDelta = latest.txWeightPct - previous.txWeightPct;
    final tsmcDelta = latest.tsmcWeightPct - previous.tsmcWeightPct;
    final cashDelta = latest.cashAndMarginPct - previous.cashAndMarginPct;
    final futuresDelta =
        latest.futuresExposurePct - previous.futuresExposurePct;
    final totalExposure = latest.stockExposurePct + latest.futuresExposurePct;

    if (txDelta.abs() >= 5.0) {
      notices.add(
        HoldingChangeNotice(
          level: HoldingChangeNoticeLevel.elevated,
          title: 'TX 權重變化較大',
          message:
              '最近兩筆 official holdings 的 TX 權重變化 ${_signedDeltaPercentText(txDelta)}，請搭配 tradeDate 與 sourceStatus 觀察。這是資料狀態提醒，非買賣建議。',
        ),
      );
    }

    if (tsmcDelta.abs() >= 2.0) {
      notices.add(
        HoldingChangeNotice(
          level: HoldingChangeNoticeLevel.watch,
          title: '台積電權重變化較大',
          message:
              '最近兩筆 official holdings 的台積電權重變化 ${_signedDeltaPercentText(tsmcDelta)}，代表每日內容物結構出現可觀察變化。這是資料狀態提醒，非買賣建議。',
        ),
      );
    }

    if (cashDelta >= 5.0) {
      notices.add(
        HoldingChangeNotice(
          level: HoldingChangeNoticeLevel.watch,
          title: '現金與保證金比例上升',
          message:
              '最近兩筆 official holdings 的現金與保證金比例增加 ${_signedDeltaPercentText(cashDelta)}，請確認是否與期貨保證金或申贖變化有關。這是資料狀態提醒，非買賣建議。',
        ),
      );
    }

    if (futuresDelta.abs() >= 10.0) {
      notices.add(
        HoldingChangeNotice(
          level: HoldingChangeNoticeLevel.watch,
          title: '期貨資產比例變化較大',
          message:
              '最近兩筆 official holdings 的期貨資產比例變化 ${_signedDeltaPercentText(futuresDelta)}，請搭配股票資產與現金保證金一起觀察。這是資料狀態提醒，非買賣建議。',
        ),
      );
    }

    if (totalExposure < 180.0 || totalExposure > 220.0) {
      notices.add(
        HoldingChangeNotice(
          level: HoldingChangeNoticeLevel.elevated,
          title: '合計曝險超出參考區間',
          message:
              '最近一筆 official holdings 的股票與期貨合計曝險約 ${totalExposure.toStringAsFixed(2)}%，不在 180%-220% 參考區間。這是資料狀態提醒，非買賣建議。',
        ),
      );
    }

    if (notices.isEmpty) {
      notices.add(
        const HoldingChangeNotice(
          level: HoldingChangeNoticeLevel.normal,
          title: '內容物結構無明顯變化',
          message: '最近兩筆 official holdings 的主要權重變化未達提醒門檻。這是資料狀態提醒，非買賣建議。',
        ),
      );
    }

    return HoldingsChangeAssessment(
      notices: notices,
      statusLabel: _holdingNoticeStatusLabel(notices),
    );
  }

  final List<HoldingChangeNotice> notices;
  final String statusLabel;
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
    required this.isStale,
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
  final bool isStale;
  final EtfDataStatus status;
  final DateTime lastFetchedAt;

  PremiumDiscountAssessment get premiumDiscountAssessment {
    return PremiumDiscountAssessment.evaluate(
      premiumDiscountPct: estimatedPremiumDiscountPct,
      sourceStatus: status,
      isStale: isStale,
    );
  }
}

class EtfIntradayNavHistoryPoint {
  const EtfIntradayNavHistoryPoint({
    required this.dataTime,
    required this.marketPrice,
    required this.estimatedNav,
    required this.premiumDiscountPct,
    required this.sourceContract,
  });

  final DateTime dataTime;
  final double? marketPrice;
  final double? estimatedNav;
  final double? premiumDiscountPct;
  final String? sourceContract;
}

class EtfIntradayNavHistorySummary {
  const EtfIntradayNavHistorySummary({
    required this.points,
    required this.sampleCount,
    required this.highestPremiumDiscountPct,
    required this.lowestPremiumDiscountPct,
    required this.averagePremiumDiscountPct,
    required this.firstDataTime,
    required this.lastDataTime,
    required this.latestMarketPrice,
    required this.latestEstimatedNav,
    required this.date,
    required this.status,
    required this.sourceStatusLabel,
    required this.sourceUrl,
    required this.lastFetchedAt,
    required this.isStale,
    this.errorMessage,
  });

  factory EtfIntradayNavHistorySummary.empty({
    DateTime? lastFetchedAt,
    EtfDataStatus status = EtfDataStatus.mock,
    String sourceStatusLabel = 'mock',
    String? errorMessage,
  }) {
    return EtfIntradayNavHistorySummary(
      points: const [],
      sampleCount: 0,
      highestPremiumDiscountPct: null,
      lowestPremiumDiscountPct: null,
      averagePremiumDiscountPct: null,
      firstDataTime: null,
      lastDataTime: null,
      latestMarketPrice: null,
      latestEstimatedNav: null,
      date: null,
      status: status,
      sourceStatusLabel: sourceStatusLabel,
      sourceUrl: '',
      lastFetchedAt: lastFetchedAt ?? DateTime.now(),
      isStale: true,
      errorMessage: errorMessage,
    );
  }

  final List<EtfIntradayNavHistoryPoint> points;
  final int sampleCount;
  final double? highestPremiumDiscountPct;
  final double? lowestPremiumDiscountPct;
  final double? averagePremiumDiscountPct;
  final DateTime? firstDataTime;
  final DateTime? lastDataTime;
  final double? latestMarketPrice;
  final double? latestEstimatedNav;
  final DateTime? date;
  final EtfDataStatus status;
  final String sourceStatusLabel;
  final String sourceUrl;
  final DateTime lastFetchedAt;
  final bool isStale;
  final String? errorMessage;

  bool get hasData => sampleCount > 0 || points.isNotEmpty;
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

enum EtfStatusSummaryLevel {
  normal,
  watch,
  elevated,
  unavailable,
  stale,
  error,
}

class EtfStatusSummary {
  const EtfStatusSummary({
    required this.level,
    required this.label,
    required this.lines,
  });

  factory EtfStatusSummary.evaluate({
    required LeveragedEtfProfile profile,
    required EtfDailyHoldingSnapshot snapshot,
    required EtfIntradayNav? intradayNav,
    required EtfHoldingsHistory holdingsHistory,
    required EtfIntradayNavHistorySummary intradayNavHistory,
    required HoldingsChangeAssessment holdingsChangeAssessment,
    required DateTime now,
  }) {
    final premiumAssessment = intradayNav?.premiumDiscountAssessment ??
        PremiumDiscountAssessment.evaluate(
          premiumDiscountPct: null,
          sourceStatus: EtfDataStatus.error,
          isStale: false,
        );
    final level = _statusSummaryLevel(
      profile: profile,
      snapshot: snapshot,
      intradayNav: intradayNav,
      premiumAssessment: premiumAssessment,
      holdingsChangeAssessment: holdingsChangeAssessment,
      now: now,
    );

    final lines = <String>[
      '官方內容物日期 ${_dateText(snapshot.tradeDate)}，holdings sourceStatus ${snapshot.status.label}。',
      if (intradayNav == null)
        '即時淨值資料不可用，暫時只能檢視官方每日內容物與已保存的歷史資料。'
      else
        '即時淨值來源 ${intradayNav.sourceContract ?? 'unavailable'}，折溢價 ${_nullableSignedPercentText(intradayNav.estimatedPremiumDiscountPct)}，狀態 ${premiumAssessment.label}。',
      '內容物變化狀態 ${holdingsChangeAssessment.statusLabel}，history sourceStatus ${holdingsHistory.sourceStatusLabel}。',
      if (intradayNavHistory.hasData)
        '盤中折溢價歷史 ${intradayNavHistory.sampleCount} 筆，平均 ${_nullableSignedPercentText(intradayNavHistory.averagePremiumDiscountPct)}。'
      else
        '盤中折溢價歷史尚未累積，intradayHistory sourceStatus ${intradayNavHistory.sourceStatusLabel}。',
      '此摘要只描述資料狀態與偏離程度，非買賣建議。',
    ];

    return EtfStatusSummary(
      level: level,
      label: _statusSummaryLabel(level),
      lines: lines,
    );
  }

  final EtfStatusSummaryLevel level;
  final String label;
  final List<String> lines;
}

enum EtfDailyReadinessLevel {
  ready,
  attention,
  actionNeeded,
}

class EtfDailyReadinessCheck {
  const EtfDailyReadinessCheck({
    required this.label,
    required this.statusLabel,
    required this.detail,
    required this.level,
    this.action,
  });

  final String label;
  final String statusLabel;
  final String detail;
  final EtfDailyReadinessLevel level;
  final String? action;

  bool get isReady => level == EtfDailyReadinessLevel.ready;
}

class EtfDailyReadinessSummary {
  const EtfDailyReadinessSummary({
    required this.level,
    required this.label,
    required this.headline,
    required this.checks,
  });

  final EtfDailyReadinessLevel level;
  final String label;
  final String headline;
  final List<EtfDailyReadinessCheck> checks;

  int get readyCount => checks
      .where((check) => check.level == EtfDailyReadinessLevel.ready)
      .length;

  int get attentionCount => checks
      .where((check) => check.level == EtfDailyReadinessLevel.attention)
      .length;

  int get actionNeededCount => checks
      .where((check) => check.level == EtfDailyReadinessLevel.actionNeeded)
      .length;
}

String _dailyReadinessLabel(EtfDailyReadinessLevel level) {
  switch (level) {
    case EtfDailyReadinessLevel.ready:
      return '可日常使用';
    case EtfDailyReadinessLevel.attention:
      return '需要觀察';
    case EtfDailyReadinessLevel.actionNeeded:
      return '需要處理';
  }
}

String _dailyReadinessHeadline(EtfDailyReadinessLevel level) {
  switch (level) {
    case EtfDailyReadinessLevel.ready:
      return '資料鏈與本機流程目前可日常使用。';
    case EtfDailyReadinessLevel.attention:
      return '資料鏈可使用，但有項目需要確認。';
    case EtfDailyReadinessLevel.actionNeeded:
      return '有項目需要先處理，請依下方程式操作檢查。';
  }
}

String _dailyReadinessDateText(DateTime? value) {
  if (value == null) {
    return 'unknown';
  }
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}/$month/$day';
}

String _dailyReadinessDateTimeText(DateTime? value) {
  if (value == null) {
    return 'unknown';
  }
  final date = _dailyReadinessDateText(value);
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '$date $hour:$minute:$second';
}

class EtfOperationsStatus {
  const EtfOperationsStatus({
    required this.status,
    required this.sourceStatusLabel,
    required this.sourceContract,
    required this.sourceUrl,
    required this.lastFetchedAt,
    required this.sourceUpdatedAt,
    required this.isStale,
    required this.intradaySourceMode,
    required this.twseIntradayNavConfigured,
    required this.yuantaIntradayNavConfigured,
    this.publicApiBaseUrl = '',
    this.allowedOrigins = const [],
    this.dataRoot = '',
    this.dataPersistenceMode = 'local',
    this.dataPersistenceWarning,
    this.dataPathWritable = false,
    this.dataPathPersistent = false,
    required this.holdingsHistoryStatus,
    required this.holdingsHistoryItemCount,
    required this.latestHoldingTradeDate,
    required this.intradayHistoryStatus,
    required this.intradaySampleCount,
    required this.latestIntradayDataTime,
    required this.intradayHistoryDate,
    this.priceHistoryStatus = 'unavailable',
    this.priceHistoryRows = 0,
    this.priceHistoryCoverageStart,
    this.priceHistoryCoverageEnd,
    this.priceHistoryCompleteFromListing = false,
    this.backtestStatus = 'unavailable',
    this.backtestAvailable = false,
    this.positionStatus = 'local_only',
    required this.collectorOneShotCommand,
    required this.collectorIntradayCommand,
    this.envFileExists = false,
    this.missingEnvKeys = const [],
    this.optionalMissingEnvKeys = const [],
    this.dataDirReady = false,
    this.exportDirReady = false,
    this.backupDirReady = false,
    this.exportAvailable = false,
    this.latestExportPath,
    this.latestExportUpdatedAt,
    this.backupAvailable = false,
    this.latestBackupPath,
    this.latestBackupUpdatedAt,
    this.reportAvailable = false,
    this.latestReportPath,
    this.latestReportGeneratedAt,
    this.reportOverallStatus = 'missing',
    this.reportWarningCount = 0,
    this.reportFailureCount = 0,
    this.dailyCycleStatus = 'missing',
    this.dailyCycleStartedAt,
    this.dailyCycleFinishedAt,
    this.dailyCycleWarningCount = 0,
    this.dailyCycleFailureCount = 0,
    this.errorMessage,
  });

  factory EtfOperationsStatus.empty({
    DateTime? lastFetchedAt,
    EtfDataStatus status = EtfDataStatus.mock,
    String sourceStatusLabel = 'mock',
    String? errorMessage,
  }) {
    return EtfOperationsStatus(
      status: status,
      sourceStatusLabel: sourceStatusLabel,
      sourceContract: '00631l_operations_status',
      sourceUrl: '',
      lastFetchedAt: lastFetchedAt ?? DateTime.now(),
      sourceUpdatedAt: null,
      isStale: true,
      intradaySourceMode: 'auto',
      twseIntradayNavConfigured: false,
      yuantaIntradayNavConfigured: false,
      publicApiBaseUrl: '',
      allowedOrigins: const [],
      dataRoot: '',
      dataPersistenceMode: 'local',
      dataPersistenceWarning: 'backend disconnected; persistence unknown.',
      dataPathWritable: false,
      dataPathPersistent: false,
      holdingsHistoryStatus: sourceStatusLabel,
      holdingsHistoryItemCount: 0,
      latestHoldingTradeDate: null,
      intradayHistoryStatus: sourceStatusLabel,
      intradaySampleCount: 0,
      latestIntradayDataTime: null,
      intradayHistoryDate: null,
      priceHistoryStatus: sourceStatusLabel,
      priceHistoryRows: 0,
      priceHistoryCoverageStart: null,
      priceHistoryCoverageEnd: null,
      priceHistoryCompleteFromListing: false,
      backtestStatus: sourceStatusLabel,
      backtestAvailable: false,
      positionStatus: 'local_only',
      collectorOneShotCommand:
          'scripts\\00631l_collect_snapshot.cmd --samples 1',
      collectorIntradayCommand:
          'scripts\\00631l_collect_snapshot.cmd --skip-profile --skip-holdings --samples 20 --interval-seconds 15',
      envFileExists: false,
      missingEnvKeys: const ['backend/.env', 'TWSE_00631L_INTRADAY_NAV_URL'],
      optionalMissingEnvKeys: const ['YUANTA_00631L_INTRADAY_NAV_URL'],
      dataDirReady: false,
      exportDirReady: false,
      backupDirReady: false,
      exportAvailable: false,
      latestExportPath: null,
      latestExportUpdatedAt: null,
      backupAvailable: false,
      latestBackupPath: null,
      latestBackupUpdatedAt: null,
      reportAvailable: false,
      latestReportPath: null,
      latestReportGeneratedAt: null,
      reportOverallStatus: 'missing',
      reportWarningCount: 0,
      reportFailureCount: 0,
      dailyCycleStatus: 'missing',
      dailyCycleStartedAt: null,
      dailyCycleFinishedAt: null,
      dailyCycleWarningCount: 0,
      dailyCycleFailureCount: 0,
      errorMessage: errorMessage,
    );
  }

  final EtfDataStatus status;
  final String sourceStatusLabel;
  final String sourceContract;
  final String sourceUrl;
  final DateTime lastFetchedAt;
  final DateTime? sourceUpdatedAt;
  final bool isStale;
  final String intradaySourceMode;
  final bool twseIntradayNavConfigured;
  final bool yuantaIntradayNavConfigured;
  final String publicApiBaseUrl;
  final List<String> allowedOrigins;
  final String dataRoot;
  final String dataPersistenceMode;
  final String? dataPersistenceWarning;
  final bool dataPathWritable;
  final bool dataPathPersistent;
  final String holdingsHistoryStatus;
  final int holdingsHistoryItemCount;
  final DateTime? latestHoldingTradeDate;
  final String intradayHistoryStatus;
  final int intradaySampleCount;
  final DateTime? latestIntradayDataTime;
  final DateTime? intradayHistoryDate;
  final String priceHistoryStatus;
  final int priceHistoryRows;
  final DateTime? priceHistoryCoverageStart;
  final DateTime? priceHistoryCoverageEnd;
  final bool priceHistoryCompleteFromListing;
  final String backtestStatus;
  final bool backtestAvailable;
  final String positionStatus;
  final String collectorOneShotCommand;
  final String collectorIntradayCommand;
  final bool envFileExists;
  final List<String> missingEnvKeys;
  final List<String> optionalMissingEnvKeys;
  final bool dataDirReady;
  final bool exportDirReady;
  final bool backupDirReady;
  final bool exportAvailable;
  final String? latestExportPath;
  final DateTime? latestExportUpdatedAt;
  final bool backupAvailable;
  final String? latestBackupPath;
  final DateTime? latestBackupUpdatedAt;
  final bool reportAvailable;
  final String? latestReportPath;
  final DateTime? latestReportGeneratedAt;
  final String reportOverallStatus;
  final int reportWarningCount;
  final int reportFailureCount;
  final String dailyCycleStatus;
  final DateTime? dailyCycleStartedAt;
  final DateTime? dailyCycleFinishedAt;
  final int dailyCycleWarningCount;
  final int dailyCycleFailureCount;
  final String? errorMessage;

  bool get hasAnyHistory =>
      holdingsHistoryItemCount > 0 ||
      intradaySampleCount > 0 ||
      priceHistoryRows > 0;

  bool get envReady =>
      missingEnvKeys.isEmpty &&
      dataDirReady &&
      exportDirReady &&
      backupDirReady;

  bool get dataDirectoriesReady =>
      dataDirReady && exportDirReady && backupDirReady;

  String get dataPersistenceLabel {
    if (sourceStatusLabel == 'mock' || backendDisconnected) {
      return 'persistence unknown';
    }
    if (!dataPathWritable) {
      return 'data path not writable';
    }
    if (dataPathPersistent) {
      return 'persistent data ready';
    }
    if (dataPersistenceMode == 'transient') {
      return 'transient data mode';
    }
    return 'local data mode';
  }

  String get dataPersistenceCaption {
    if (sourceStatusLabel == 'mock' || backendDisconnected) {
      return 'backend operations/status is required to verify persistence';
    }
    if (dataPersistenceWarning != null && dataPersistenceWarning!.isNotEmpty) {
      return dataPersistenceWarning!;
    }
    if (dataPathPersistent) {
      return 'public deployment data path is configured as persistent';
    }
    return 'public deployment should use a persistent volume';
  }

  bool get backendDisconnected {
    final message = errorMessage?.toLowerCase() ?? '';
    return status == EtfDataStatus.error &&
        sourceStatusLabel == 'error' &&
        message.contains('backend');
  }

  String get backendConnectionLabel {
    if (backendDisconnected) {
      return 'backend disconnected';
    }
    if (sourceStatusLabel == 'mock') {
      return 'mock fallback';
    }
    if (sourceStatusLabel == 'unavailable') {
      return 'backend unavailable';
    }
    if (sourceStatusLabel == 'error') {
      return 'backend error';
    }
    return 'backend reachable';
  }

  String get backendConnectionCaption {
    if (backendDisconnected) {
      return 'start scripts\\00631l_start_backend.cmd; fallback remains visible';
    }
    if (sourceStatusLabel == 'mock') {
      return 'live proxy disabled or using safe fallback';
    }
    if (sourceStatusLabel == 'unavailable' || sourceStatusLabel == 'error') {
      return errorMessage ?? 'operations status unavailable';
    }
    return 'operations/status response received';
  }

  EtfDailyReadinessSummary get dailyReadinessSummary {
    final checks = <EtfDailyReadinessCheck>[
      _backendReadinessCheck(),
      _holdingsReadinessCheck(),
      _intradayReadinessCheck(),
      _dailyCycleReadinessCheck(),
      _reportReadinessCheck(),
      _exportReadinessCheck(),
      _backupReadinessCheck(),
      _localStateReadinessCheck(),
    ];

    final hasAction = checks.any(
      (check) => check.level == EtfDailyReadinessLevel.actionNeeded,
    );
    final hasAttention = checks.any(
      (check) => check.level == EtfDailyReadinessLevel.attention,
    );
    final level = hasAction
        ? EtfDailyReadinessLevel.actionNeeded
        : (hasAttention
            ? EtfDailyReadinessLevel.attention
            : EtfDailyReadinessLevel.ready);

    return EtfDailyReadinessSummary(
      level: level,
      label: _dailyReadinessLabel(level),
      headline: _dailyReadinessHeadline(level),
      checks: checks,
    );
  }

  EtfDailyReadinessCheck _backendReadinessCheck() {
    if (backendDisconnected ||
        sourceStatusLabel == 'error' ||
        sourceStatusLabel == 'unavailable') {
      return EtfDailyReadinessCheck(
        label: 'backend 連線',
        statusLabel: backendConnectionLabel,
        detail: backendConnectionCaption,
        level: EtfDailyReadinessLevel.actionNeeded,
        action: '執行 scripts\\00631l_start_backend.cmd，重新開啟 /#/00631l-lab。',
      );
    }
    if (sourceStatusLabel == 'mock') {
      return EtfDailyReadinessCheck(
        label: 'backend 連線',
        statusLabel: backendConnectionLabel,
        detail: '目前是 mock/fallback 模式，畫面可讀但不是 live proxy。',
        level: EtfDailyReadinessLevel.attention,
        action: '需要 live 資料時，請用 live proxy 啟動 frontend。',
      );
    }
    return EtfDailyReadinessCheck(
      label: 'backend 連線',
      statusLabel: backendConnectionLabel,
      detail: 'operations/status 已回應。',
      level: EtfDailyReadinessLevel.ready,
    );
  }

  EtfDailyReadinessCheck _holdingsReadinessCheck() {
    final hasHoldings =
        holdingsHistoryItemCount > 0 && latestHoldingTradeDate != null;
    final abnormal = holdingsHistoryStatus == 'error' ||
        holdingsHistoryStatus == 'unavailable' ||
        holdingsHistoryStatus == 'mock';
    if (!hasHoldings || abnormal) {
      return EtfDailyReadinessCheck(
        label: 'official holdings',
        statusLabel: holdingsHistoryStatus,
        detail: hasHoldings
            ? 'latest ${_dailyReadinessDateText(latestHoldingTradeDate)}；sourceStatus $holdingsHistoryStatus。'
            : '尚無 official holdings history。',
        level: abnormal
            ? EtfDailyReadinessLevel.actionNeeded
            : EtfDailyReadinessLevel.attention,
        action:
            '執行 scripts\\00631l_daily_cycle.cmd 累積 official holdings history。',
      );
    }
    return EtfDailyReadinessCheck(
      label: 'official holdings',
      statusLabel: holdingsHistoryStatus,
      detail:
          '$holdingsHistoryItemCount 筆，latest ${_dailyReadinessDateText(latestHoldingTradeDate)}。',
      level: holdingsHistoryStatus == 'stale'
          ? EtfDailyReadinessLevel.attention
          : EtfDailyReadinessLevel.ready,
      action: holdingsHistoryStatus == 'stale'
          ? '請執行 daily cycle 並確認 Yuanta ratio 來源。'
          : null,
    );
  }

  EtfDailyReadinessCheck _intradayReadinessCheck() {
    final hasIntraday =
        intradaySampleCount > 0 && latestIntradayDataTime != null;
    final abnormal = intradayHistoryStatus == 'error' ||
        intradayHistoryStatus == 'unavailable' ||
        !twseIntradayNavConfigured;
    if (!hasIntraday || abnormal) {
      return EtfDailyReadinessCheck(
        label: 'intraday NAV',
        statusLabel: intradayHistoryStatus,
        detail: hasIntraday
            ? 'latest ${_dailyReadinessDateTimeText(latestIntradayDataTime)}；TWSE URL ${twseIntradayNavConfigured ? 'configured' : 'missing'}。'
            : '尚無 intraday NAV history。',
        level: abnormal
            ? EtfDailyReadinessLevel.actionNeeded
            : EtfDailyReadinessLevel.attention,
        action: '檢查 TWSE URL 設定與交易時段，必要時執行 daily cycle。',
      );
    }
    return EtfDailyReadinessCheck(
      label: 'intraday NAV',
      statusLabel: intradayHistoryStatus,
      detail:
          '$intradaySampleCount 筆，latest ${_dailyReadinessDateTimeText(latestIntradayDataTime)}。',
      level: intradayHistoryStatus == 'stale'
          ? EtfDailyReadinessLevel.attention
          : EtfDailyReadinessLevel.ready,
      action: intradayHistoryStatus == 'stale'
          ? '請以資料時間為準，必要時重新執行 daily cycle。'
          : null,
    );
  }

  EtfDailyReadinessCheck _dailyCycleReadinessCheck() {
    if (dailyCycleStatus == 'PASS' && dailyCycleFinishedAt != null) {
      return EtfDailyReadinessCheck(
        label: 'daily cycle',
        statusLabel: dailyCycleStatus,
        detail:
            'finished ${_dailyReadinessDateTimeText(dailyCycleFinishedAt)}；warnings $dailyCycleWarningCount，failures $dailyCycleFailureCount。',
        level: dailyCycleWarningCount > 0
            ? EtfDailyReadinessLevel.attention
            : EtfDailyReadinessLevel.ready,
        action: dailyCycleWarningCount > 0
            ? '查看 daily report 與 smoke WARN 說明。'
            : null,
      );
    }
    return EtfDailyReadinessCheck(
      label: 'daily cycle',
      statusLabel: dailyCycleStatus,
      detail: dailyCycleFinishedAt == null
          ? '尚未執行 daily cycle。'
          : 'finished ${_dailyReadinessDateTimeText(dailyCycleFinishedAt)}；failures $dailyCycleFailureCount。',
      level: dailyCycleFailureCount > 0 || dailyCycleStatus == 'FAIL'
          ? EtfDailyReadinessLevel.actionNeeded
          : EtfDailyReadinessLevel.attention,
      action: '執行 scripts\\00631l_daily_cycle.cmd，完成後查看今日資料狀態。',
    );
  }

  EtfDailyReadinessCheck _reportReadinessCheck() {
    if (!reportAvailable) {
      return const EtfDailyReadinessCheck(
        label: 'daily report',
        statusLabel: 'missing',
        detail: '尚無最新日報。',
        level: EtfDailyReadinessLevel.attention,
        action: '執行 scripts\\00631l_generate_daily_report.cmd 或 daily cycle。',
      );
    }
    return EtfDailyReadinessCheck(
      label: 'daily report',
      statusLabel: reportOverallStatus,
      detail:
          'generated ${_dailyReadinessDateTimeText(latestReportGeneratedAt)}；warnings $reportWarningCount，failures $reportFailureCount。',
      level: reportFailureCount > 0 || reportOverallStatus == 'FAIL'
          ? EtfDailyReadinessLevel.actionNeeded
          : (reportWarningCount > 0
              ? EtfDailyReadinessLevel.attention
              : EtfDailyReadinessLevel.ready),
      action: reportFailureCount > 0 || reportWarningCount > 0
          ? '查看最新 daily report 的 WARN/FAIL 區塊。'
          : null,
    );
  }

  EtfDailyReadinessCheck _exportReadinessCheck() {
    if (!exportAvailable) {
      return const EtfDailyReadinessCheck(
        label: 'CSV export',
        statusLabel: 'missing',
        detail: '尚無 CSV export。',
        level: EtfDailyReadinessLevel.attention,
        action: '執行 scripts\\00631l_export_history.cmd。',
      );
    }
    return EtfDailyReadinessCheck(
      label: 'CSV export',
      statusLabel: 'ready',
      detail: 'updated ${_dailyReadinessDateTimeText(latestExportUpdatedAt)}。',
      level: EtfDailyReadinessLevel.ready,
    );
  }

  EtfDailyReadinessCheck _backupReadinessCheck() {
    if (!backupAvailable) {
      return const EtfDailyReadinessCheck(
        label: 'local backup',
        statusLabel: 'missing',
        detail: '尚無 local backup。',
        level: EtfDailyReadinessLevel.attention,
        action: '執行 scripts\\00631l_backup_data.cmd。',
      );
    }
    return EtfDailyReadinessCheck(
      label: 'local backup',
      statusLabel: 'ready',
      detail: 'updated ${_dailyReadinessDateTimeText(latestBackupUpdatedAt)}。',
      level: EtfDailyReadinessLevel.ready,
    );
  }

  EtfDailyReadinessCheck _localStateReadinessCheck() {
    if (!envReady) {
      return EtfDailyReadinessCheck(
        label: 'local state',
        statusLabel: 'check',
        detail: 'env 或 data/export/backup 目錄需要確認。',
        level: EtfDailyReadinessLevel.actionNeeded,
        action: missingEnvKeys.any((key) => key.contains('.env'))
            ? '從 backend\\.env.example 建立 backend\\.env，並執行 scripts\\00631l_check_env.cmd。'
            : '執行 scripts\\00631l_check_env.cmd 檢查本機目錄與設定。',
      );
    }
    if (!dataPathPersistent) {
      return EtfDailyReadinessCheck(
        label: 'data persistence',
        statusLabel: dataPersistenceLabel,
        detail: dataPersistenceCaption,
        level: EtfDailyReadinessLevel.attention,
        action:
            '公開部署時請設定 persistent volume 與 00631L_DATA_PERSISTENCE_MODE=persistent。',
      );
    }
    return const EtfDailyReadinessCheck(
      label: 'local state',
      statusLabel: 'ready',
      detail: 'required env keys 與 data/export/backup 目錄可用。',
      level: EtfDailyReadinessLevel.ready,
    );
  }

  List<String> get operationGuidanceLines {
    final lines = <String>[];
    if (backendDisconnected) {
      lines.add(
          'backend disconnected: run scripts\\00631l_start_backend.cmd, then open /#/00631l-lab. mock/fallback remains visible.');
    }
    if (dailyCycleStatus == 'missing' || dailyCycleFinishedAt == null) {
      lines.add('尚未跑 daily cycle：請執行 scripts\\00631l_daily_cycle.cmd。');
    }

    if (missingEnvKeys.any((key) => key.contains('.env'))) {
      lines.add('backend env 未設定：請參考 backend\\.env.example。');
    } else if (missingEnvKeys.isNotEmpty) {
      lines.add('backend env 有缺項：請檢查 ${missingEnvKeys.join(', ')}。');
    }

    final intradayUnavailable = intradayHistoryStatus == 'unavailable' ||
        intradayHistoryStatus == 'error' ||
        latestIntradayDataTime == null ||
        !twseIntradayNavConfigured;
    if (intradayUnavailable) {
      lines.add('intraday NAV 目前不可用：請檢查 TWSE URL 設定或交易時段。');
    }

    if (!exportAvailable) {
      lines.add('CSV export 不存在：可執行 scripts\\00631l_export_history.cmd。');
    }
    if (!backupAvailable) {
      lines.add('local backup 不存在：可執行 scripts\\00631l_backup_data.cmd。');
    }
    if (!reportAvailable) {
      lines.add(
          'daily report 不存在：可執行 scripts\\00631l_generate_daily_report.cmd。');
    }
    if (!dataDirectoriesReady) {
      lines.add(
          'data、exports 或 backups 目錄需要檢查：請執行 scripts\\00631l_check_env.cmd。');
    }
    if (dataPathWritable && !dataPathPersistent) {
      lines.add(
          '公開部署資料未標示 persistent：請掛載 persistent volume，並設定 00631L_DATA_PERSISTENCE_MODE=persistent。');
    }

    if (lines.isEmpty) {
      lines.add('目前沒有需要處理的本機操作項目。');
    }
    return lines;
  }
}

class EtfAiAnalysisSummary {
  const EtfAiAnalysisSummary({
    required this.source,
    required this.sourceStatusLabel,
    required this.generatedAt,
    required this.dataTime,
    required this.readinessLevel,
    required this.bullets,
    required this.actionItems,
    required this.sourceStatuses,
    required this.disclaimer,
    this.errorMessage,
  });

  factory EtfAiAnalysisSummary.mockFallback({DateTime? now}) {
    final resolvedNow = now ?? DateTime.now();
    return EtfAiAnalysisSummary(
      source: 'rule_based',
      sourceStatusLabel: 'mock',
      generatedAt: resolvedNow,
      dataTime: null,
      readinessLevel: 'action_needed',
      bullets: const [
        '目前使用 mock/fallback 資料，無法代表 official live source。',
        '請啟動 backend live proxy 後重新整理，以取得 official holdings 與 intraday NAV。',
        '此摘要只描述資料狀態與偏離程度。',
      ],
      actionItems: const [
        '請執行 scripts\\00631l_start_backend.cmd。',
        '請用 live proxy 模式開啟 /#/00631l-lab。',
      ],
      sourceStatuses: const {
        'analysis': 'mock',
        'operations': 'mock',
        'holdingsHistory': 'mock',
        'intradayNavHistory': 'mock',
      },
      disclaimer: '非買賣建議',
    );
  }

  final String source;
  final String sourceStatusLabel;
  final DateTime generatedAt;
  final DateTime? dataTime;
  final String readinessLevel;
  final List<String> bullets;
  final List<String> actionItems;
  final Map<String, String> sourceStatuses;
  final String disclaimer;
  final String? errorMessage;

  String get readinessLabel {
    switch (readinessLevel) {
      case 'ready':
        return '可日常使用';
      case 'attention':
        return '需要觀察';
      case 'action_needed':
        return '需要處理';
      default:
        return '資料不足';
    }
  }

  EtfAiAnalysisSummary asCached() {
    return EtfAiAnalysisSummary(
      source: source,
      sourceStatusLabel: 'cached',
      generatedAt: generatedAt,
      dataTime: dataTime,
      readinessLevel: readinessLevel,
      bullets: bullets,
      actionItems: actionItems,
      sourceStatuses: sourceStatuses,
      disclaimer: disclaimer,
      errorMessage: errorMessage,
    );
  }
}

class EtfPriceHistoryPoint {
  const EtfPriceHistoryPoint({
    required this.date,
    required this.close,
    this.open,
    this.high,
    this.low,
    this.volume,
    this.nav,
    this.premiumDiscountPct,
    this.dailyReturnPct,
    this.cumulativeReturnPct,
    this.drawdownPct,
  });

  final DateTime date;
  final double close;
  final double? open;
  final double? high;
  final double? low;
  final int? volume;
  final double? nav;
  final double? premiumDiscountPct;
  final double? dailyReturnPct;
  final double? cumulativeReturnPct;
  final double? drawdownPct;
}

class EtfPriceHistory {
  const EtfPriceHistory({
    required this.points,
    required this.status,
    required this.sourceStatusLabel,
    required this.sourceUrl,
    required this.lastFetchedAt,
    required this.coverageStart,
    required this.coverageEnd,
    required this.isCompleteFromListing,
    this.errorMessage,
  });

  factory EtfPriceHistory.empty({
    DateTime? lastFetchedAt,
    EtfDataStatus status = EtfDataStatus.mock,
    String sourceStatusLabel = 'mock',
    String sourceUrl = '',
    String? errorMessage,
  }) {
    final now = lastFetchedAt ?? DateTime.now();
    return EtfPriceHistory(
      points: const [],
      status: status,
      sourceStatusLabel: sourceStatusLabel,
      sourceUrl: sourceUrl,
      lastFetchedAt: now,
      coverageStart: null,
      coverageEnd: null,
      isCompleteFromListing: false,
      errorMessage: errorMessage,
    );
  }

  final List<EtfPriceHistoryPoint> points;
  final EtfDataStatus status;
  final String sourceStatusLabel;
  final String sourceUrl;
  final DateTime lastFetchedAt;
  final DateTime? coverageStart;
  final DateTime? coverageEnd;
  final bool isCompleteFromListing;
  final String? errorMessage;

  bool get hasData => points.isNotEmpty;

  EtfPerformanceSummary get performance =>
      EtfPerformanceSummary.fromPoints(points);
}

class EtfPerformanceSummary {
  const EtfPerformanceSummary({
    required this.totalReturnPct,
    required this.annualizedReturnPct,
    required this.annualizedVolatilityPct,
    required this.maxDrawdownPct,
    required this.bestDailyReturnPct,
    required this.worstDailyReturnPct,
  });

  factory EtfPerformanceSummary.empty() {
    return const EtfPerformanceSummary(
      totalReturnPct: null,
      annualizedReturnPct: null,
      annualizedVolatilityPct: null,
      maxDrawdownPct: null,
      bestDailyReturnPct: null,
      worstDailyReturnPct: null,
    );
  }

  factory EtfPerformanceSummary.fromPoints(List<EtfPriceHistoryPoint> points) {
    if (points.length < 2) {
      return EtfPerformanceSummary.empty();
    }
    final ordered = [...points]..sort((a, b) => a.date.compareTo(b.date));
    final first = ordered.first.close;
    final last = ordered.last.close;
    final totalReturn = first == 0 ? null : (last / first - 1) * 100;
    final days = ordered.last.date.difference(ordered.first.date).inDays;
    final annualizedReturn = totalReturn == null || days <= 0
        ? null
        : ((powDouble(last / first, 365 / days) - 1) * 100);
    final returns = <double>[];
    var peak = first;
    var maxDrawdown = 0.0;
    for (var index = 1; index < ordered.length; index += 1) {
      final previous = ordered[index - 1].close;
      final current = ordered[index].close;
      if (previous > 0) {
        returns.add((current / previous - 1) * 100);
      }
      if (current > peak) {
        peak = current;
      }
      if (peak > 0) {
        final drawdown = (current / peak - 1) * 100;
        if (drawdown < maxDrawdown) {
          maxDrawdown = drawdown;
        }
      }
    }
    final volatility = returns.length < 2
        ? null
        : _standardDeviation(returns) * powDouble(252, 0.5);
    returns.sort();
    return EtfPerformanceSummary(
      totalReturnPct: totalReturn,
      annualizedReturnPct: annualizedReturn,
      annualizedVolatilityPct: volatility,
      maxDrawdownPct: maxDrawdown,
      bestDailyReturnPct: returns.isEmpty ? null : returns.last,
      worstDailyReturnPct: returns.isEmpty ? null : returns.first,
    );
  }

  final double? totalReturnPct;
  final double? annualizedReturnPct;
  final double? annualizedVolatilityPct;
  final double? maxDrawdownPct;
  final double? bestDailyReturnPct;
  final double? worstDailyReturnPct;
}

enum EtfBacktestStrategy {
  lumpSum,
  monthlyContribution,
}

class EtfBacktestRequest {
  const EtfBacktestRequest({
    required this.strategy,
    required this.startDate,
    required this.endDate,
    required this.initialAmount,
    required this.monthlyAmount,
    required this.monthlyDay,
    required this.feeRatePct,
  });

  final EtfBacktestStrategy strategy;
  final DateTime startDate;
  final DateTime endDate;
  final double initialAmount;
  final double monthlyAmount;
  final int monthlyDay;
  final double feeRatePct;
}

class EtfBacktestResult {
  const EtfBacktestResult({
    required this.sourceStatusLabel,
    required this.totalInvested,
    required this.finalValue,
    required this.totalReturnPct,
    required this.annualizedReturnPct,
    required this.maxDrawdownPct,
    required this.volatilityPct,
    required this.bestPeriodReturnPct,
    required this.worstPeriodReturnPct,
    required this.equityCurve,
    required this.drawdownCurve,
    this.errorMessage,
  });

  factory EtfBacktestResult.unavailable(String message) {
    return EtfBacktestResult(
      sourceStatusLabel: 'unavailable',
      totalInvested: 0,
      finalValue: 0,
      totalReturnPct: null,
      annualizedReturnPct: null,
      maxDrawdownPct: null,
      volatilityPct: null,
      bestPeriodReturnPct: null,
      worstPeriodReturnPct: null,
      equityCurve: const [],
      drawdownCurve: const [],
      errorMessage: message,
    );
  }

  final String sourceStatusLabel;
  final double totalInvested;
  final double finalValue;
  final double? totalReturnPct;
  final double? annualizedReturnPct;
  final double? maxDrawdownPct;
  final double? volatilityPct;
  final double? bestPeriodReturnPct;
  final double? worstPeriodReturnPct;
  final List<EtfBacktestCurvePoint> equityCurve;
  final List<EtfBacktestCurvePoint> drawdownCurve;
  final String? errorMessage;
}

class EtfBacktestCurvePoint {
  const EtfBacktestCurvePoint({
    required this.date,
    required this.value,
  });

  final DateTime date;
  final double value;
}

class EtfBacktestEngine {
  const EtfBacktestEngine();

  EtfBacktestResult run({
    required EtfBacktestRequest request,
    required List<EtfPriceHistoryPoint> history,
  }) {
    final points = history
        .where((point) =>
            !point.date.isBefore(request.startDate) &&
            !point.date.isAfter(request.endDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (points.length < 2) {
      return EtfBacktestResult.unavailable('歷史資料不足，無法執行回測。');
    }

    var cashInvested = 0.0;
    var units = 0.0;
    var lastContributionMonth = '';
    final equity = <EtfBacktestCurvePoint>[];
    final drawdowns = <EtfBacktestCurvePoint>[];
    final periodReturns = <double>[];
    var peak = 0.0;

    for (var index = 0; index < points.length; index += 1) {
      final point = points[index];
      final shouldInitial = index == 0 && request.initialAmount > 0;
      final monthKey = '${point.date.year}-${point.date.month}';
      final shouldMonthly =
          request.strategy == EtfBacktestStrategy.monthlyContribution &&
              request.monthlyAmount > 0 &&
              point.date.day >= request.monthlyDay &&
              monthKey != lastContributionMonth;
      var contribution = 0.0;
      if (shouldInitial) {
        contribution += request.initialAmount;
      }
      if (shouldMonthly) {
        contribution += request.monthlyAmount;
        lastContributionMonth = monthKey;
      }
      if (contribution > 0 && point.close > 0) {
        final fee = contribution * request.feeRatePct / 100;
        units += (contribution - fee) / point.close;
        cashInvested += contribution;
      }
      final value = units * point.close;
      if (value > peak) {
        peak = value;
      }
      final drawdown = peak <= 0 ? 0.0 : (value / peak - 1) * 100;
      equity.add(EtfBacktestCurvePoint(date: point.date, value: value));
      drawdowns.add(EtfBacktestCurvePoint(date: point.date, value: drawdown));
      if (index > 0 && equity[index - 1].value > 0) {
        periodReturns.add((value / equity[index - 1].value - 1) * 100);
      }
    }

    final finalValue = equity.last.value;
    final totalReturn =
        cashInvested <= 0 ? null : (finalValue / cashInvested - 1) * 100;
    final days = points.last.date.difference(points.first.date).inDays;
    final annualized = totalReturn == null || days <= 0 || cashInvested == 0
        ? null
        : ((powDouble(finalValue / cashInvested, 365 / days) - 1) * 100);
    periodReturns.sort();
    return EtfBacktestResult(
      sourceStatusLabel: 'calculated',
      totalInvested: cashInvested,
      finalValue: finalValue,
      totalReturnPct: totalReturn,
      annualizedReturnPct: annualized,
      maxDrawdownPct: drawdowns.map((point) => point.value).reduce(
            (a, b) => a < b ? a : b,
          ),
      volatilityPct: periodReturns.length < 2
          ? null
          : _standardDeviation(periodReturns) * powDouble(252, 0.5),
      bestPeriodReturnPct: periodReturns.isEmpty ? null : periodReturns.last,
      worstPeriodReturnPct: periodReturns.isEmpty ? null : periodReturns.first,
      equityCurve: equity,
      drawdownCurve: drawdowns,
    );
  }
}

class EtfPositionInput {
  const EtfPositionInput({
    required this.shares,
    required this.averageCost,
    this.totalAssets,
    this.feeAndTax = 0,
    this.note = '',
  });

  factory EtfPositionInput.empty() {
    return const EtfPositionInput(shares: 0, averageCost: 0);
  }

  final double shares;
  final double averageCost;
  final double? totalAssets;
  final double feeAndTax;
  final String note;
}

class EtfPositionSummary {
  const EtfPositionSummary({
    required this.marketValue,
    required this.cost,
    required this.unrealizedPnl,
    required this.unrealizedPnlPct,
    required this.assetWeightPct,
    required this.dataTime,
  });

  factory EtfPositionSummary.evaluate({
    required EtfPositionInput input,
    required double? marketPrice,
    required DateTime? dataTime,
  }) {
    final price = marketPrice ?? 0;
    final marketValue = input.shares * price;
    final cost = input.shares * input.averageCost + input.feeAndTax;
    final pnl = marketValue - cost;
    return EtfPositionSummary(
      marketValue: marketValue,
      cost: cost,
      unrealizedPnl: pnl,
      unrealizedPnlPct: cost <= 0 ? null : pnl / cost * 100,
      assetWeightPct: (input.totalAssets ?? 0) <= 0
          ? null
          : marketValue / input.totalAssets! * 100,
      dataTime: dataTime,
    );
  }

  final double marketValue;
  final double cost;
  final double unrealizedPnl;
  final double? unrealizedPnlPct;
  final double? assetWeightPct;
  final DateTime? dataTime;
}

class Etf00631LLabData {
  const Etf00631LLabData({
    required this.profile,
    required this.snapshot,
    required this.intradayNav,
    required this.futuresQuote,
    required this.holdingsHistory,
    required this.intradayNavHistory,
    required this.priceHistory,
    required this.operationsStatus,
    required this.analysis,
    required this.aiAnalysis,
    required this.lastFetchedAt,
  });

  final LeveragedEtfProfile profile;
  final EtfDailyHoldingSnapshot snapshot;
  final EtfIntradayNav? intradayNav;
  final FuturesQuote futuresQuote;
  final EtfHoldingsHistory holdingsHistory;
  final EtfIntradayNavHistorySummary intradayNavHistory;
  final EtfPriceHistory priceHistory;
  final EtfOperationsStatus operationsStatus;
  final EtfAnalysisSummary analysis;
  final EtfAiAnalysisSummary aiAnalysis;
  final DateTime lastFetchedAt;

  HoldingsChangeAssessment get holdingsChangeAssessment {
    return HoldingsChangeAssessment.evaluate(
      history: holdingsHistory,
      snapshot: snapshot,
      now: lastFetchedAt,
    );
  }

  EtfStatusSummary get statusSummary {
    return EtfStatusSummary.evaluate(
      profile: profile,
      snapshot: snapshot,
      intradayNav: intradayNav,
      holdingsHistory: holdingsHistory,
      intradayNavHistory: intradayNavHistory,
      holdingsChangeAssessment: holdingsChangeAssessment,
      now: lastFetchedAt,
    );
  }

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

double powDouble(double base, double exponent) {
  if (base <= 0) {
    return 0;
  }
  return math.pow(base, exponent).toDouble();
}

double _standardDeviation(List<double> values) {
  if (values.length < 2) {
    return 0;
  }
  final mean = values.reduce((a, b) => a + b) / values.length;
  final variance = values
          .map((value) => (value - mean) * (value - mean))
          .reduce((a, b) => a + b) /
      (values.length - 1);
  return powDouble(variance, 0.5);
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

String _signedPercentText(double value) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(2)}%';
}

String _signedDeltaPercentText(double value) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(2)} 個百分點';
}

String _holdingNoticeStatusLabel(List<HoldingChangeNotice> notices) {
  if (notices.any((notice) => notice.level == HoldingChangeNoticeLevel.stale)) {
    return 'stale';
  }
  if (notices
      .any((notice) => notice.level == HoldingChangeNoticeLevel.elevated)) {
    return 'elevated';
  }
  if (notices.any((notice) => notice.level == HoldingChangeNoticeLevel.watch)) {
    return 'watch';
  }
  if (notices
      .any((notice) => notice.level == HoldingChangeNoticeLevel.unavailable)) {
    return 'unavailable';
  }
  return 'normal';
}

EtfStatusSummaryLevel _statusSummaryLevel({
  required LeveragedEtfProfile profile,
  required EtfDailyHoldingSnapshot snapshot,
  required EtfIntradayNav? intradayNav,
  required PremiumDiscountAssessment premiumAssessment,
  required HoldingsChangeAssessment holdingsChangeAssessment,
  required DateTime now,
}) {
  if (profile.status == EtfDataStatus.error ||
      snapshot.status == EtfDataStatus.error) {
    return EtfStatusSummaryLevel.error;
  }
  if (snapshot.isStale(now) ||
      intradayNav?.isStale == true ||
      holdingsChangeAssessment.statusLabel == 'stale') {
    return EtfStatusSummaryLevel.stale;
  }
  if (intradayNav == null ||
      premiumAssessment.level == PremiumDiscountLevel.unavailable) {
    return EtfStatusSummaryLevel.unavailable;
  }
  if (premiumAssessment.level == PremiumDiscountLevel.extreme ||
      premiumAssessment.level == PremiumDiscountLevel.elevated ||
      holdingsChangeAssessment.statusLabel == 'elevated') {
    return EtfStatusSummaryLevel.elevated;
  }
  if (premiumAssessment.level == PremiumDiscountLevel.watch ||
      holdingsChangeAssessment.statusLabel == 'watch' ||
      holdingsChangeAssessment.statusLabel == 'unavailable') {
    return EtfStatusSummaryLevel.watch;
  }
  return EtfStatusSummaryLevel.normal;
}

String _statusSummaryLabel(EtfStatusSummaryLevel level) {
  switch (level) {
    case EtfStatusSummaryLevel.normal:
      return '資料狀態正常';
    case EtfStatusSummaryLevel.watch:
      return '資料狀態觀察';
    case EtfStatusSummaryLevel.elevated:
      return '偏離程度較高';
    case EtfStatusSummaryLevel.unavailable:
      return '資料不足';
    case EtfStatusSummaryLevel.stale:
      return '資料可能過期';
    case EtfStatusSummaryLevel.error:
      return '資料錯誤';
  }
}

String _dateText(DateTime date) {
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

String _nullableSignedPercentText(double? value) {
  if (value == null) {
    return 'unavailable';
  }
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(2)}%';
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
