
import std/sugar
import pixie, pixie/paths
import delaunator, delaunator/helpers


#[ TODO:
 use `sid` in place of pid where it reps a site?
 pathForNeighborSites
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


template pathForSites*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  ## Returns a `Path` of all sites of the triangulation. `body` will be evaluated
  ## for each site. Symbols available to `body`:
  ## - `path: Path`: The path being constructed
  ## - `pid: uint32`: The *point* index of the site being considered
  ## - `p: array[2, T]`: The site's point location
  bind pixienator.sitesRadius
  block:
    var path = newPath()
    for (pid, p) in iterPoints(d):
      defaultFor(body):
        path.circle(float32(p[0]), float32(p[1]), sitesRadius)
    path


template pathForSite*(d: Delaunator, siteId: uint32, body: untyped = nil): Path {.dirty.} =
  ## Returns a `Path` of the site specified by `siteId`. `body` will be evaluated
  ## for this site. Symbols available to `body`:
  ## - `path: Path`: The path being constructed
  ## - `pid: uint32`: The *point* index of the site being considered
  ## - `p: array[2, T]`: The site's point location
  bind pixienator.siteRadius
  block:
    var
      path = newPath()
      pid = siteId
      p = [d.coords[2 * pid], d.coords[2 * pid + 1]]
    defaultFor(body):
      path.circle(float32(p[0]), float32(p[1]), siteRadius)
    path


#TODO: use an `iterTriangleIds` instead because most yielded items not needed.
template pathForCircumcenters*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  ## Returns a `Path` of all circumcenters of the triangulation. `body` will be
  ## evaluated for each circumcenter. Symbols available to `body`:
  ## - `path: Path`: The path being constructed
  ## - `tid: uint32`: The *triangles* index of the circumcenter's triangle
  ## - `c: array[2, T]`: The circumcenter's point location
  bind pixienator.circumcentersRadius
  block:
    var path = newPath()
    for (tid, _, _, _, _, _, _) in iterTriangles(d):
      let c = triangleCircumcenter(d, tid)
      defaultFor(body):
        path.circle(float32(c[0]), float32(c[1]), circumcentersRadius)
    path


template pathForCircumcenter*(d: Delaunator, triangleId: uint32, body: untyped = nil): Path {.dirty.} =
  ## Returns a `Path` of the circumcenter constructed from the triangle specified
  ## by `triangleId`. `body` will be evaluated for this circumcenter. Symbols
  ## available to `body`:
  ## - `path: Path`: The path being constructed
  ## - `tid: uint32`: The *triangles* index of the circumcenter's triangle
  ## - `c: array[2, T]`: The circumcenter's point location
  bind pixienator.circumcenterRadius
  block:
    var
      path = newPath()
      tid = triangleId
      c = triangleCircumcenter(d, tid)
    defaultFor(body):
      path.circle(float32(c[0]), float32(c[1]), circumcenterRadius)
    path


#TODO: use an `iterTriangleIds` instead because most yielded items not needed.
template pathForTriangleCentroids*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  ## Returns a `Path` of all triangle centroids of the triangulation. `body`
  ## will be evaluated for each centroid. Symbols available to `body`:
  ## - `path: Path`: The path being constructed
  ## - `tid: uint32`: The *triangles* index of the centroid's triangle
  ## - `c: array[2, T]`: The centroid's point location
  bind pixienator.triCentroidsRadius
  block:
    var path = newPath()
    for (tid, _, _, _, _, _, _) in iterTriangles(d):
      let c = triangleCentroid(d, tid)
      defaultFor(body):
        path.circle(float32(c[0]), float32(c[1]), triCentroidsRadius)
    path


template pathForTriangleCentroid*(d: Delaunator, triangleId: uint32, body: untyped = nil): Path {.dirty.} =
  ## Returns a `Path` of the centroid constructed from the triangle specified
  ## by `triangleId`. `body` will be evaluated for this centroid. Symbols available
  ## to `body`:
  ## - `path: Path`: The path being constructed
  ## - `tid: uint32`: The *triangles* index of the centroid's triangle
  ## - `c: array[2, T]`: The centroid's point location
  bind pixienator.centroidRadius
  block:
    var
      path = newPath()
      tid = triangleId
      c = triangleCentroid(d, tid)
    defaultFor(body):
      path.circle(float32(c[0]), float32(c[1]), centroidRadius)
    path


template pathForRegionCentroids*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  ## Returns a `Path` of all region centroids of the voronoi diagram. `body` will
  ## be evaluated for each centroid. Symbols available to `body`:
  ## - `path: Path`: The path being constructed
  ## - `pid: uint32`: The *point* index of the region's site
  ## - `verts: seq[array[2, T]]`: The points of the region's polygon
  ## - `c: array[2, T]`: The centroid's point location
  bind pixienator.plyCentroidsRadius
  block:
    var path = newPath()
    for (pid, verts) in iterVoronoiRegions(d):
      let c = polygonCentroid(verts)
      defaultFor(body):
        path.circle(float32(c[0]), float32(c[1]), plyCentroidsRadius)
    path


template pathForRegionCentroid*(d: Delaunator, siteId: uint32, body: untyped = nil): Path {.dirty.} =
  ## Returns a `Path` of the region centroid constructed from the site specified
  ## by `siteId`. `body` will be evaluated for this centroid. Symbols available
  ## to `body`:
  ## - `path: Path`: The path being constructed
  ## - `pid: uint32`: The *point* index of the region's site
  ## - `verts: seq[array[2, T]]`: The points of the region's polygon
  ## - `c: array[2, T]`: The centroid's point location
  bind pixienator.centroidRadius
  block:
    var
      path = newPath()
      (pid, verts) = voronoiRegion(d, siteId)
      c = polygonCentroid(verts)
    defaultFor(body):
      path.circle(float32(c[0]), float32(c[1]), centroidRadius)
    path


template pathForHullSites*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  ## Returns a `Path` of all sites on the hull of the triangulation. `body` will
  ## be evaluated for each hull site. Symbols available to `body`:
  ## - `path: Path`: The path being constructed
  ## - `hid: uint32`: The *hull* index of site being considered
  ## - `pid: uint32`: The *point* index of the site being considered
  ## - `p: array[2, T]`: The site's point location
  bind pixienator.hullSitesRadius
  block:
    var path = newPath()
    for (hid, pid, p) in iterHullPoints(d):
      defaultFor(body):
        path.circle(float32(p[0]), float32(p[1]), hullSitesRadius)
    path


template pathForHullSite*(d: Delaunator, hullId: uint32, body: untyped = nil): Path {.dirty.} =
  ## Returns a `Path` of the site on the hull specified by `hullId`. `body` will
  ## be evaluated for this hull site. Symbols available to `body`:
  ## - `path: Path`: The path being constructed
  ## - `hid: uint32`: The *hull* index of site being considered
  ## - `pid: uint32`: The *point* index of the site being considered
  ## - `p: array[2, T]`: The site's point location
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


template pathForHalfedge*(d: Delaunator, edgeId: int32, body: untyped = nil): Path {.dirty.} =
  ## Returns a `Path` of the halfedge specified by `edgeId`. `body` will be
  ## evaluated for this halfedge. Symbols available to `body`:
  ## - `path: Path`: The path being constructed
  ## - `eid: int32`: The *halfedges* index of halfedge being considered
  ## - `pid: uint32`: The *point* index of the site where the halfedge starts
  ## - `qid: uint32`: The *point* index of the site where the halfedge ends
  ## - `p: array[2, T]`: The halfedge's starting point location
  ## - `q: array[2, T]`: The halfedge's ending point location
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


# TODO: OPT: qid is always sid
template pathsForHalfedgesAroundSite*(d: Delaunator, siteId: uint32, body: untyped = nil): seq[Path] {.dirty.} =
  ## Returns a `seq[Path]` of all halfedges leading to the site specified by
  ## `siteId`. `body` will be evaluated for each halfedge. Symbols available
  ## to `body`:
  ## - `path: Path`: The path being constructed
  ## - `sid: uint32`: The *point* index of the site being considered
  ## - `eid: int32`: The *halfedges* index of halfedge being considered
  ## - `pid: uint32`: The *point* index of the site where the halfedge starts
  ## - `qid: uint32`: The *point* index of the site where the halfedge ends
  ## - `p: array[2, T]`: The halfedge's starting point location
  ## - `q: array[2, T]`: The halfedge's ending point location
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
    for (hid, eid, pid, qid, p, q) in iterHullEdges(d):
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
    for (tid, eid, pid, qid, p, q) in iterTriangleEdges(d):
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
    for (tid, pid, qid, rid, p, q, r) in iterTriangles(d):
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
    for (eid, p, q) in iterVoronoiEdges(d):
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
    for (sid, verts) in iterVoronoiRegions(d):
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

template pathForExtents*(d: Delaunator, body: untyped = nil): Path {.dirty.} =
  block:
    var
      path = newPath()
      minX = d.minX
      minY = d.minY
      maxX = d.maxX
      maxY = d.maxY
      x = minX
      y = minY
      w = maxX - minX
      h = maxY - minY
    defaultFor(body):
      path.rect(x, y, w, h)
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
