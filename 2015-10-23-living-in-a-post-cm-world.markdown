---
layout: post
title: "Living in a Post CM World"
date: 2015-10-23 10:50
comments: true
categories: ["devops", "automation"]
---

I've long been a configuration management tool fan. I have blogged, spoken at conferences and used [Puppet]() as well as [Chef]() and [Ansible](). The more I use these tools now, the more I realise I'm actually not making my life any easier

Currently, the infrastructure I manage is 100% AWS Cloud based. This has actually changed how I work:

1. I have learned to always expect problems so I therefore should have *everything* 100% automated.

2. No server is kept in production for more than 2 weeks

By combining these 2 ways of working, I can easily recover from outages. The speed of recovery is down to being able to provision the pieces of my system as fast as possible. The simpliest way to be able to provision instances fast is to build my own AMIs with [Packer](). I have come to the realisation that when I boot an instance, I don't *really* want to wait for a configuration management tool to run. I have also begun to realise that having a tool change my systems in production can introduce unneeded risk. The Packer templates to build the AMI have [serverspec]() tests built into them. This means that at build time, I know if an AMI has been built correctly.

The AWS infrastructure itself is managed by [Terraform](). I tend to use AutoScalingGroups and LaunchConfig for the instances and when Terraform is checking the state of the infrastructure, it will look up the latest AMI ID and make sure that it is part of the Launch Configuration. If it isn't, Terraform will update the Launch Config so that the next machine will be booted from the new AMI.

I use [Rundeck]() for orchestrating changes to the infrastructure. I have a job in Rundeck that allows me to recycle *all* instances in an AutoScalingGroup one at a time and in a HA manner. From building a new AMI, to fully recycling an AutoScalingGroup is about 20 minutes (the packer build itself takes about 12 minutes). So, in theory, it takes me about 20 minutes to release new security patches. 

###Isn't this just 'Golden Images'?

In a way, yes. But the importang for me is being able to roll out a fully tested AMI and then not making any unnecessary changes to it in production. I would like to say that my infrastructure is 100% immutable, but after reading a [recent article]() by <>, I now realise that can never be the case. Each of my AMIs are versioned and I have a nightly Rundeck job that tells me what version of an AMI a system is built / released with.

###Do I Consider Configuration Management Dead?

Not at all. I simply do not want to make unnecessary changes to my environments. Right now, I use Ansible to provision my AMI as part of my Packer scripts. So I do belive these tools still need to be part of our eco-system. I could substitute in any configuration management tool here and the purists could even use bash / shell scripts to do the same job

###Can I only do this if I use *nix / AWS?
Not at all. At $JOB[-1], we actually were changing our provisioning to allow us to spin up images much faster. We were using a mix of AMIs and VMWare templates for Windows and Ubuntu. By moving in that direction, it would reduce the time taken to provision a box from maybe an hour to minutes. 

In my opinion, moving to a more immutable style of infrastructure is the next phase of infra management for me. I believe the learnings from using config management tools in production across 1000s of nodes has helped me move in this direction but YMMV.

