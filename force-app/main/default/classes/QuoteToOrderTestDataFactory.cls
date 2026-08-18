@IsTest
/**
 * Builds the real Salesforce graph required by integration and E2E tests.
 * Mock-based service tests intentionally avoid this factory; that contrast is
 * the source of the test-runtime lesson demonstrated by the repository.
 */
public class QuoteToOrderTestDataFactory {

  public class Graph {

    public Account account;
    public Opportunity opportunity;
    public Quote quoteRecord;
    public List<PricebookEntry> entries;
  }

  public static Graph createAcceptedQuote(Integer lineCount) {

    return createQuote('Repository Test Quote', lineCount, 'Accepted');
  }

  public static Graph createQuote(
    String quoteName,
    Integer lineCount,
    String status
  ) {

    Graph graph = new Graph();
    graph.account = new Account(Name = quoteName + ' Account');
    insert graph.account;
    graph.opportunity = new Opportunity(
      Name = quoteName + ' Opportunity',
      AccountId = graph.account.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      Pricebook2Id = Test.getStandardPricebookId()
    );
    insert graph.opportunity;

    List<Product2> products = new List<Product2>();
    for (Integer index = 0; index < lineCount; index++) {

      products.add(
        new Product2(Name = quoteName + ' Product ' + index, IsActive = true)
      );
    }
    insert products;
    graph.entries = new List<PricebookEntry>();
    for (Integer index = 0; index < products.size(); index++) {

      graph.entries.add(
        new PricebookEntry(
          Pricebook2Id = Test.getStandardPricebookId(),
          Product2Id = products[index].Id,
          UnitPrice = 10 + index,
          IsActive = true
        )
      );
    }
    insert graph.entries;
    graph.quoteRecord = new Quote(
      Name = quoteName,
      OpportunityId = graph.opportunity.Id,
      Pricebook2Id = Test.getStandardPricebookId(),
      Status = status
    );
    insert graph.quoteRecord;
    List<QuoteLineItem> lines = new List<QuoteLineItem>();
    for (Integer index = 0; index < graph.entries.size(); index++) {

      lines.add(
        new QuoteLineItem(
          QuoteId = graph.quoteRecord.Id,
          PricebookEntryId = graph.entries[index].Id,
          Quantity = index + 1,
          UnitPrice = 9 + index
        )
      );
    }
    insert lines;
    return graph;
  }
}
