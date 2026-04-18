package us.rasor.mc.difficulty.deathban;

import java.text.SimpleDateFormat;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.Locale;
import net.fabricmc.fabric.api.entity.event.v1.ServerLivingEntityEvents;
import net.minecraft.network.chat.Component;
import net.minecraft.network.chat.MutableComponent;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.server.players.UserBanListEntry;
import net.minecraft.world.damagesource.DamageSource;
import net.minecraft.world.entity.LivingEntity;

public class BanPlayerAfterDeathEvent {

  private static final SimpleDateFormat BAN_DATE_FORMAT = new SimpleDateFormat(
      "yyyy-MM-dd 'at' HH:mm:ss z", Locale.ROOT);

  public static void init() {
    ServerLivingEntityEvents.AFTER_DEATH.register(BanPlayerAfterDeathEvent::banPlayer);
  }

  private static void banPlayer(LivingEntity entity, DamageSource damageSource) {
    if (!(entity instanceof ServerPlayer player)) {
      return;
    }

    UserBanListEntry ban = new UserBanListEntry(
        player.nameAndId(),
        null,
        "Server (Caused by player death)",
        Date.from(Instant.now().plus(24, ChronoUnit.HOURS)),
        damageSource.getLocalizedDeathMessage(entity).getString()
    );
    player.level().getServer().getPlayerList().getBans().add(ban);
    MutableComponent reason = Component.translatable("multiplayer.disconnect.banned.reason",
        ban.getReasonMessage());
    reason.append(Component.translatable("multiplayer.disconnect.banned.expiration",
        BAN_DATE_FORMAT.format(ban.getExpires())));

    player.connection.disconnect(reason);
  }
}
