package us.rasor.mc.economy.insurance;

import java.time.Instant;
import java.time.temporal.TemporalAmount;
import java.util.Optional;
import net.fabricmc.fabric.api.attachment.v1.AttachmentRegistry;
import net.fabricmc.fabric.api.attachment.v1.AttachmentType;
import net.fabricmc.fabric.api.transfer.v1.transaction.TransactionContext;
import net.fabricmc.fabric.api.transfer.v1.transaction.base.SnapshotParticipant;
import net.minecraft.resources.Identifier;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.util.ExtraCodecs;

public class InsuranceAttachment extends SnapshotParticipant<Optional<Instant>> {

  private static AttachmentType<Instant> INSURANCE_ENDS_AT;

  private final ServerPlayer player;
  private Instant value;

  public InsuranceAttachment(ServerPlayer player) {
    this.player = player;
    this.value = player.getAttached(INSURANCE_ENDS_AT);
  }

  public static void init() {
    INSURANCE_ENDS_AT = AttachmentRegistry.create(
        Identifier.fromNamespaceAndPath("rasor-economy", "insurance-ends-at"),
        builder -> builder
            .persistent(ExtraCodecs.INSTANT_ISO8601)
            .copyOnDeath()
    );
  }

  public Instant get() {
    return value;
  }

  public boolean isPolicyActive() {
    return value != null && value.isAfter(Instant.now());
  }

  public void incrementPolicyDuration(TemporalAmount duration, TransactionContext transaction) {
    Instant now = Instant.now();
    Instant instantToAddTo;
    if (value != null && value.isAfter(now)) {
      instantToAddTo = value;
    } else {
      instantToAddTo = now;
    }

    updateSnapshots(transaction);
    value = instantToAddTo.plus(duration);
  }

  @Override
  protected Optional<Instant> createSnapshot() {
    return Optional.ofNullable(value);
  }

  @Override
  protected void readSnapshot(Optional<Instant> snapshot) {
    this.value = snapshot.orElse(null);
  }

  @Override
  protected void onFinalCommit() {
    player.setAttached(INSURANCE_ENDS_AT, value);
  }
}
