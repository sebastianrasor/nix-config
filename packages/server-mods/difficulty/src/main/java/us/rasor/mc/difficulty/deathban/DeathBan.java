package us.rasor.mc.difficulty.deathban;

public final class DeathBan {

    private DeathBan() {
        throw new AssertionError();
    }

    public static void init() {
        BanPlayerAfterDeathEvent.init();
        GameRules.init();
    }
}
