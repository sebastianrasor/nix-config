package us.rasor.mc.economy.teleportation;

import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.exceptions.CommandSyntaxException;
import java.math.BigDecimal;
import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;
import net.fabricmc.fabric.api.transfer.v1.transaction.Transaction;
import net.minecraft.commands.CommandBuildContext;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.commands.Commands.CommandSelection;
import net.minecraft.core.GlobalPos;
import net.minecraft.network.chat.Component;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.portal.TeleportTransition;
import net.minecraft.world.level.storage.LevelData;
import net.minecraft.world.phys.Vec3;
import us.rasor.mc.economy.bank.BalanceAttachment;

public class HomeCommand {

  private static final double SET_HOME_MULTIPLIER = 100;

  public static void init() {
    CommandRegistrationCallback.EVENT.register(HomeCommand::register);
  }

  private static void register(CommandDispatcher<CommandSourceStack> dispatcher,
      CommandBuildContext buildContext, CommandSelection selection) {
    dispatcher.register(Commands.literal("home").executes(HomeCommand::handleCommand)
        .then(Commands.literal("set")
            .executes(HomeCommand::handleSetCommand)
        )
    );


  }

  private static int handleCommand(CommandContext<CommandSourceStack> context)
      throws CommandSyntaxException {
    CommandSourceStack source = context.getSource();
    ServerPlayer player = source.getPlayerOrException();
    MinecraftServer server = source.getServer();

    BalanceAttachment balance = new BalanceAttachment(player);
    HomeAttachment home = new HomeAttachment(player);
    TeleportTransition teleportTransition = Teleportation.getTeleportTransition(home.get(), server);

    if (teleportTransition == null) {
      source.sendFailure(Component.translatable("commands.economy.home.failure.unset"));
      return 1;
    }

    BigDecimal fare = Teleportation.computeFare(source.getPosition(), teleportTransition.position(), server);

    try (Transaction tx = Transaction.openOuter()) {
      balance.subtract(fare, tx);
      if (!balance.isLessThanZero()) {
        player.teleport(teleportTransition);
        tx.commit();
        source.sendSuccess(
            () -> Component.translatable("commands.economy.home.success", BalanceAttachment.format(fare), balance.getString()),
            false);
        return 0;
      } else {
        tx.abort();
        source.sendFailure(
            Component.translatable("commands.economy.home.failure.insufficient_funds",
                balance.getString(), BalanceAttachment.format(fare)));
        return 1;
      }
    }
  }

  private static int handleSetCommand(CommandContext<CommandSourceStack> context)
      throws CommandSyntaxException {
    CommandSourceStack source = context.getSource();
    if (source.getLevel().dimension() != Level.OVERWORLD) {
      source.sendFailure(
          Component.translatable("commands.economy.home.set.failure.invalid_location"));
      return 1;
    }

    ServerPlayer player = source.getPlayerOrException();
    MinecraftServer server = source.getServer();
    BalanceAttachment balance = new BalanceAttachment(player);
    HomeAttachment home = new HomeAttachment(player);

    LevelData.RespawnData newHome = new LevelData.RespawnData(
        new GlobalPos(source.getLevel().dimension(), player.blockPosition()),
        source.getRotation().y, source.getRotation().x);

    try (Transaction tx = Transaction.openOuter()) {
      home.set(newHome, tx);
      TeleportTransition teleportTransition = Teleportation.getTeleportTransition(home.get(), server);
      if (teleportTransition == null) {
        tx.abort();
        source.sendFailure(
            Component.translatable("commands.economy.home.set.failure.invalid_location"));
        return 2;
      }
      BigDecimal fee = Teleportation.computeFare(Vec3.ZERO, teleportTransition.position(), server);
      balance.subtract(fee, tx);
      if (!balance.isLessThanZero()) {
        tx.commit();
        source.sendSuccess(
            () -> Component.translatable("commands.economy.home.set.success", BalanceAttachment.format(fee), balance.getString()),
            false);
        return 0;
      } else {
        tx.abort();
        source.sendFailure(
            Component.translatable("commands.economy.home.set.failure.insufficient_funds",
                balance.getString(), BalanceAttachment.format(fee)));
        return 3;
      }
    }
  }
}
