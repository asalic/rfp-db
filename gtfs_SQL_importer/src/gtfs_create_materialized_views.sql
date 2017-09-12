
DROP MATERIALIZED VIEW public.view_shapes_routes;
DROP MATERIALIZED VIEW public.view_gtfs_shapes;
DROP MATERIALIZED VIEW public.view_route_schedule;
DROP  MATERIALIZED VIEW public.view_stops_routes_ids;
DROP MATERIALIZED VIEW public.view_stops_routes;

CREATE MATERIALIZED VIEW public.view_gtfs_shapes AS 
 SELECT gtfs_shapes.shape_id,
    array_agg(gtfs_shapes.shape_pt_lat) AS shape_pt_lat_agg,
    array_agg(gtfs_shapes.shape_pt_lon) AS shape_pt_lon_agg
   FROM gtfs_shapes
  GROUP BY gtfs_shapes.shape_id
WITH DATA;

CREATE MATERIALIZED VIEW public.view_route_schedule AS 
 SELECT trips.trip_id,
    trips.route_id,
    st.stop_id,
    st.stop_sequence,
    st.arrival_time,
    st.departure_time
   FROM gtfs_trips trips
     JOIN gtfs_stop_times st ON trips.trip_id = st.trip_id
  ORDER BY trips.trip_id
WITH DATA;

CREATE MATERIALIZED VIEW public.view_shapes_routes AS 
 SELECT DISTINCT ON (gtfs_trips.route_id, view_gtfs_shapes.shape_id) view_gtfs_shapes.shape_id,
    gtfs_trips.route_id,
    view_gtfs_shapes.shape_pt_lat_agg,
    view_gtfs_shapes.shape_pt_lon_agg
   FROM gtfs_trips
     JOIN view_gtfs_shapes ON view_gtfs_shapes.shape_id = gtfs_trips.shape_id
WITH DATA;

CREATE MATERIALIZED VIEW public.view_stops_routes AS 
 SELECT DISTINCT stops.stop_id,
    routes.route_id
   FROM gtfs_stops stops
     JOIN gtfs_stop_times stoptimes ON stops.stop_id = stoptimes.stop_id
     JOIN gtfs_trips trips ON stoptimes.trip_id = trips.trip_id
     JOIN gtfs_routes routes ON trips.route_id = routes.route_id
  ORDER BY stops.stop_id
WITH DATA;

CREATE MATERIALIZED VIEW public.view_stops_routes_ids AS 
 SELECT stops.stop_id,
    stops.stop_name,
    stops.stop_lat,
    stops.stop_lon,
    array_agg(stops_routes.route_id) AS array_agg
   FROM gtfs_stops stops
     JOIN view_stops_routes stops_routes ON stops.stop_id = stops_routes.stop_id
  GROUP BY stops.stop_id
WITH DATA;


