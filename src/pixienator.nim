
import std/sugar
import pixie, pixie/paths
import delaunator, delaunator/helpers


#[ TODO:
 pathForExtents, pathForBounds, pathForNeighborSites
allow override of pathing with custom anonomous proc?
support labels
reconsider naming?
]#


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


proc pathForSites*(
  d: Delaunator,
  pthproc: (var Path, uint32, array[2, float]) -> void =
           (pth: var Path, pid: uint32, p: array[2, float]) =>
             pth.circle(float32(p[0]), float32(p[1]), sitesRadius)
): Path =
  var path = newPath()
  for (pid, p) in d.iterPoints:
    pthproc(path, pid, p)
  return path


proc pathForSite*(
  d: Delaunator,
  pid: uint32,
  pthproc: (var Path, uint32, array[2, float]) -> void =
           (pth: var Path, pid: uint32, p: array[2, float]) =>
             pth.circle(float32(p[0]), float32(p[1]), siteRadius)
): Path =
  var
    path = newPath()
    p = [d.coords[pid], d.coords[pid + 1]]
  pthproc(path, pid, p)
  return path


proc pathForCircumcenters*(
  d: Delaunator,
  pthproc: (var Path, uint32, array[2, float]) -> void =
           (pth: var Path, tid: uint32, p: array[2, float]) =>
             pth.circle(float32(p[0]), float32(p[1]), circumcentersRadius)
): Path =
  var path = newPath()
  for (tid, _, _, _, _, _, _) in d.iterTriangles:
    let c = triangleCircumcenter(d, tid)
    pthproc(path, tid, c)
  return path


proc pathForCircumcenter*(
  d: Delaunator,
  tid: uint32,
  pthproc: (var Path, uint32, array[2, float]) -> void =
           (pth: var Path, tid: uint32, p: array[2, float]) =>
             pth.circle(float32(p[0]), float32(p[1]), circumcenterRadius)
): Path =
  var
    path = newPath()
    c = triangleCircumcenter(d, tid)
  pthproc(path, tid, c)
  return path


proc pathForTriangleCentroids*(
  d: Delaunator,
  pthproc: (var Path, uint32, array[2, float]) -> void =
           (pth: var Path, tid: uint32, p: array[2, float]) =>
             pth.circle(float32(p[0]), float32(p[1]), triCentroidsRadius)
): Path =
  var path = newPath()
  for (tid, _, _, _, _, _, _) in d.iterTriangles:
    let c = triangleCentroid(d, tid)
    pthproc(path, tid, c)
  return path


proc pathForTriangleCentroid*(
  d: Delaunator,
  tid: uint32,
  pthproc: (var Path, uint32, array[2, float]) -> void =
           (pth: var Path, tid: uint32, p: array[2, float]) =>
             pth.circle(float32(p[0]), float32(p[1]), centroidRadius)
): Path =
  var
    path = newPath()
    c = triangleCentroid(d, tid)
  pthproc(path, tid, c)
  return path


proc pathForRegionCentroids*(
  d: Delaunator,
  pthproc: (var Path, uint32, array[2, float]) -> void =
           (pth: var Path, pid: uint32, p: array[2, float]) =>
             pth.circle(float32(p[0]), float32(p[1]), plyCentroidsRadius)
): Path =
  var path = newPath()
  for (pid, verts) in d.iterVoronoiRegions:
    let c = polygonCentroid(verts)
    pthproc(path, pid, c)
  return path


proc pathForRegionCentroid*(
  d: Delaunator,
  pid: uint32,
  pthproc: (var Path, uint32, array[2, float]) -> void =
           (pth: var Path, pid: uint32, p: array[2, float]) =>
             pth.circle(float32(p[0]), float32(p[1]), centroidRadius)
): Path =
  var
    path = newPath()
    (pid, verts) = voronoiRegion(d, pid)
    c = polygonCentroid(verts)
  pthproc(path, pid, c)
  return path


proc pathForHullSites*(
  d: Delaunator,
  pthproc: (var Path, uint32, uint32, array[2, float]) -> void =
           (pth: var Path, hid: uint32, pid: uint32, p: array[2, float]) =>
             pth.circle(float32(p[0]), float32(p[1]), hullSitesRadius)
): Path =
  var path = newPath()
  for (hid, pid, p) in d.iterHullPoints:
    pthproc(path, hid, pid, p)
  return path


proc pathForHullSite*(
  d: Delaunator,
  hid: uint32,
  pthproc: (var Path, uint32, uint32, array[2, float]) -> void =
           (pth: var Path, hid: uint32, pid: uint32, p: array[2, float]) =>
             pth.circle(float32(p[0]), float32(p[1]), hullSiteRadius)
): Path =
  var
    path = newPath()
    pid = d.hull[hid]
    p = [d.coords[2 * pid], d.coords[2 * pid + 1]]
  pthproc(path, hid, pid, p)
  return path


proc pathForHalfedge*(
  d: Delaunator,
  eid: int32,
  pthproc: (var Path, int32, uint32, uint32, array[2, float], array[2, float]) -> void =
           proc (pth: var Path, eid: int32, pid: uint32, qid: uint32, p: array[2, float], q: array[2, float]) =
             pth.moveTo(float32(p[0]), float32(p[1]))
             pth.lineTo(float32(q[0]), float32(q[1]))
             pth.closePath()
): Path =
  var
    path = newPath()
    pid = d.triangles[eid]
    qid = d.triangles[nextHalfedge(eid)]
    p = [d.coords[(2 * pid)], d.coords[(2 * pid + 1)]]
    q = [d.coords[(2 * qid)], d.coords[(2 * qid + 1)]]
  pthproc(path, eid, pid, qid, p, q)
  return path


proc pathsForHalfedgesAroundSite*(
  d: Delaunator,
  pid: uint32,
  pthproc: (var Path, int32, uint32, uint32, array[2, float], array[2, float]) -> void =
           proc (pth: var Path, eid: int32, pid: uint32, qid: uint32, p: array[2, float], q: array[2, float]) =
             pth.moveTo(float32(p[0]), float32(p[1]))
             pth.lineTo(float32(q[0]), float32(q[1]))
             pth.closePath()
): seq[Path] =
  var
    eid = pointToLeftmostHalfedge(d, pid)
    edges = edgeIdsAroundPoint(d, eid)
    paths = newSeqOfCap[Path](edges.len)
  for he in edges:
    paths.add(pathForHalfedge(d, he, pthproc))
  return paths


proc pathForHull*(
  d: Delaunator,
  pthproc: (var Path, uint32, int32, uint32, uint32, array[2, float], array[2, float]) -> void =
           proc (pth: var Path, hid: uint32, eid: int32, pid: uint32, qid: uint32, p: array[2, float], q: array[2, float]) =
             pth.moveTo(float32(p[0]), float32(p[1]))
             pth.lineTo(float32(q[0]), float32(q[1]))
             pth.closePath()
): Path =
  var
    path = newPath()
    epth = newPath()
  for (hid, eid, pid, qid, p, q) in d.iterHullEdges:
    pthproc(epth, hid, eid, pid, qid, p, q)
    path.addPath(epth)
  return path


proc pathForTriangleSites*(
  d: Delaunator,
  tid: uint32,
  pthproc: (var Path, uint32, uint32, uint32, uint32, array[2, float], array[2, float], array[2, float]) -> void =
           proc (pth: var Path, tid: uint32, pid: uint32, qid: uint32, rid: uint32, p: array[2, float], q: array[2, float], r: array[2, float]) =
             pth.circle(float32(p[0]), float32(p[1]), triangleSiteRadius)
             pth.circle(float32(q[0]), float32(q[1]), triangleSiteRadius)
             pth.circle(float32(r[0]), float32(r[1]), triangleSiteRadius)
): Path =
  var
    path = newPath()
    pids = pointIdsOfTriangle(d, tid)
    a = [d.coords[2 * pids[0]], d.coords[2 * pids[0] + 1]]
    b = [d.coords[2 * pids[1]], d.coords[2 * pids[1] + 1]]
    c = [d.coords[2 * pids[2]], d.coords[2 * pids[2] + 1]]
  pthproc(path, tid, pids[0] ,pids[1], pids[2], a, b, c)
  return path


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


proc pathsForTriangles*(
  d: Delaunator,
  pthproc: (var Path, uint32, uint32, uint32, uint32, array[2, float], array[2, float], array[2, float]) -> void =
           proc (pth: var Path, tid: uint32, pid: uint32, qid: uint32, rid: uint32, p: array[2, float], q: array[2, float], r: array[2, float]) =
             pth.moveTo(float32(p[0]), float32(p[1]))
             pth.lineTo(float32(q[0]), float32(q[1]))
             pth.lineTo(float32(r[0]), float32(r[1]))
             pth.closePath()
): seq[Path] =
  var paths = newSeqOfCap[Path](floorDiv(d.triangles.len, 3))
  for (tid, pid, qid, rid, p, q, r) in d.iterTriangles:
    var pth = newPath()
    pthproc(pth, tid, pid, qid, rid, p, q, r)
    paths.add(pth)
  return paths


proc pathForTriangle*(
  d: Delaunator,
  tid: uint32,
  pthproc: (var Path, uint32, uint32, uint32, uint32, array[2, float], array[2, float], array[2, float]) -> void =
           proc (pth: var Path, tid: uint32, pid: uint32, qid: uint32, rid: uint32, p: array[2, float], q: array[2, float], r: array[2, float]) =
             pth.moveTo(float32(p[0]), float32(p[1]))
             pth.lineTo(float32(q[0]), float32(q[1]))
             pth.lineTo(float32(r[0]), float32(r[1]))
             pth.closePath()
): Path =
  var
    path = newPath()
    pids = pointIdsOfTriangle(d, tid)
    a = [d.coords[2 * pids[0]], d.coords[2 * pids[0] + 1]]
    b = [d.coords[2 * pids[1]], d.coords[2 * pids[1] + 1]]
    c = [d.coords[2 * pids[2]], d.coords[2 * pids[2] + 1]]
  pthproc(path, tid, pids[0], pids[1], pids[2], a, b, c)
  return path


proc pathForRegionEdges*(
  d: Delaunator,
  pthproc: (var Path, int32, array[2, float], array[2, float]) -> void =
           proc (pth: var Path, eid: int32, p: array[2, float], q: array[2, float]) =
             pth.moveTo(float32(p[0]), float32(p[1]))
             pth.lineTo(float32(q[0]), float32(q[1]))
             pth.closePath()
): Path =
  var path = newPath()
  for (eid, p, q) in d.iterVoronoiEdges:
    var pth = newPath()
    pthproc(pth, eid, p, q)
    path.addPath(pth)
  return path


proc pathsForRegions*(
  d: Delaunator,
  pthproc: (var Path, uint32, seq[array[2, float]]) -> void =
           proc (pth: var Path, sid: uint32, verts: seq[array[2, float]]) =
             pth.moveTo(float32(verts[0][0]), float32(verts[0][1]))
             for v in verts[1 .. ^1]:
               pth.lineTo(float32(v[0]), float32(v[1]))
             pth.closePath()
): seq[Path] =
  var paths = newSeqOfCap[Path](ashr(d.coords.len, 1))
  for (sid, verts) in d.iterVoronoiRegions:
    var pth = newPath()
    pthproc(pth, sid, verts)
    paths.add(pth)
  return paths


proc pathForRegion*(
  d: Delaunator,
  sid: uint32,
  pthproc: (var Path, uint32, seq[array[2, float]]) -> void =
           proc (pth: var Path, sid: uint32, verts: seq[array[2, float]]) =
             pth.moveTo(float32(verts[0][0]), float32(verts[0][1]))
             for v in verts[1 .. ^1]:
               pth.lineTo(float32(v[0]), float32(v[1]))
             pth.closePath()
): Path =
  var
    path = newPath()
    (sid, verts) = voronoiRegion(d, sid)
  if verts.len != 0:
    pthproc(path, sid, verts)
  return path
