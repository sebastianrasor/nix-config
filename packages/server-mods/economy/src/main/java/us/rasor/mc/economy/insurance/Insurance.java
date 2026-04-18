package us.rasor.mc.economy.insurance;

public final class Insurance {

  private Insurance() {
    throw new AssertionError();
  }

  public static void init() {
    InsuranceAttachment.init();
    InsuranceCommand.init();
    KeepInventoryAttachment.init();
  }
}
