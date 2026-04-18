package us.rasor.mc.economy.bank;

import com.mojang.serialization.Codec;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.math.MathContext;
import java.math.RoundingMode;
import java.text.DecimalFormat;
import net.fabricmc.fabric.api.attachment.v1.AttachmentRegistry;
import net.fabricmc.fabric.api.attachment.v1.AttachmentType;
import net.fabricmc.fabric.api.entity.event.v1.ServerPlayerEvents;
import net.fabricmc.fabric.api.transfer.v1.transaction.TransactionContext;
import net.fabricmc.fabric.api.transfer.v1.transaction.base.SnapshotParticipant;
import net.minecraft.resources.Identifier;
import net.minecraft.server.level.ServerPlayer;

public class BalanceAttachment extends SnapshotParticipant<BigDecimal> {

  private static final Codec<BigDecimal> BIG_DECIMAL_CODEC = Codec.STRING.xmap(BigDecimal::new,
      BigDecimal::toString);
  private static final DecimalFormat FORMATTER = new DecimalFormat("#,##0.000◆");
  private static final int SCALE = 3;
  private static final MathContext MATH_CONTEXT = new MathContext(0, RoundingMode.UNNECESSARY);

  private static AttachmentType<BigDecimal> BALANCE;

  private final ServerPlayer player;
  private BigDecimal value;

  public BalanceAttachment(ServerPlayer player) {
    this.player = player;
    this.value = player.getAttached(BALANCE);
  }

  public static void init() {
    BALANCE = AttachmentRegistry.create(Identifier.fromNamespaceAndPath("rasor-economy", "balance"),
        builder -> builder.initializer(() -> new BigDecimal(BigInteger.ZERO, SCALE, MATH_CONTEXT))
            .persistent(BIG_DECIMAL_CODEC).copyOnDeath());

    ServerPlayerEvents.JOIN.register(player -> player.getAttachedOrCreate(BALANCE));
  }

  public static String format(BigDecimal amount) {
    return FORMATTER.format(amount);
  }

  public BigDecimal get() {
    return value;
  }

  public String getString() {
    return format(value);
  }

  public boolean isLessThanZero() {
    return value.compareTo(BigDecimal.ZERO) < 0;
  }

  public void add(BigDecimal amount, TransactionContext transaction) {
    updateSnapshots(transaction);
    value = value.add(amount, MATH_CONTEXT);
  }

  public void add(long amount, TransactionContext transaction) {
    add(BigDecimal.valueOf(amount), transaction);
  }

  public void subtract(BigDecimal amount, TransactionContext transaction) {
    updateSnapshots(transaction);
    value = value.subtract(amount, MATH_CONTEXT);
  }

  public void subtract(long amount, TransactionContext transaction) {
    subtract(BigDecimal.valueOf(amount), transaction);
  }

  @Override
  protected BigDecimal createSnapshot() {
    return value;
  }

  @Override
  protected void readSnapshot(BigDecimal snapshot) {
    this.value = snapshot;
  }

  @Override
  protected void onFinalCommit() {
    player.setAttached(BALANCE, value);
  }
}
