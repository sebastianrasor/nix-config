package us.rasor.mc.difficulty.amplifier;

import net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents;
import net.minecraft.server.MinecraftServer;

public class GameRules {
    public static void init() {
        ServerLifecycleEvents.SERVER_STARTED.register(GameRules::setGameRules);
    }

    private static void setGameRules(MinecraftServer server) {
        server.getGameRules().set(net.minecraft.world.level.gamerules.GameRules.NATURAL_HEALTH_REGENERATION, false, server);
        server.getGameRules().set(net.minecraft.world.level.gamerules.GameRules.PLAYERS_SLEEPING_PERCENTAGE, 101, server);

        // If I'm going to disable sleeping through the night, keeping phantoms enabled is just wrong.
        server.getGameRules().set(net.minecraft.world.level.gamerules.GameRules.SPAWN_PHANTOMS, false, server);
    }
}
