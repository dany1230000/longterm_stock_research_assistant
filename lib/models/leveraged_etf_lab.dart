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

class Etf00631LLabData {
  const Etf00631LLabData({
    required this.profile,
    required this.snapshot,
    required this.intradayNav,
    required this.futuresQuote,
    required this.holdingsHistory,
    required this.intradayNavHistory,
    required this.analysis,
    required this.lastFetchedAt,
  });

  final LeveragedEtfProfile profile;
  final EtfDailyHoldingSnapshot snapshot;
  final EtfIntradayNav? intradayNav;
  final FuturesQuote futuresQuote;
  final EtfHoldingsHistory holdingsHistory;
  final EtfIntradayNavHistorySummary intradayNavHistory;
  final EtfAnalysisSummary analysis;
  final DateTime lastFetchedAt;

  HoldingsChangeAssessment get holdingsChangeAssessment {
    return HoldingsChangeAssessment.evaluate(
      history: holdingsHistory,
      snapshot: snapshot,
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
