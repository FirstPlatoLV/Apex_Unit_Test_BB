/**
 * Dependency-injected Quote-to-Order business service.
 *
 * Its conversion rules intentionally mirror LegacyQuoteToOrderService. The
 * difference is architectural: persistence, time, and policy access arrive
 * through interfaces. Unit tests can therefore exercise every branch with
 * in-memory records and mocks instead of constructing a Salesforce data graph.
 */
public inherited sharing class QuoteToOrderService implements IQuoteToOrderService {

  private final IQuoteToOrderDAO dao;
  private final IDateProvider dateProvider;
  private final IQuoteConversionPolicy policy;

  public QuoteToOrderService(
    IQuoteToOrderDAO dao,
    IDateProvider dateProvider,
    IQuoteConversionPolicy policy
  ) {

    // Constructor injection makes every external dependency explicit and
    // prevents production implementations from being created inside the logic.
    this.dao = dao;
    this.dateProvider = dateProvider;
    this.policy = policy;
  }

  public Map<Id, QuoteToOrderResult> convertQuotes(Set<Id> quoteIds) {

    if (quoteIds == null || quoteIds.isEmpty()) {

      return new Map<Id, QuoteToOrderResult>();
    }
    Map<Id, Quote> quotesById = dao.findQuotes(quoteIds);
    if (quotesById.size() != quoteIds.size()) {

      throw new QuoteToOrderException('Quote does not exist');
    }
    // The policy is replaceable, so tests do not depend on deployable Custom
    // Metadata records or on the org's current configuration.
    Quote_Conversion_Policy__mdt conversionPolicy = policy.getPolicy();
    String acceptedQuoteStatus = conversionPolicy?.Accepted_Quote_Status__c;
    Set<Id> eligibleQuoteIds = selectEligibleQuoteIds(
      quotesById,
      acceptedQuoteStatus
    );
    if (eligibleQuoteIds.isEmpty()) {

      return new Map<Id, QuoteToOrderResult>();
    }
    Map<Id, List<QuoteLineItem>> linesByQuoteId = groupQuoteLines(
      dao.findQuoteLines(eligibleQuoteIds)
    );
    // A replaceable clock makes the mapped EffectiveDate deterministic.
    Date effectiveDate = dateProvider.today();
    Map<Id, Order> ordersByQuoteId = buildOrders(
      eligibleQuoteIds,
      quotesById,
      linesByQuoteId,
      effectiveDate
    );
    Map<Id, List<OrderItem>> itemsByQuoteId = buildOrderItems(
      eligibleQuoteIds,
      linesByQuoteId
    );
    // The service prepares the desired records; the DAO coordinates persistence.
    Map<Id, Id> orderIdsByQuoteId = dao.saveOrders(
      ordersByQuoteId,
      itemsByQuoteId
    );
    dao.markQuotesConverted(orderIdsByQuoteId);
    return buildResults(eligibleQuoteIds, orderIdsByQuoteId, itemsByQuoteId);
  }

  @TestVisible
  private Set<Id> selectEligibleQuoteIds(
    Map<Id, Quote> quotesById,
    String acceptedQuoteStatus
  ) {

    Set<Id> eligibleQuoteIds = new Set<Id>();
    for (Id quoteId : quotesById.keySet()) {

      if (quotesById.get(quoteId).Status == acceptedQuoteStatus) {

        eligibleQuoteIds.add(quoteId);
      }
    }
    return eligibleQuoteIds;
  }

  @TestVisible
  private Map<Id, List<QuoteLineItem>> groupQuoteLines(
    List<QuoteLineItem> quoteLines
  ) {

    Map<Id, List<QuoteLineItem>> linesByQuoteId = new Map<Id, List<QuoteLineItem>>();
    for (QuoteLineItem line : quoteLines) {

      if (!linesByQuoteId.containsKey(line.QuoteId)) {

        linesByQuoteId.put(line.QuoteId, new List<QuoteLineItem>());
      }
      linesByQuoteId.get(line.QuoteId).add(line);
    }
    return linesByQuoteId;
  }

  @TestVisible
  private Map<Id, Order> buildOrders(
    Set<Id> quoteIds,
    Map<Id, Quote> quotesById,
    Map<Id, List<QuoteLineItem>> linesByQuoteId,
    Date effectiveDate
  ) {

    Map<Id, Order> ordersByQuoteId = new Map<Id, Order>();
    for (Id quoteId : quoteIds) {

      Quote quoteRecord = quotesById.get(quoteId);
      validate(quoteRecord, linesByQuoteId.get(quoteId));
      ordersByQuoteId.put(
        quoteId,
        new Order(
          AccountId = quoteRecord.AccountId,
          EffectiveDate = effectiveDate,
          Pricebook2Id = quoteRecord.Pricebook2Id,
          Status = 'Draft'
        )
      );
    }
    return ordersByQuoteId;
  }

  @TestVisible
  private Map<Id, List<OrderItem>> buildOrderItems(
    Set<Id> quoteIds,
    Map<Id, List<QuoteLineItem>> linesByQuoteId
  ) {

    Map<Id, List<OrderItem>> itemsByQuoteId = new Map<Id, List<OrderItem>>();
    for (Id quoteId : quoteIds) {

      List<OrderItem> items = new List<OrderItem>();
      for (QuoteLineItem line : linesByQuoteId.get(quoteId)) {

        items.add(
          new OrderItem(
            PricebookEntryId = line.PricebookEntryId,
            Quantity = line.Quantity,
            UnitPrice = line.UnitPrice
          )
        );
      }
      itemsByQuoteId.put(quoteId, items);
    }
    return itemsByQuoteId;
  }

  @TestVisible
  private Map<Id, QuoteToOrderResult> buildResults(
    Set<Id> quoteIds,
    Map<Id, Id> orderIdsByQuoteId,
    Map<Id, List<OrderItem>> itemsByQuoteId
  ) {

    Map<Id, QuoteToOrderResult> results = new Map<Id, QuoteToOrderResult>();
    for (Id quoteId : quoteIds) {

      results.put(
        quoteId,
        new QuoteToOrderResult(
          orderIdsByQuoteId.get(quoteId),
          itemsByQuoteId.get(quoteId).size()
        )
      );
    }
    return results;
  }

  @TestVisible
  private void validate(Quote quoteRecord, List<QuoteLineItem> lines) {

    if (quoteRecord.Converted_Order__c != null) {

      throw new QuoteToOrderException('Quote was already converted');
    }
    if (quoteRecord.AccountId == null) {

      throw new QuoteToOrderException('Quote Account is required');
    }
    if (quoteRecord.Pricebook2Id == null) {

      throw new QuoteToOrderException('Quote Price Book is required');
    }
    if (lines == null || lines.isEmpty()) {

      throw new QuoteToOrderException('Quote must contain at least one line');
    }
  }
}
