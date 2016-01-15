---
layout: post
title: "Replacing a node in a Riak Cluster"
date: 2016-01-15 11:03
comments: true
categories: [aws,infrastructure,riak]
---
The instances that run in my infrastructure get a lifespan of 14 days. This allows me to continually test that I can replace my environment at any point. People always ask me if I follow the same principal for data nodes. I posted [previously](http://www.paulstack.co.uk/blog/2016/01/04/replacing-the-nodes-in-an-aws-elasticsearch-cluster/) about replacing nodes is an [ElasticSearch](https://www.elastic.co/products/elasticsearch) cluster, this post will detail how I replace  nodes in a [Riak](http://basho.com/products/riak-kv/) cluster 

**_NOTE_**: This post assumes that you have the [Riak Control console](http://docs.basho.com/riak/latest/ops/advanced/riak-control/) enabled for Riak. You can find out how to enable that in the [post](http://www.paulstack.co.uk/blog/2016/01/06/building-a-riak-cluster-in-aws-with-packer-and-terraform/) I wrote on configuring Riak.

When going to the Riak Control, you can find the following screens:

*Cluster Health*

![Image](/images/riak-control-cluster-health.png)

*Ring Status*

![Image](/images/riak-control-ring-status.png)

*Cluster Management* 

![Image](/images/riak-control-cluster-mgmt.png)

*Node Management*

![Image](/images/riak-control-node-mgmt.png)

###Removing a node from the Cluster

In order to remove a node from the cluster, go to the cluster managemenet screen. Find the node you want to replace in the list and click on the `Actions` toggle. It will reveal actions as follows:

![Image](/images/riak-control-cluster-node-options.png)

As the node is currently running, I tend to chose the `Allow this node to leave normally` option (if the node had died or was unresponsive, I would usually chose the `force this node to leave`). Clicking on the `Stage` button, details a plan of what is going to happen:

![Image](/images/riak-control-remove-node.png)

If the proposed changes look good, `Commit` the plan. Watch the partitions drain from the node to be replaced:

![Image](/images/riak-control-node-draining.png)

When the all the partitions have drained, we now have a 2 node cluster where the partitons are split 50:50:

![Image](/images/riak-control-smaller-cluster.png)

We can now destroy the node and let the [autoscaling group](https://aws.amazon.com/autoscaling/) launch another to replace it

###Adding a new node to the Cluster

Assuming a new node has already been launched and is ready to go into the cluster. Go to the cluster management page in the portal and enter new node details. It should follow the format `riak@<ipaddress>`

![Image](/images/riak-control-add-new-node.png)

The list of actions that are pending on the cluster:

![Image](/images/riak-control-stage-new-node.png)

`Commit` the changes, watch the partions rebalance across the cluster:

![Image](/images/riak-control-cluster-rebalance.png)

The cluster will return to being 3 nodes, with equal partition split and will then show as green again

![Image](/images/riak-control-green-cluster.png)
