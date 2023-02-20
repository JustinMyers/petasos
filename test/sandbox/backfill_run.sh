# ruby node_a/petasos_node_manager.rb
# ruby node_b/petasos_node_manager.rb
# ruby cluster/petasos_cluster_manager.rb

echo "Running in node_a"
cd node_a
ruby -I../../../lib ../../../bin/petasos
echo "Running in node_b"
cd ../node_b
ruby -I../../../lib ../../../bin/petasos
echo "Running in distributor"
cd ../distributor
echo "Copying basic config into place."
cp basic_petasos_distribution-config.yaml petasos_distribution-config.yaml
ruby -I../../../lib ../../../bin/petasos

# Now create the backfill target and rerun
echo "Running in node_c"
cd ../node_c
ruby -I../../../lib ../../../bin/petasos
echo "Running in distributor"
cd ../distributor
echo "Copying backfill config into place."
cp backfill_petasos_distribution-config.yaml petasos_distribution-config.yaml
ruby -I../../../lib ../../../bin/petasos