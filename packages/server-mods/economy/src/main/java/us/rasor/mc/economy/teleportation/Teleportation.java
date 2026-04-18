package us.rasor.mc.economy.teleportation;

import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.vehicle.DismountHelper;
import net.minecraft.world.level.portal.TeleportTransition;
import net.minecraft.world.level.storage.LevelData.RespawnData;
import net.minecraft.world.phys.Vec3;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.operation.distance.DistanceOp;

import java.math.BigDecimal;
import java.math.RoundingMode;

public final class Teleportation {

  // Y=-59
  private static final double EXPECTED_DIAMOND_ORE_PER_BLOCK = (double) 226 / 100000;
  // fortune 3
  private static final double EXPECTED_DIAMONDS_PER_DIAMOND_ORE = 2.2;
  // efficiency 5 netherite pick mines every 9 ticks
  private static final double MAXIMUM_BLOCKS_MINED_PER_SECOND = (double) 20 / 9;
  private static final double MAXIMUM_DIAMONDS_PER_SECOND = MAXIMUM_BLOCKS_MINED_PER_SECOND * EXPECTED_DIAMOND_ORE_PER_BLOCK * EXPECTED_DIAMONDS_PER_DIAMOND_ORE;
  private static final double PROFIT_MARGIN = 1.1;
  private static final double BLUE_ICE_BOAT_SPEED = 72 + ((double) 8 /11);
  private static final double MINECART_SPEED = 8;

  private Teleportation() {
    throw new AssertionError();
  }

  public static void init() {
    HomeAttachment.init();
    HomeCommand.init();
    WarpsAttachment.init();
    WarpCommand.init();
  }

  public static BigDecimal computeFare(Vec3 origin, Vec3 destination, MinecraftServer server) {
    WarpsAttachment warps = new WarpsAttachment(server);
    Geometry convexHull = warps.getConvexHull();

    GeometryFactory geometryFactory = new GeometryFactory();
    Point originPoint = geometryFactory.createPoint(new Coordinate(origin.x(), origin.z()));
    Point destinationPoint = geometryFactory.createPoint(new Coordinate(destination.x(), destination.z()));

    double cheapDistance;
    double expensiveDistance;

    if (convexHull.contains(originPoint) && convexHull.contains(destinationPoint)) {
      expensiveDistance = 0;
      cheapDistance = originPoint.distance(destinationPoint);
    } else if (convexHull.contains(originPoint)) {
      Point convexHullPoint = geometryFactory.createPoint(DistanceOp.nearestPoints(convexHull, destinationPoint)[0]);
      expensiveDistance = destinationPoint.distance(convexHullPoint);
      cheapDistance = originPoint.distance(convexHullPoint);
    } else if (convexHull.contains(destinationPoint)) {
      Point convexHullPoint = geometryFactory.createPoint(DistanceOp.nearestPoints(convexHull, originPoint)[0]);
      expensiveDistance = originPoint.distance(convexHullPoint);
      cheapDistance = destinationPoint.distance(convexHullPoint);
    } else {
      cheapDistance = 0;
      expensiveDistance = originPoint.distance(destinationPoint);
    }

    double straightLineDistance = origin.distanceTo(destination);

    return new BigDecimal(
            Math.min(
                    computeCheapFarePart(cheapDistance) + computeExpensiveFarePart(expensiveDistance),
                    computeExpensiveFarePart(straightLineDistance)
            )
    ).setScale(3, RoundingMode.UP);
  }

  private static double computeCheapFarePart(double distance) {
    double netherDistance = distance / 8;

    return netherDistance / BLUE_ICE_BOAT_SPEED * MAXIMUM_DIAMONDS_PER_SECOND * PROFIT_MARGIN;
  }

  private static double computeExpensiveFarePart(double distance) {
    return distance / MINECART_SPEED * MAXIMUM_DIAMONDS_PER_SECOND * PROFIT_MARGIN;
  }

  public static Vec3 getAdjustedPosition(RespawnData destination, MinecraftServer server) {
    if (destination == null) {
      return null;
    }
    ServerLevel level = server.getLevel(destination.dimension());
    if (level == null) {
      return null;
    }
    return DismountHelper.findSafeDismountLocation(
            EntityType.PLAYER,
            level,
            destination.pos(),
            true
    );
  }

  public static TeleportTransition getTeleportTransition(RespawnData destination, MinecraftServer server) {
    if (destination == null) {
      return null;
    }
    Vec3 adjustedPosition = getAdjustedPosition(destination, server);
    ServerLevel level = server.getLevel(destination.dimension());
    if (adjustedPosition == null || level == null) {
      return null;
    }
    return new TeleportTransition(
            level,
            adjustedPosition,
            Vec3.ZERO,
            destination.yaw(),
            destination.pitch(),
            TeleportTransition.DO_NOTHING
    );
  }
}
