package us.rasor.mc.economy.insurance;

import com.mojang.serialization.Codec;
import net.fabricmc.fabric.api.attachment.v1.AttachmentRegistry;
import net.fabricmc.fabric.api.attachment.v1.AttachmentType;
import net.fabricmc.fabric.api.entity.event.v1.ServerLivingEntityEvents;
import net.fabricmc.fabric.api.entity.event.v1.ServerPlayerEvents;
import net.minecraft.resources.Identifier;
import net.minecraft.server.level.ServerPlayer;

public class KeepInventoryAttachment {

  private static AttachmentType<Boolean> KEEP_INVENTORY;

  private final ServerPlayer player;
  private Boolean value;

  public KeepInventoryAttachment(ServerPlayer player) {
    this.player = player;
    this.value = player.getAttached(KEEP_INVENTORY);
  }

  public static void init() {
    KEEP_INVENTORY = AttachmentRegistry.create(
        Identifier.fromNamespaceAndPath("rasor-economy", "keep-inventory"),
        builder -> builder
            .persistent(Codec.BOOL)
            .copyOnDeath()
    );

    ServerLivingEntityEvents.ALLOW_DEATH.register((entity, _, _) -> {
      if (!(entity instanceof ServerPlayer player)) {
        return true;
      }

      InsuranceAttachment insurance = new InsuranceAttachment(player);
      KeepInventoryAttachment keepInventory = new KeepInventoryAttachment(player);

      keepInventory.setKeepInventory(insurance.isPolicyActive());
      player.setAttached(KEEP_INVENTORY, insurance.isPolicyActive());
      return true;
    });

    ServerPlayerEvents.AFTER_RESPAWN.register(
        (_, player, _) -> new KeepInventoryAttachment(player).setKeepInventory(null));
  }

  public Boolean shouldKeepInventory() {
    return this.value != null && this.value;
  }

  private void setKeepInventory(Boolean shouldKeepInventory) {
    this.value = shouldKeepInventory;
    player.setAttached(KEEP_INVENTORY, this.value);
  }
}
