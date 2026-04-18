package us.rasor.mc.economy.bank;

public final class Bank {

  private Bank() {
    throw new AssertionError();
  }

  public static void init() {
    BalanceAttachment.init();
    BankCommand.init();
  }
}
