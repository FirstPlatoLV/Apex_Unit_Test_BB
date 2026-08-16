/**
 * Production implementation of IDateProvider.
 *
 * Production code receives the real platform date through this small adapter,
 * while unit tests replace the interface with a mock returning a chosen date.
 * This keeps the business service deterministic without changing how production
 * time is calculated.
 */
public inherited sharing class SystemDateProvider implements IDateProvider {
  public Date today() {
    return Date.today();
  }
}
