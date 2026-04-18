package us.rasor.mc.economy.insurance;

import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.arguments.IntegerArgumentType;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.exceptions.CommandSyntaxException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;
import net.fabricmc.fabric.api.transfer.v1.transaction.Transaction;
import net.minecraft.commands.CommandBuildContext;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.commands.Commands.CommandSelection;
import net.minecraft.commands.arguments.TimeArgument;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerPlayer;
import org.apache.commons.lang3.time.DurationFormatUtils;
import us.rasor.mc.economy.bank.BalanceAttachment;

public class InsuranceCommand {

  public static void init() {
    CommandRegistrationCallback.EVENT.register(InsuranceCommand::register);
  }

  private static void register(CommandDispatcher<CommandSourceStack> dispatcher,
      CommandBuildContext buildContext, CommandSelection selection) {
    dispatcher.register(Commands.literal("insurance")
        .executes(InsuranceCommand::handleCommand)
        .then(Commands.literal("purchase")
            .then(Commands.argument("duration", TimeArgument.time(1))
                .executes(InsuranceCommand::handlePurchaseCommand)
            )
        )
    );
  }

  private static int handleCommand(CommandContext<CommandSourceStack> context)
      throws CommandSyntaxException {
    CommandSourceStack source = context.getSource();
    ServerPlayer player = source.getPlayerOrException();
    InsuranceAttachment insurance = new InsuranceAttachment(player);
    Instant insuranceEndsAt = insurance.get();
    Instant now = Instant.now();
    if (insuranceEndsAt != null && insuranceEndsAt.isAfter(now)) {
      source.sendSuccess(() -> Component.translatable("commands.economy.insurance.success",
          DurationFormatUtils.formatDurationWords(Duration.between(now, insuranceEndsAt).toMillis(),
              true, true)), false);
      return 0;
    } else {
      source.sendFailure(Component.translatable("commands.economy.insurance.failure"));
      return 1;
    }
  }

  private static int handlePurchaseCommand(CommandContext<CommandSourceStack> context)
      throws CommandSyntaxException {
    CommandSourceStack source = context.getSource();
    ServerPlayer player = source.getPlayerOrException();

    int insuranceDurationTicks = IntegerArgumentType.getInteger(context, "duration");

    // 1 diamond per day
    BigDecimal premium = BigDecimal.valueOf((double) insuranceDurationTicks / 24000)
        .setScale(3, RoundingMode.UP);

    BalanceAttachment balance = new BalanceAttachment(player);
    InsuranceAttachment insurance = new InsuranceAttachment(player);

    try (Transaction tx = Transaction.openOuter()) {
      balance.subtract(premium, tx);
      if (!balance.isLessThanZero()) {
        insurance.incrementPolicyDuration(Duration.ofMillis(insuranceDurationTicks * 50L), tx);
        tx.commit();
        source.sendSuccess(
            () -> Component.translatable("commands.economy.insurance.purchase.success",
                balance.getString()), false);
        return 0;
      } else {
        tx.abort();
        source.sendFailure(
            Component.translatable("commands.economy.insurance.purchase.failure", balance.getString(),
                BalanceAttachment.format(premium)));
        return 1;
      }
    }
  }
}
