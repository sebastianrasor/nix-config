package us.rasor.mc.difficulty.amplifier;

public final class Amplifier {

    private Amplifier() {
        throw new AssertionError();
    }

    public static void init() {
        GameRules.init();
    }
}
