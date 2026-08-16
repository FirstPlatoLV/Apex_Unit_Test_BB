/** Replaceable clock used to make date-dependent mapping deterministic in tests. */
public interface IDateProvider {
  Date today();
}
