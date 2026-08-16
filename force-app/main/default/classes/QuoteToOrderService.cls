public inherited sharing class QuoteToOrderService {
    private final IQuoteRepository quoteRepository;
    private final IQuoteLineRepository quoteLineRepository;
    private final IOrderRepository orderRepository;
    private final IDateProvider dateProvider;
    private final String acceptedQuoteStatus;

    public QuoteToOrderService(
        IQuoteRepository quoteRepository,
        IQuoteLineRepository quoteLineRepository,
        IOrderRepository orderRepository,
        IDateProvider dateProvider,
        String acceptedQuoteStatus
    ) {
        this.quoteRepository = quoteRepository;
        this.quoteLineRepository = quoteLineRepository;
        this.orderRepository = orderRepository;
        this.dateProvider = dateProvider;
        this.acceptedQuoteStatus = acceptedQuoteStatus;
    }

    public QuoteToOrderResult convert(Id quoteId) {
        Quote quoteRecord = quoteRepository.findById(quoteId);
        if (quoteRecord == null) {
            throw new QuoteToOrderException('Quote does not exist');
        }
        if (quoteRecord.Status != acceptedQuoteStatus) {
            throw new QuoteToOrderException('Quote status is not accepted');
        }
        if (quoteRecord.Converted_Order__c != null) {
            throw new QuoteToOrderException('Quote was already converted');
        }
        if (quoteRecord.AccountId == null) {
            throw new QuoteToOrderException('Quote Account is required');
        }
        if (quoteRecord.Pricebook2Id == null) {
            throw new QuoteToOrderException('Quote Price Book is required');
        }

        List<QuoteLineItem> quoteLines = quoteLineRepository.findByQuoteId(quoteId);
        if (quoteLines == null || quoteLines.isEmpty()) {
            throw new QuoteToOrderException('Quote must contain at least one line');
        }

        Order orderRecord = new Order(
            AccountId = quoteRecord.AccountId,
            EffectiveDate = dateProvider.today(),
            Pricebook2Id = quoteRecord.Pricebook2Id,
            Status = 'Draft'
        );
        List<OrderItem> orderItems = new List<OrderItem>();
        for (QuoteLineItem quoteLine : quoteLines) {
            orderItems.add(new OrderItem(
                PricebookEntryId = quoteLine.PricebookEntryId,
                Quantity = quoteLine.Quantity,
                UnitPrice = quoteLine.UnitPrice
            ));
        }

        Id orderId = orderRepository.save(orderRecord, orderItems);
        quoteRepository.markConverted(quoteId, orderId);
        return new QuoteToOrderResult(orderId, orderItems.size());
    }
}
