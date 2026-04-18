package us.rasor.mc.difficulty.amplifier.mixin;

import net.minecraft.world.DifficultyInstance;
import net.minecraft.world.level.MoonPhase;
import net.minecraft.world.level.dimension.DimensionType;
import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.ModifyVariable;

@Mixin(DifficultyInstance.class)
abstract class EffectiveDifficultyMixin {

  @Shadow
  @Final
  private static float MAX_DIFFICULTY_TIME_GLOBAL;

  @Shadow
  @Final
  private static float MAX_DIFFICULTY_TIME_LOCAL;

  @ModifyVariable(
      method = "<init>",
      at = @At("HEAD"),
      argsOnly = true,
      ordinal = 0
  )
  private static long maximizeTotalGameTime(final long totalGameTime) {
    return (long) MAX_DIFFICULTY_TIME_GLOBAL;
  }

  @ModifyVariable(
      method = "<init>",
      at = @At("HEAD"),
      argsOnly = true,
      ordinal = 1
  )
  private static long maximizeLocalGameTime(final long localGameTime) {
    return (long) MAX_DIFFICULTY_TIME_LOCAL;
  }

  @ModifyVariable(
      method = "<init>",
      at = @At("HEAD"),
      argsOnly = true,
      ordinal = 0
  )
  private static float maximizeMoonBrightness(final float localGameTime) {
    return DimensionType.MOON_BRIGHTNESS_PER_PHASE[MoonPhase.FULL_MOON.index()];
  }
}
