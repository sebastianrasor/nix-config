package us.rasor.mc.difficulty.deathban;

import net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents;
import net.minecraft.server.MinecraftServer;

public class GameRules {
    public static void init() {
        ServerLifecycleEvents.SERVER_STARTED.register(GameRules::setGameRules);
    }

    private static void setGameRules(MinecraftServer server) {
        // Required for the ban on death and respawn on join after unban to work properly.
        server.getGameRules().set(net.minecraft.world.level.gamerules.GameRules.IMMEDIATE_RESPAWN, true, server);
    }
}
