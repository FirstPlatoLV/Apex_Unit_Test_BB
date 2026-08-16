/**
 * Abstraction over the system clock.
 *
 * Although Date.today() looks like an ordinary static utility call, its result
 * is an external input that changes every day. Exposing that input through an
 * interface lets unit tests supply a fixed date and assert exact, deterministic
 * output without depending on when the test happens to run.
 *
 * The current service uses it to map Order.EffectiveDate. The seam becomes even
 * more valuable when rules involve expiration dates, grace periods, renewals,
 * month-end behavior, leap years, or other date boundaries that would otherwise
 * be difficult or impossible to reproduce reliably in a test.
 */
public interface IDateProvider {
  Date today();
}
