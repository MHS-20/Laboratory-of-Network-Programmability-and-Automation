sudo ip -all netns delete
sudo ovs-vsctl del-br SW1
sudo ovs-vsctl -- --all destroy Bridge
sudo ovs-vsctl -- --all destroy Port  
sudo ovs-vsctl -- --all destroy Interface