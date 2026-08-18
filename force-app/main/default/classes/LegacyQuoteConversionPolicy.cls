/**
 * Original static Custom Metadata access point.
 * Existing code can continue calling this class during an incremental migration.
 */
public inherited sharing class LegacyQuoteConversionPolicy {

  public static Quote_Conversion_Policy__mdt getPolicy() {

    return Quote_Conversion_Policy__mdt.getInstance('Default');
  }
}
