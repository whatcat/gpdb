-- @Description Ensures that a reindex table during reindex index operations is ok
-- 

DELETE FROM reindex_crtab_aoco_btree WHERE a < 128;
1: BEGIN;
2: BEGIN;
1: REINDEX index idx_reindex_crtab_aoco_btree;
2&: REINDEX TABLE  reindex_crtab_aoco_btree;
1: COMMIT;
2<:
2: COMMIT;
3: select count(*) from reindex_crtab_aoco_btree where a = 1000;
3: set enable_seqscan=false;
3: set enable_indexscan=true;
3: select count(*) from reindex_crtab_aoco_btree where a = 1000;

-- expect to have all the segments update relfilenode twice, one by 'reindex index', and one by 'reindex table'
-- by exposing the invisible rows, we can see the historical updates to the relfilenode of given index
-- aggregate by gp_segment_id and oid can verify total number of updates
-- finally compare total number of segments + master to ensure all segments and master got reindexed twice
3: set gp_select_invisible=on;
3: select relname, sum(relfilenode_updated_count)::int/(select count(*) from gp_segment_configuration where role='p' and xmax=0) as all_segs_reindexed_count from (select oid, relname, (count(relfilenode)-1) as relfilenode_updated_count from (select gp_segment_id, oid, relfilenode, relname from pg_class union all select gp_segment_id, oid, relfilenode, relname from gp_dist_random('pg_class')) all_pg_class where relname = 'idx_reindex_crtab_aoco_btree' group by gp_segment_id, oid, relname) per_seg_filenode_updated group by oid, relname;
3: set gp_select_invisible=off;
