package us.rasor.mc.economy.teleportation;

import java.util.Optional;
import net.fabricmc.fabric.api.attachment.v1.AttachmentRegistry;
import net.fabricmc.fabric.api.attachment.v1.AttachmentType;
import net.fabricmc.fabric.api.transfer.v1.transaction.TransactionContext;
import net.fabricmc.fabric.api.transfer.v1.transaction.base.SnapshotParticipant;
import net.minecraft.resources.Identifier;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.level.storage.LevelData.RespawnData;

public class HomeAttachment extends SnapshotParticipant<Optional<RespawnData>> {

  private static AttachmentType<RespawnData> HOME;

  private final ServerPlayer player;
  private RespawnData value;

  public HomeAttachment(ServerPlayer player) {
    this.player = player;
    this.value = player.getAttached(HOME);
  }

  public static void init() {
    HOME = AttachmentRegistry.create(
        Identifier.fromNamespaceAndPath("rasor-economy", "home"),
        builder -> builder
            .persistent(RespawnData.CODEC)
            .copyOnDeath()
    );
  }

  public RespawnData get() {
    return value;
  }

  public void set(RespawnData home, TransactionContext transaction) {
    updateSnapshots(transaction);
    value = home;
  }

  @Override
  protected Optional<RespawnData> createSnapshot() {
    return Optional.ofNullable(value);
  }

  @Override
  protected void readSnapshot(Optional<RespawnData> snapshot) {
    value = snapshot.orElse(null);
  }

  @Override
  protected void onFinalCommit() {
    player.setAttached(HOME, value);
  }
}
