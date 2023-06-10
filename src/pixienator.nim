
import std/sugar
import pixie, pixie/paths
import delaunator, delaunator/helpers


#[ TODO:
 pathForExtents, pathForBounds, pathForNeighborSites
 better naming of avail vars
reconsider path and pth, etc
support labels
reconsider naming?
]#

#NOTE: template params that are to be passed along to optional body must be
# name differently than that declared in the template local block. I.e. a
# template which requires a halfedge id and also wishes to pass it along to
# the body will name the template param `edgeId` and then declare `eid` in
# the local block assigned as edgeId. (see for instance pathForHalfedge)

# Defaults
let
  sitesRadius = 1.5
  siteRadius = 5.0
  hullSitesRadius = 3.0
  hullSiteRadius = 5.0
  circumcentersRadius = 1.0
  circumcenterRadius = 5.0
  triCentroidsRadius = 1.0
  plyCentroidsRadius = 1.0
  centroidRadius = 3.0
  triangleSiteRadius = 2.0


template defaultFor*(body, default: untyped) {.dirty.}=
  when astToStr(body) == "nil":
    default
  else:
    body


# proc pathForSites*(
#   d: Delaunator,
#   pthproc: (var Path, uint32, array[2, float]) -> void =
#            (pth: var Path, pid: uint32, p: array[2, float]) =>
#              pth.circle(float32(p[0]), float32(p[1]), sitesRadius)
# ): Path =
#   var path = newPath()
#   for (pid, p) in d.iterPoints:
#     pthproc(path, pid, p)
#   return path
template pathForSites*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  bind pixienator.sitesRadius
  block:
    var path = newPath()
    for (pid, p) in d.iterPoints:
      defaultFor(body):
        path.circle(float32(p[0]), float32(p[1]), sitesRadius)
    path

# proc pathForSite*(
#   d: Delaunator,
#   pid: uint32,
#   pthproc: (var Path, uint32, array[2, float]) -> void =
#            (pth: var Path, pid: uint32, p: array[2, float]) =>
#              pth.circle(float32(p[0]), float32(p[1]), siteRadius)
# ): Path =
#   var
#     path = newPath()
#     p = [d.coords[2 * pid], d.coords[2 * pid + 1]]
#   pthproc(path, pid, p)
#   return path
template pathForSite*(d: Delaunator, siteId: uint32, body: untyped = nil): Path {.dirty.} =
  bind pixienator.siteRadius
  block:
    var
      path = newPath()
      pid = siteId
      p = [d.coords[2 * pid], d.coords[2 * pid + 1]]
    defaultFor(body):
      path.circle(float32(p[0]), float32(p[1]), siteRadius)
    path


# proc pathForCircumcenters*(
#   d: Delaunator,
#   pthproc: (var Path, uint32, array[2, float]) -> void =
#            (pth: var Path, tid: uint32, p: array[2, float]) =>
#              pth.circle(float32(p[0]), float32(p[1]), circumcentersRadius)
# ): Path =
#   var path = newPath()
#   for (tid, _, _, _, _, _, _) in d.iterTriangles:
#     let c = triangleCircumcenter(d, tid)
#     pthproc(path, tid, c)
#   return path
template pathForCircumcenters*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  bind pixienator.circumcentersRadius
  block:
    var path = newPath()
    for (tid, _, _, _, _, _, _) in d.iterTriangles:
      let c = triangleCircumcenter(d, tid)
      defaultFor(body):
        path.circle(float32(c[0]), float32(c[1]), circumcentersRadius)
    path


# proc pathForCircumcenter*(
#   d: Delaunator,
#   tid: uint32,
#   pthproc: (var Path, uint32, array[2, float]) -> void =
#            (pth: var Path, tid: uint32, p: array[2, float]) =>
#              pth.circle(float32(p[0]), float32(p[1]), circumcenterRadius)
# ): Path =
#   var
#     path = newPath()
#     c = triangleCircumcenter(d, tid)
#   pthproc(path, tid, c)
#   return path
template pathForCircumcenter*(d: Delaunator, triangleId: uint32, body: untyped = nil): Path {.dirty.} =
  bind pixienator.circumcenterRadius
  block:
    var
      path = newPath()
      tid = triangleId
      c = triangleCircumcenter(d, tid)
    defaultFor(body):
      path.circle(float32(c[0]), float32(c[1]), circumcenterRadius)
    path


# proc pathForTriangleCentroids*(
#   d: Delaunator,
#   pthproc: (var Path, uint32, array[2, float]) -> void =
#            (pth: var Path, tid: uint32, p: array[2, float]) =>
#              pth.circle(float32(p[0]), float32(p[1]), triCentroidsRadius)
# ): Path =
#   var path = newPath()
#   for (tid, _, _, _, _, _, _) in d.iterTriangles:
#     let c = triangleCentroid(d, tid)
#     pthproc(path, tid, c)
#   return path
template pathForTriangleCentroids*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  bind pixienator.triCentroidsRadius
  block:
    var path = newPath()
    for (tid, _, _, _, _, _, _) in d.iterTriangles:
      let c = triangleCentroid(d, tid)
      defaultFor(body):
        path.circle(float32(c[0]), float32(c[1]), triCentroidsRadius)
    path


# proc pathForTriangleCentroid*(
#   d: Delaunator,
#   tid: uint32,
#   pthproc: (var Path, uint32, array[2, float]) -> void =
#            (pth: var Path, tid: uint32, p: array[2, float]) =>
#              pth.circle(float32(p[0]), float32(p[1]), centroidRadius)
# ): Path =
#   var
#     path = newPath()
#     c = triangleCentroid(d, tid)
#   pthproc(path, tid, c)
#   return path
template pathForTriangleCentroid*(d: Delaunator, triangleId: uint32, body: untyped = nil): Path {.dirty.} =
  bind pixienator.centroidRadius
  block:
    var
      path = newPath()
      tid = triangleId
      c = triangleCentroid(d, tid)
    defaultFor(body):
      path.circle(float32(c[0]), float32(c[1]), centroidRadius)
    path


# proc pathForRegionCentroids*(
#   d: Delaunator,
#   pthproc: (var Path, uint32, array[2, float]) -> void =
#            (pth: var Path, pid: uint32, p: array[2, float]) =>
#              pth.circle(float32(p[0]), float32(p[1]), plyCentroidsRadius)
# ): Path =
#   var path = newPath()
#   for (pid, verts) in d.iterVoronoiRegions:
#     let c = polygonCentroid(verts)
#     pthproc(path, pid, c)
#   return path
template pathForRegionCentroids*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  bind pixienator.plyCentroidsRadius
  block:
    var path = newPath()
    for (pid, verts) in d.iterVoronoiRegions:
      let c = polygonCentroid(verts)
      defaultFor(body):
        path.circle(float32(c[0]), float32(c[1]), plyCentroidsRadius)
    path


# proc pathForRegionCentroid*(
#   d: Delaunator,
#   pid: uint32,
#   pthproc: (var Path, uint32, array[2, float]) -> void =
#            (pth: var Path, pid: uint32, p: array[2, float]) =>
#              pth.circle(float32(p[0]), float32(p[1]), centroidRadius)
# ): Path =
#   var
#     path = newPath()
#     (pid, verts) = voronoiRegion(d, pid)
#     c = polygonCentroid(verts)
#   pthproc(path, pid, c)
#   return path
template pathForRegionCentroid*(d: Delaunator, siteId: uint32, body: untyped = nil): Path {.dirty.} =
  bind pixienator.centroidRadius
  block:
    var
      path = newPath()
      (pid, verts) = voronoiRegion(d, siteId)
      c = polygonCentroid(verts)
    defaultFor(body):
      path.circle(float32(c[0]), float32(c[1]), centroidRadius)
    path


# proc pathForHullSites*(
#   d: Delaunator,
#   pthproc: (var Path, uint32, uint32, array[2, float]) -> void =
#            (pth: var Path, hid: uint32, pid: uint32, p: array[2, float]) =>
#              pth.circle(float32(p[0]), float32(p[1]), hullSitesRadius)
# ): Path =
#   var path = newPath()
#   for (hid, pid, p) in d.iterHullPoints:
#     pthproc(path, hid, pid, p)
#   return path
template pathForHullSites*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  bind pixienator.hullSitesRadius
  block:
    var path = newPath()
    for (hid, pid, p) in d.iterHullPoints:
      defaultFor(body):
        path.circle(float32(p[0]), float32(p[1]), hullSitesRadius)
    path


# proc pathForHullSite*(
#   d: Delaunator,
#   hid: uint32,
#   pthproc: (var Path, uint32, uint32, array[2, float]) -> void =
#            (pth: var Path, hid: uint32, pid: uint32, p: array[2, float]) =>
#              pth.circle(float32(p[0]), float32(p[1]), hullSiteRadius)
# ): Path =
#   var
#     path = newPath()
#     pid = d.hull[hid]
#     p = [d.coords[2 * pid], d.coords[2 * pid + 1]]
#   pthproc(path, hid, pid, p)
#   return path
template pathForHullSite*(d: Delaunator, hullId: uint32, body: untyped = nil): Path {.dirty.} =
  bind pixienator.hullSiteRadius
  block:
    var
      path = newPath()
      hid = hullId
      pid = d.hull[hullId]
      p = [d.coords[2 * pid], d.coords[2 * pid + 1]]
    defaultFor(body):
      path.circle(float32(p[0]), float32(p[1]), hullSiteRadius)
    path


# proc pathForHalfedge*(
#   d: Delaunator,
#   eid: int32,
#   pthproc: (var Path, int32, uint32, uint32, array[2, float], array[2, float]) -> void =
#            proc (pth: var Path, eid: int32, pid: uint32, qid: uint32, p: array[2, float], q: array[2, float]) =
#              pth.moveto(float32(p[0]), float32(p[1]))
#              pth.lineto(float32(q[0]), float32(q[1]))
#              pth.closepath()
# ): Path =
#   var
#     path = newPath()
#     pid = d.triangles[eid]
#     qid = d.triangles[nextHalfedge(eid)]
#     p = [d.coords[(2 * pid)], d.coords[(2 * pid + 1)]]
#     q = [d.coords[(2 * qid)], d.coords[(2 * qid + 1)]]
#   pthproc(path, eid, pid, qid, p, q)
#   return path
template pathForHalfedge*(d: Delaunator, edgeId: int32, body: untyped = nil): Path {.dirty.} =
  block:
    var
      path = newPath()
      eid = edgeId
      pid = d.triangles[edgeId]
      qid = d.triangles[nextHalfedge(edgeId)]
      p = [d.coords[(2 * pid)], d.coords[(2 * pid + 1)]]
      q = [d.coords[(2 * qid)], d.coords[(2 * qid + 1)]]
    defaultFor(body):
      path.moveto(float32(p[0]), float32(p[1]))
      path.lineto(float32(q[0]), float32(q[1]))
      path.closepath()
    path


# proc pathsForHalfedgesAroundSite*(
#   d: Delaunator,
#   pid: uint32,
#   pthproc: (var Path, int32, uint32, uint32, array[2, float], array[2, float]) -> void =
#            proc (pth: var Path, eid: int32, pid: uint32, qid: uint32, p: array[2, float], q: array[2, float]) =
#              pth.moveTo(float32(p[0]), float32(p[1]))
#              pth.lineTo(float32(q[0]), float32(q[1]))
#              pth.closePath()
# ): seq[Path] =
#   var
#     eid = pointToLeftmostHalfedge(d, pid)
#     edges = edgeIdsAroundPoint(d, eid)
#     paths = newSeqOfCap[Path](edges.len)
#   for he in edges:
#     paths.add(pathForHalfedge(d, he, pthproc))
#   return paths
template pathsForHalfedgesAroundSite*(d: Delaunator, siteId: uint32, body: untyped = nil): seq[Path] {.dirty.} =
  block:
    var
      leftmostEdge = pointToLeftmostHalfedge(d, siteId)
      edges = edgeIdsAroundPoint(d, leftmostEdge)
      paths = newSeqOfCap[Path](edges.len)
    for he in edges:
      var
        path = newPath()
        sid = siteId
        eid = he
        pid = d.triangles[he]
        qid = d.triangles[nextHalfedge(he)]
        p = [d.coords[(2 * pid)], d.coords[(2 * pid + 1)]]
        q = [d.coords[(2 * qid)], d.coords[(2 * qid + 1)]]
      defaultFor(body):
        path.moveTo(float32(p[0]), float32(p[1]))
        path.lineTo(float32(q[0]), float32(q[1]))
        path.closePath()
      paths.add(path)
    paths



# proc pathForHull*(
#   d: Delaunator,
#   pthproc: (var Path, uint32, int32, uint32, uint32, array[2, float], array[2, float]) -> void =
#            proc (pth: var Path, hid: uint32, eid: int32, pid: uint32, qid: uint32, p: array[2, float], q: array[2, float]) =
#              pth.moveTo(float32(p[0]), float32(p[1]))
#              pth.lineTo(float32(q[0]), float32(q[1]))
#              pth.closePath()
# ): Path =
#   var
#     path = newPath()
#     epth = newPath()
#   for (hid, eid, pid, qid, p, q) in d.iterHullEdges:
#     pthproc(epth, hid, eid, pid, qid, p, q)
#     path.addPath(epth)
#   return path
template pathForHull*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  block:
    var
      path = newPath()
      epth = newPath()
    for (hid, eid, pid, qid, p, q) in d.iterHullEdges:
      defaultFor(body):
        epth.moveTo(float32(p[0]), float32(p[1]))
        epth.lineTo(float32(q[0]), float32(q[1]))
        epth.closePath()
      path.addPath(epth)
    path


# proc pathForTriangleSites*(
#   d: Delaunator,
#   tid: uint32,
#   pthproc: (var Path, uint32, uint32, uint32, uint32, array[2, float], array[2, float], array[2, float]) -> void =
#            proc (pth: var Path, tid: uint32, pid: uint32, qid: uint32, rid: uint32, p: array[2, float], q: array[2, float], r: array[2, float]) =
#              pth.circle(float32(p[0]), float32(p[1]), triangleSiteRadius)
#              pth.circle(float32(q[0]), float32(q[1]), triangleSiteRadius)
#              pth.circle(float32(r[0]), float32(r[1]), triangleSiteRadius)
# ): Path =
#   var
#     path = newPath()
#     pids = pointIdsOfTriangle(d, tid)
#     a = [d.coords[2 * pids[0]], d.coords[2 * pids[0] + 1]]
#     b = [d.coords[2 * pids[1]], d.coords[2 * pids[1] + 1]]
#     c = [d.coords[2 * pids[2]], d.coords[2 * pids[2] + 1]]
#   pthproc(path, tid, pids[0] ,pids[1], pids[2], a, b, c)
#   return path
template pathForTriangleSites*(d: Delaunator, triangleId: uint32, body: untyped = nil): Path {.dirty.} =
  bind triangleSiteRadius
  block:
    var
      path = newPath()
      tid = triangleId
      pntIds = pointIdsOfTriangle(d, triangleId)
      pid = pntIds[0]
      qid = pntIds[1]
      rid = pntIds[2]
      p = [d.coords[2 * pid], d.coords[2 * pid + 1]]
      q = [d.coords[2 * qid], d.coords[2 * qid + 1]]
      r = [d.coords[2 * rid], d.coords[2 * rid + 1]]
    defaultFor(body):
      path.circle(float32(p[0]), float32(p[1]), triangleSiteRadius)
      path.circle(float32(q[0]), float32(q[1]), triangleSiteRadius)
      path.circle(float32(r[0]), float32(r[1]), triangleSiteRadius)
    path


#[
proc pathForTriangleEdges*(
  d: Delaunator,
  pthproc: (var Path, uint32, int32, uint32, uint32, array[2, float], array[2, float]) -> void =
           proc (pth: var Path, tid: uint32, eid: int32, pid: uint32, qid: uint32, p: array[2, float], q: array[2, float]) =
             pth.moveTo(float32(p[0]), float32(p[1]))
             pth.lineTo(float32(q[0]), float32(q[1]))
             pth.closePath()
): Path =
  var
    path = newPath()
    epth = newPath()
  for (tid, eid, pid, qid, p, q) in d.iterTriangleEdges:
    pthproc(epth, tid, eid, pid, qid, p, q)
    path.addPath(epth)
  return path
]#
template pathForTriangleEdges*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  block:
    var path = newPath()
    for (tid, eid, pid, qid, p, q) in d.iterTriangleEdges:
      let pth = newPath()
      defaultFor(body):
        pth.moveTo(float32(p[0]), float32(p[1]))
        pth.lineTo(float32(q[0]), float32(q[1]))
        pth.closePath()
      path.addPath(pth)
    path


# proc pathsForTriangles*(
#   d: Delaunator,
#   pthproc: (var Path, uint32, uint32, uint32, uint32, array[2, float], array[2, float], array[2, float]) -> void =
#            proc (pth: var Path, tid: uint32, pid: uint32, qid: uint32, rid: uint32, p: array[2, float], q: array[2, float], r: array[2, float]) =
#              pth.moveTo(float32(p[0]), float32(p[1]))
#              pth.lineTo(float32(q[0]), float32(q[1]))
#              pth.lineTo(float32(r[0]), float32(r[1]))
#              pth.closePath()
# ): seq[Path] =
#   var paths = newSeqOfCap[Path](floorDiv(d.triangles.len, 3))
#   for (tid, pid, qid, rid, p, q, r) in d.iterTriangles:
#     var pth = newPath()
#     pthproc(pth, tid, pid, qid, rid, p, q, r)
#     paths.add(pth)
#   return paths
template pathsForTriangles*(d: Delaunator, body: untyped = nil): seq[Path] {.dirty.} =
  block:
    var paths = newSeqOfCap[Path](floorDiv(d.triangles.len, 3))
    for (tid, pid, qid, rid, p, q, r) in d.iterTriangles:
      var path = newPath()
      #pthproc(pth, tid, pid, qid, rid, p, q, r)
      defaultFor(body):
        path.moveTo(float32(p[0]), float32(p[1]))
        path.lineTo(float32(q[0]), float32(q[1]))
        path.lineTo(float32(r[0]), float32(r[1]))
        path.closePath()
      paths.add(path)
    paths


# proc pathForTriangle*(
#   d: Delaunator,
#   tid: uint32,
#   pthproc: (var Path, uint32, uint32, uint32, uint32, array[2, float], array[2, float], array[2, float]) -> void =
#            proc (pth: var Path, tid: uint32, pid: uint32, qid: uint32, rid: uint32, p: array[2, float], q: array[2, float], r: array[2, float]) =
#              pth.moveTo(float32(p[0]), float32(p[1]))
#              pth.lineTo(float32(q[0]), float32(q[1]))
#              pth.lineTo(float32(r[0]), float32(r[1]))
#              pth.closePath()
# ): Path =
#   var
#     path = newPath()
#     pids = pointIdsOfTriangle(d, tid)
#     a = [d.coords[2 * pids[0]], d.coords[2 * pids[0] + 1]]
#     b = [d.coords[2 * pids[1]], d.coords[2 * pids[1] + 1]]
#     c = [d.coords[2 * pids[2]], d.coords[2 * pids[2] + 1]]
#   pthproc(path, tid, pids[0], pids[1], pids[2], a, b, c)
#   return path
template pathForTriangle*(d: Delaunator, triangleId: uint32, body: untyped = nil): Path {.dirty.} =
  block:
    var
      path = newPath()
      tid = triangleId
      pntIds = pointIdsOfTriangle(d, triangleId)
      pid = pntIds[0]
      qid = pntIds[1]
      rid = pntIds[2]
      p = [d.coords[2 * pid], d.coords[2 * pid + 1]]
      q = [d.coords[2 * qid], d.coords[2 * qid + 1]]
      r = [d.coords[2 * rid], d.coords[2 * rid + 1]]
    defaultFor(body):
      path.moveTo(float32(p[0]), float32(p[1]))
      path.lineTo(float32(q[0]), float32(q[1]))
      path.lineTo(float32(r[0]), float32(r[1]))
      path.closePath()
    path


# proc pathForRegionEdges*(
#   d: Delaunator,
#   pthproc: (var Path, int32, array[2, float], array[2, float]) -> void =
#            proc (pth: var Path, eid: int32, p: array[2, float], q: array[2, float]) =
#              pth.moveTo(float32(p[0]), float32(p[1]))
#              pth.lineTo(float32(q[0]), float32(q[1]))
#              pth.closePath()
# ): Path =
#   var path = newPath()
#   for (eid, p, q) in d.iterVoronoiEdges:
#     var pth = newPath()
#     pthproc(pth, eid, p, q)
#     path.addPath(pth)
#   return path
template pathForRegionEdges*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  block:
    var path = newPath()
    for (eid, p, q) in d.iterVoronoiEdges:
      var pth = newPath()
      defaultFor(body):
        pth.moveTo(float32(p[0]), float32(p[1]))
        pth.lineTo(float32(q[0]), float32(q[1]))
        pth.closePath()
      path.addPath(pth)
    path


# proc pathsForRegions*(
#   d: Delaunator,
#   pthproc: (var Path, uint32, seq[array[2, float]]) -> void =
#            proc (pth: var Path, sid: uint32, verts: seq[array[2, float]]) =
#              pth.moveTo(float32(verts[0][0]), float32(verts[0][1]))
#              for v in verts[1 .. ^1]:
#                pth.lineTo(float32(v[0]), float32(v[1]))
#              pth.closePath()
# ): seq[Path] =
#   var paths = newSeqOfCap[Path](ashr(d.coords.len, 1))
#   for (sid, verts) in d.iterVoronoiRegions:
#     var pth = newPath()
#     pthproc(pth, sid, verts)
#     paths.add(pth)
#  return paths
template pathsForRegions*(d: Delaunator, body: untyped = nil): seq[Path] {.dirty.} =
  block:
    var paths = newSeqOfCap[Path](ashr(d.coords.len, 1))
    for (sid, verts) in d.iterVoronoiRegions:
      var path = newPath()
      defaultFor(body):
        path.moveTo(float32(verts[0][0]), float32(verts[0][1]))
        for v in verts[1 .. ^1]:
          path.lineTo(float32(v[0]), float32(v[1]))
        path.closePath()
      paths.add(path)
    paths


# proc pathForRegion*(
#   d: Delaunator,
#   sid: uint32,
#   pthproc: (var Path, uint32, seq[array[2, float]]) -> void =
#            proc (pth: var Path, sid: uint32, verts: seq[array[2, float]]) =
#              pth.moveTo(float32(verts[0][0]), float32(verts[0][1]))
#              for v in verts[1 .. ^1]:
#                pth.lineTo(float32(v[0]), float32(v[1]))
#              pth.closePath()
# ): Path =
#   var
#     path = newPath()
#     (sid, verts) = voronoiRegion(d, sid)
#   if verts.len != 0:
#     pthproc(path, sid, verts)
#   return path
template pathForRegion*(d: Delaunator, siteId: uint32, body: untyped = nil): Path {.dirty.} =
  block:
    var
      path = newPath()
      (sid, verts) = voronoiRegion(d, siteId)
    if verts.len != 0:
      defaultFor(body):
        path.moveTo(float32(verts[0][0]), float32(verts[0][1]))
        for v in verts[1 .. ^1]:
          path.lineTo(float32(v[0]), float32(v[1]))
        path.closePath()
    path

template pathForBounds*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  block:
    var
      path = newPath()
      (minX, minY, maxX, maxY) = d.bounds
      x = minX
      y = minY
      w = maxX - minX
      h = maxY - minY
    defaultFor(body):
      path.rect(x, y, w, h)
    path
