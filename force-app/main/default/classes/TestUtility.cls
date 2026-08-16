@IsTest
/**
 * Generates syntactically valid IDs for mock-only tests.
 * Using the object's real key prefix makes relationships readable without DML
 * or brittle hardcoded IDs.
 */
public class TestUtility {
  private static Integer s_num = 1;

  public static String getFakeId(Schema.SObjectType sObjectType) {
    String sequence = String.valueOf(s_num++);
    return sObjectType.getDescribe().getKeyPrefix() +
      '0'.repeat(12 - sequence.length()) +
      sequence;
  }
}
