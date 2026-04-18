package us.rasor.mc.difficulty.deathban.mixin;

import com.llamalad7.mixinextras.expression.Definition;
import com.llamalad7.mixinextras.expression.Expression;
import com.llamalad7.mixinextras.injector.ModifyExpressionValue;
import net.minecraft.server.network.ServerGamePacketListenerImpl;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;

@Mixin(ServerGamePacketListenerImpl.class)
abstract class HardcoreRespawnMixin {

  @Definition(id = "Boolean", type = Boolean.class)
  @Definition(id = "get", method = "Lnet/minecraft/world/level/gamerules/GameRules;get(Lnet/minecraft/world/level/gamerules/GameRule;)Ljava/lang/Object;")
  @Definition(id = "KEEP_INVENTORY", field = "Lnet/minecraft/world/level/gamerules/GameRules;KEEP_INVENTORY:Lnet/minecraft/world/level/gamerules/GameRule;")
  @Expression("((Boolean) ?.get(KEEP_INVENTORY))")
  @ModifyExpressionValue(
      method = "handleClientCommand",
      at = @At(value = "INVOKE", target = "Lnet/minecraft/server/MinecraftServer;isHardcore()Z")
  )
  private boolean shouldRespawnInSpectator(boolean original) {
    return false;
  }
}