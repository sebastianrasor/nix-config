package us.rasor.mc.difficulty.deathban.mixin;

import net.minecraft.server.players.StoredUserEntry;
import net.minecraft.server.players.StoredUserList;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Overwrite;
import org.spongepowered.asm.mixin.Shadow;

@Mixin(StoredUserList.class)
abstract class StoredUserListContainsExpiredMixin<K, V extends StoredUserEntry<K>> {

  @Shadow
  public abstract V get(K object);

  @SuppressWarnings("OverwriteAuthorRequired")
  @Overwrite
  protected boolean contains(K object) {
    V userEntry = get(object);

    return !(userEntry == null || userEntry.hasExpired());
  }
}