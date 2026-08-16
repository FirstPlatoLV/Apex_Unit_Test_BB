/** Production clock implementation; unit tests inject a fixed mock instead. */
public inherited sharing class SystemDateProvider implements IDateProvider {
  public Date today() {
    return Date.today();
  }
}
