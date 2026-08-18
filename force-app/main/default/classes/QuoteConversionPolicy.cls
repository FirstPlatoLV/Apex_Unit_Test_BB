/**
 * Instance adapter around the legacy static policy lookup.
 *
 * This small wrapper demonstrates a useful migration technique: place an
 * interface in front of static code, inject the interface into new consumers,
 * and mock it in unit tests without rewriting the existing implementation.
 */
public inherited sharing class QuoteConversionPolicy implements IQuoteConversionPolicy {
  public Quote_Conversion_Policy__mdt getPolicy() {

    return LegacyQuoteConversionPolicy.getPolicy();
  }
}
