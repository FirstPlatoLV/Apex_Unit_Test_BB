@IsTest
public class BrownbagTestDataFactory {
    public class Graph {
        public Account account;
        public Opportunity opportunity;
        public Quote quoteRecord;
        public List<PricebookEntry> entries;
    }

    public static Graph createAcceptedQuote(Integer lineCount) {
        Graph graph = new Graph();
        graph.account = new Account(Name = 'Repository Test Account');
        insert graph.account;
        graph.opportunity = new Opportunity(
            Name = 'Repository Test Opportunity', AccountId = graph.account.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert graph.opportunity;

        List<Product2> products = new List<Product2>();
        for (Integer index = 0; index < lineCount; index++) {
            products.add(new Product2(Name = 'Repository Product ' + index, IsActive = true));
        }
        insert products;
        graph.entries = new List<PricebookEntry>();
        for (Integer index = 0; index < products.size(); index++) {
            graph.entries.add(new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(), Product2Id = products[index].Id,
                UnitPrice = 10 + index, IsActive = true
            ));
        }
        insert graph.entries;
        graph.quoteRecord = new Quote(
            Name = 'Repository Test Quote', OpportunityId = graph.opportunity.Id,
            Pricebook2Id = Test.getStandardPricebookId(), Status = 'Accepted'
        );
        insert graph.quoteRecord;
        List<QuoteLineItem> lines = new List<QuoteLineItem>();
        for (Integer index = 0; index < graph.entries.size(); index++) {
            lines.add(new QuoteLineItem(
                QuoteId = graph.quoteRecord.Id, PricebookEntryId = graph.entries[index].Id,
                Quantity = index + 1, UnitPrice = 9 + index
            ));
        }
        insert lines;
        return graph;
    }
}
