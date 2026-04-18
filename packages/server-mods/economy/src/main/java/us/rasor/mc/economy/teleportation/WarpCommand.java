package us.rasor.mc.economy.teleportation;

import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.arguments.StringArgumentType;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.exceptions.CommandSyntaxException;
import com.mojang.brigadier.suggestion.SuggestionProvider;
import com.mojang.brigadier.suggestion.Suggestions;
import com.mojang.brigadier.suggestion.SuggestionsBuilder;
import java.math.BigDecimal;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
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
import net.minecraft.world.level.portal.TeleportTransition;
import net.minecraft.world.level.storage.LevelData;
import net.minecraft.world.level.storage.LevelData.RespawnData;
import net.minecraft.world.phys.Vec3;
import us.rasor.mc.economy.bank.BalanceAttachment;

public class WarpCommand {

  public static void init() {
    CommandRegistrationCallback.EVENT.register(WarpCommand::register);
  }

  private static void register(CommandDispatcher<CommandSourceStack> dispatcher,
      CommandBuildContext buildContext, CommandSelection selection) {
    dispatcher.register(Commands.literal("warp")
        .executes(WarpCommand::handleCommand)
        .then(Commands.argument("name", StringArgumentType.greedyString())
            .suggests(new WarpSuggestionProvider())
            .executes(WarpCommand::handleTeleportCommand)
        )
        .then(Commands.literal("set")
            .then(Commands.argument("name", StringArgumentType.greedyString())
                .suggests(new WarpSuggestionProvider())
                .executes(WarpCommand::handleSetCommand)
            )
        )
        .then(Commands.literal("remove")
            .then(Commands.argument("name", StringArgumentType.greedyString())
                .suggests(new WarpSuggestionProvider())
                .executes(WarpCommand::handleRemoveCommand)
            )
        )
    );
  }

  private static int handleCommand(CommandContext<CommandSourceStack> context) {
    CommandSourceStack source = context.getSource();
    source.sendSuccess(() -> Component.literal(
        String.join(", ", new WarpsAttachment(source.getServer()).get().keySet())), false);
    return 0;
  }

  private static int handleTeleportCommand(CommandContext<CommandSourceStack> context)
      throws CommandSyntaxException {
    String warpName = StringArgumentType.getString(context, "name");
    CommandSourceStack source = context.getSource();
    ServerPlayer player = source.getPlayerOrException();
    MinecraftServer server = source.getServer();

    BalanceAttachment balance = new BalanceAttachment(player);
    WarpsAttachment warps = new WarpsAttachment(source.getServer());
    RespawnData warp = warps.get(warpName);
    TeleportTransition teleportTransition = Teleportation.getTeleportTransition(warp, server);

    if (teleportTransition == null) {
      source.sendFailure(Component.translatable("commands.economy.warp.to.failure.nonexistent"));
      return 1;
    }

    // TODO: add some kind of cross-dimension check

    BigDecimal fare = Teleportation.computeFare(source.getPosition(), teleportTransition.position(), server);

    try (Transaction tx = Transaction.openOuter()) {
      balance.subtract(fare, tx);
      if (!balance.isLessThanZero()) {
        player.teleport(teleportTransition);
        tx.commit();
        source.sendSuccess(
            () -> Component.translatable("commands.economy.warp.to.success", BalanceAttachment.format(fare), balance.getString()),
            false);
        return 0;
      } else {
        tx.abort();
        source.sendFailure(
            Component.translatable("commands.economy.warp.to.failure.insufficient_funds",
                balance.getString(), BalanceAttachment.format(fare)));
        return 2;
      }
    }
  }

  private static int handleSetCommand(CommandContext<CommandSourceStack> context)
      throws CommandSyntaxException {
    String warpName = StringArgumentType.getString(context, "name");
    CommandSourceStack source = context.getSource();

    WarpsAttachment warps = new WarpsAttachment(source.getServer());

    LevelData.RespawnData newWarp = new LevelData.RespawnData(
        new GlobalPos(source.getLevel().dimension(), source.getPlayerOrException().blockPosition()),
        source.getRotation().y, source.getRotation().x);

    try (Transaction tx = Transaction.openOuter()) {
      warps.put(warpName, newWarp, tx);
      if (warps.get(warpName) != null) {
        tx.commit();
        source.sendSuccess(
            () -> Component.translatable("commands.economy.warp.set.success", warpName), true);
        return 0;
      } else {
        tx.abort();
        source.sendFailure(Component.translatable("commands.economy.warp.set.failure"));
        return 1;
      }
    }
  }

  private static int handleRemoveCommand(CommandContext<CommandSourceStack> context)
      throws CommandSyntaxException {
    String warpName = StringArgumentType.getString(context, "name");
    CommandSourceStack source = context.getSource();

    WarpsAttachment warps = new WarpsAttachment(source.getServer());

    if (warps.get(warpName) == null) {
      source.sendFailure(Component.translatable("commands.economy.warp.remove.failure"));
      return 1;
    }

    try (Transaction tx = Transaction.openOuter()) {
      warps.remove(warpName, tx);
      tx.commit();
      source.sendSuccess(
          () -> Component.translatable("commands.economy.warp.remove.success", warpName),
          true);
      return 0;
    }
  }

  private static class WarpSuggestionProvider implements SuggestionProvider<CommandSourceStack> {

    @Override
    public CompletableFuture<Suggestions> getSuggestions(CommandContext<CommandSourceStack> context,
        SuggestionsBuilder builder) {
      MinecraftServer server = context.getSource().getServer();
      WarpsAttachment warps = new WarpsAttachment(server);

      for (String warpName : warps.get().keySet()) {
        builder.suggest(warpName);
      }

      return builder.buildFuture();
    }
  }
}
