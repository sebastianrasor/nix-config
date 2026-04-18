package us.rasor.mc.economy.bank;

import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.arguments.IntegerArgumentType;
import com.mojang.brigadier.context.CommandContext;
import com.mojang.brigadier.exceptions.CommandSyntaxException;
import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;
import net.fabricmc.fabric.api.transfer.v1.item.ItemVariant;
import net.fabricmc.fabric.api.transfer.v1.item.PlayerInventoryStorage;
import net.fabricmc.fabric.api.transfer.v1.transaction.Transaction;
import net.minecraft.commands.CommandBuildContext;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.commands.Commands.CommandSelection;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.item.Items;

public class BankCommand {

  public static void init() {
    CommandRegistrationCallback.EVENT.register(BankCommand::register);
  }

  private static void register(CommandDispatcher<CommandSourceStack> dispatcher,
      CommandBuildContext buildContext, CommandSelection selection) {
    dispatcher.register(Commands.literal("bank")
        .then(Commands.literal("balance")
            .executes(BankCommand::handleCommand)
        )
        .then(Commands.literal("deposit")
            .then(Commands.argument("diamonds", IntegerArgumentType.integer(1))
                .executes(BankCommand::handleDepositCommand)
            )
        )
        .then(Commands.literal("withdraw")
            .then(Commands.argument("diamonds", IntegerArgumentType.integer(1))
                .executes(BankCommand::handleWithdrawCommand)
            )
        )
    );
  }

  private static int handleCommand(CommandContext<CommandSourceStack> context)
      throws CommandSyntaxException {
    CommandSourceStack source = context.getSource();
    ServerPlayer player = source.getPlayerOrException();
    BalanceAttachment balance = new BalanceAttachment(player);

    if (balance.get() == null) {
      source.sendFailure(
          Component.translatable("commands.economy.bank.failure"));
      return 1;
    }

    source.sendSuccess(() -> Component.translatable("commands.economy.bank.success", balance.getString()),
        false);
    return 0;
  }

  private static int handleDepositCommand(CommandContext<CommandSourceStack> context)
      throws CommandSyntaxException {
    int depositAmount = IntegerArgumentType.getInteger(context, "diamonds");
    CommandSourceStack source = context.getSource();
    ServerPlayer player = source.getPlayerOrException();

    BalanceAttachment balance = new BalanceAttachment(player);
    PlayerInventoryStorage inventory = PlayerInventoryStorage.of(player);

    try (Transaction tx = Transaction.openOuter()) {
      long diamondsExtracted = inventory.extract(ItemVariant.of(Items.DIAMOND), depositAmount, tx);
      balance.add(diamondsExtracted, tx);
      if (diamondsExtracted == depositAmount) {
        tx.commit();
        source.sendSuccess(
            () -> Component.translatable("commands.economy.bank.deposit.success", diamondsExtracted,
                balance.getString()), true);
        return 0;
      } else {
        tx.abort();
        source.sendFailure(
            Component.translatable("commands.economy.bank.deposit.failure", depositAmount,
                diamondsExtracted));
        return 1;
      }
    }
  }

  private static int handleWithdrawCommand(CommandContext<CommandSourceStack> context)
      throws CommandSyntaxException {
    int withdrawAmount = IntegerArgumentType.getInteger(context, "diamonds");
    CommandSourceStack source = context.getSource();
    ServerPlayer player = source.getPlayerOrException();

    BalanceAttachment balance = new BalanceAttachment(player);
    PlayerInventoryStorage inventory = PlayerInventoryStorage.of(player);

    try (Transaction tx = Transaction.openOuter()) {
      balance.subtract(withdrawAmount, tx);
      long diamondsInserted = inventory.offer(ItemVariant.of(Items.DIAMOND), withdrawAmount, tx);
      if (balance.isLessThanZero()) {
        tx.abort();
        source.sendFailure(
            Component.translatable("commands.economy.bank.withdraw.failure.insufficient_funds",
                withdrawAmount, balance.getString()));
        return 1;
      } else if (diamondsInserted < withdrawAmount) {
        tx.abort();
        source.sendFailure(
            Component.translatable("commands.economy.bank.withdraw.failure.insufficient_room",
                withdrawAmount, diamondsInserted));
        return 2;
      } else {
        tx.commit();
        source.sendSuccess(
            () -> Component.translatable("commands.economy.bank.withdraw.success", diamondsInserted,
                balance.getString()), true);
        return 0;
      }
    }
  }

}
