package us.rasor.mc.economy.teleportation;

import com.mojang.serialization.Codec;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import net.fabricmc.fabric.api.attachment.v1.AttachmentRegistry;
import net.fabricmc.fabric.api.attachment.v1.AttachmentType;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents;
import net.fabricmc.fabric.api.transfer.v1.transaction.TransactionContext;
import net.fabricmc.fabric.api.transfer.v1.transaction.base.SnapshotParticipant;
import net.minecraft.resources.Identifier;
import net.minecraft.server.MinecraftServer;
import net.minecraft.world.level.storage.LevelData.RespawnData;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;

public class WarpsAttachment extends SnapshotParticipant<Optional<Map<String, RespawnData>>> {

  private static AttachmentType<Map<String, RespawnData>> WARPS;

  private final MinecraftServer server;
  private Map<String, RespawnData> value;
  private Geometry convexHull;

  public WarpsAttachment(MinecraftServer server) {
    this.server = server;
    this.value = server.globalAttachments().getAttached(WARPS);
  }

  public static void init() {
    WARPS = AttachmentRegistry.create(Identifier.fromNamespaceAndPath("rasor-economy", "warp"),
        builder -> builder.initializer(HashMap::new)
            .persistent(Codec.unboundedMap(Codec.STRING, RespawnData.CODEC))
            .copyOnDeath()
    );

    ServerLifecycleEvents.SERVER_STARTED.register(server -> {
      server.globalAttachments().getAttachedOrCreate(WARPS);
    });
  }

  public Map<String, RespawnData> get() {
    return value;
  }

  public Geometry getConvexHull() {
    if (convexHull == null) {
      convexHull = computeConvexHull();
    }
    return convexHull;
  }

  public RespawnData get(String warpName) {
    return value.get(warpName);
  }

  public void put(String warpName, RespawnData warp, TransactionContext transaction) {
    updateSnapshots(transaction);
    value.put(warpName, warp);
    if (convexHull != null) {
      convexHull = computeConvexHull();
    }
  }

  public void remove(String warpName, TransactionContext transaction) {
    updateSnapshots(transaction);
    value.remove(warpName);
    if (convexHull != null) {
      convexHull = computeConvexHull();
    }
  }

  private Geometry computeConvexHull() {
    Coordinate[] warpCoordinates = value
        .values()
        .stream()
        .map(r -> new Coordinate(r.pos().getX(), r.pos().getZ()))
        .toArray(Coordinate[]::new);

    return new GeometryFactory()
            .createMultiPointFromCoords(warpCoordinates)
            .convexHull();
  }

  @Override
  protected Optional<Map<String, RespawnData>> createSnapshot() {
    return Optional.ofNullable(value);
  }

  @Override
  protected void readSnapshot(Optional<Map<String, RespawnData>> snapshot) {
    value = snapshot.orElse(null);
  }

  @Override
  protected void onFinalCommit() {
    server.globalAttachments().setAttached(WARPS, value);
  }
}
