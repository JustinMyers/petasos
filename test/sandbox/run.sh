# ruby node_a/petasos_node_manager.rb
# ruby node_b/petasos_node_manager.rb
# ruby cluster/petasos_cluster_manager.rb

# echo "RUNNER: Running in node_a"
# cd node_a
# ruby -I../../../lib ../../../bin/petasos
# echo "RUNNER: Running in node_b"
# cd ../node_b
# ruby -I../../../lib ../../../bin/petasos
echo "RUNNER: Running in distributor"
cd distributor
echo "RUNNER: Copying basic config into place."
cp basic_petasos_distribution-config.yaml petasos_distribution-config.yaml
ruby -I../../../lib ../../../bin/petasos
