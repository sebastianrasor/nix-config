package us.rasor.mc.economy.insurance.mixin;

import com.llamalad7.mixinextras.expression.Definition;
import com.llamalad7.mixinextras.expression.Expression;
import com.llamalad7.mixinextras.injector.ModifyExpressionValue;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.level.Level;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import us.rasor.mc.economy.insurance.KeepInventoryAttachment;

@Mixin(value = {Player.class, ServerPlayer.class})
abstract class KeepInventoryMixin extends LivingEntity {

  protected KeepInventoryMixin(
      EntityType<? extends LivingEntity> entityType,
      Level level) {
    super(entityType, level);
  }

  @Definition(id = "Boolean", type = Boolean.class)
  @Definition(id = "get", method = "Lnet/minecraft/world/level/gamerules/GameRules;get(Lnet/minecraft/world/level/gamerules/GameRule;)Ljava/lang/Object;")
  @Definition(id = "KEEP_INVENTORY", field = "Lnet/minecraft/world/level/gamerules/GameRules;KEEP_INVENTORY:Lnet/minecraft/world/level/gamerules/GameRule;")
  @Expression("((Boolean) ?.get(KEEP_INVENTORY))")
  @ModifyExpressionValue(
      method = {
          "dropEquipment",
          "getBaseExperienceReward",
          "restoreFrom",
      },
      at = @At("MIXINEXTRAS:EXPRESSION")
  )
  private Boolean shouldPlayerKeepInventory(Boolean original) {
    MinecraftServer server = level().getServer();
    if (server == null) {
      return original;
    }

    ServerPlayer player = server.getPlayerList().getPlayer(getUUID());
    if (player == null) {
      return original;
    }

    KeepInventoryAttachment keepInventory = new KeepInventoryAttachment(player);

    return keepInventory.shouldKeepInventory() || original;
  }
}