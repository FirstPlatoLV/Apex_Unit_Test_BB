/**
 * Replaceable source for the complete Quote conversion policy record.
 * Returning the record allows one lookup to supply both the accepted status and
 * implementation flag as more policy fields are introduced.
 */
public interface IQuoteConversionPolicy {
  Quote_Conversion_Policy__mdt getPolicy();
}
