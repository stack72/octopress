---
layout: post
title: "Recycling All Instances in an AWS AutoScale Group in a HA Manner"
date: 2016-01-04 14:49
comments: true
categories: 
---
I tend to treat my server infrastructure as [immutable](), therefore, the lifespan of an instance in my AWS farm is usually 14 days from when it has been launched. Each morjing at 0900 UTC, I have written a very crude Python script that (given a region), 
