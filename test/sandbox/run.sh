# ruby node_a/petasos_node_manager.rb
# ruby node_b/petasos_node_manager.rb
# ruby cluster/petasos_cluster_manager.rb

echo "Running in node_a"
cd node_a
ruby -I../../../lib ../../../bin/petasos
echo "Running in node_b"
cd ../node_b
ruby -I../../../lib ../../../bin/petasos