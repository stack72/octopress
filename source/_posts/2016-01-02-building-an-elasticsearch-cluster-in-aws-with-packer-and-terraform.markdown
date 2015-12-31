---
layout: post
title: "Building an ElasticSearch cluster in AWS with Packer and Terraform"
date: 2016-01-02 12:47
comments: true
categories: [aws,automation,elasticsearch,terraform,infrastructure]
---
As discussed in a [previous post](http://www.paulstack.co.uk/blog/2015/11/09/the-quest-for-infra-management-2-dot-0/), I like to build separate [AMIs](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) for each of my systems. This allows me to scale up and recycle nodes easily. I have been doing this with [ElasticSearch](https://www.elastic.co/products/elasticsearch) for a while now. I usually build an AMI with [Packer](https://packer.io/) and [Ansible](http://www.ansible.com/) and I use [Terraform](https://terraform.io/) to roll out the infrastructure

###Building ElasticSearch AMIs with Packer

The packer template looks as follows:

```
{
  "variables": {
    "ami_id": "",
    "private_subnet_id": "",
    "security_group_id": "",
    "packer_build_number": "",
  },
  "description": "ElasticSearch Image",
  "builders": [
    {
      "ami_name": "elasticsearch-{{user `packer_build_number`}}",
      "availability_zone": "eu-west-1a",
      "iam_instance_profile": "app-server",
      "instance_type": "t2.small",
      "region": "eu-west-1",
      "run_tags": {
        "role": "packer"
      },
      "security_group_ids": [
        "{{user `security_group_id`}}"
      ],
      "source_ami": "{{user `ami_id`}}",
      "ssh_timeout": "10m",
      "ssh_username": "ubuntu",
      "subnet_id": "{{user `private_subnet_id`}}",
      "tags": {
        "Name": "elasticsearch-packer-image"
      },
      "type": "amazon-ebs"
    }
  ],
  "provisioners": [
    {
      "type": "shell",
      "inline": [ "sleep 10" ]
    },
    {
      "type": "shell",
      "script": "install_dependencies.sh",
      "execute_command": "echo '' | {{ .Vars }} sudo -E -S sh '{{ .Path }}'"
    },
    {
      "type": "ansible-local",
      "playbook_file": "elasticsearch.yml",
      "extra_arguments": [
        "--module-path=./modules"
      ],
      "playbook_dir": "../../"
    }
  ]
}

```

This is essentially a pretty simple script and builds an AWS Instance in a private subnet of my choice in eu-west-1a in AWS. 

#### install_dependencies.sh

The first part of the script just installs the dependencies that my system has:

```
#!/bin/bash

apt-get update
apt-get upgrade -y
apt-get install -y software-properties-common git
apt-add-repository -y ppa:ansible/ansible apt-get update

# workaround for ubuntu pip bug - https://bugs.launchpad.net/ubuntu/+source/python-pip/+bug/1306991
rm -rf /usr/local/lib/python2.7/dist-packages/requests
apt-get install -y python-dev

ssh-keyscan -H github.com > /etc/ssh/ssh_known_hosts

wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py
python get-pip.py

pip install ansible paramiko PyYAML jinja2 httplib2 netifaces boto awscli six

```

####Ansible playbook for ElasticSearch

The ElasticSearch playbook looks as follows:

```
- hosts: all
  sudo: yes

  pre_tasks:
    - ec2_tags:
    - ec2_facts:

  roles:
    - base
    - elasticsearch
```

The playbook installs a base role for all the base pieces of my system (e.g. Logstash, Sensu-client, prometheus node_exporter) and then proceeds to install ElasticSearch. 

The ElasticSearch role looks as follows:

```
- ec2_facts:
- ec2_tags:

- name: Add Oracle Java Repository
  apt_repository: repo='ppa:webupd8team/java'

- name: Accept Java 8 Licence
  shell: echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | tee /etc/oracle-java-8-licence-acceptance | /usr/bin/debconf-set-selections
  args:
    creates: /etc/oracle-java-8-licence-acceptance

- name: Add ElasticSearch repo public signing key
  apt_key: id=46095ACC8548582C1A2699A9D27D666CD88E42B4 url=https://packages.elastic.co/GPG-KEY-elasticsearch state=present

- name: Add ElasticSearch repository
  apt_repository:
    repo: 'deb http://packages.elasticsearch.org/elasticsearch/{{ es_release }}/debian stable main'
    state: present

- name: Install Oracle Java 8
  apt: name={{item}} state=latest
  with_items:
    - oracle-java8-installer
    - ca-certificates
    - oracle-java8-set-default

- name: Install ElasticSearch
  apt: name=elasticsearch={{ es_version }} state=present
  notify: Restart elasticsearch

- name: Copy /etc/default/elasticsearch
  template: src=elasticsearch dest=/etc/default/elasticsearch
  notify: Restart elasticsearch

- name: Copy /etc/elasticsearch/elasticsearch.yml
  template: src=elasticsearch.yml dest=/etc/elasticsearch/elasticsearch.yml
  notify: Restart elasticsearch

- name: Set elasticsearch service to start on boot
  service: name=elasticsearch enabled=yes

- name: Install plugins
  command: bin/plugin --install {{item.name}}
  args:
    chdir: "{{ es_home }}"
    creates: "{{ es_home }}/plugins/{{ item.plugin_file | default(item.name.split('/')[1]) }}"
  with_items: es_plugins
  notify: Restart elasticsearch

- name: Set elasticsearch to be running
  service: name=elasticsearch state=running enabled=yes

```

This is just some basic ansible commands to get the apt-repo, packages and plugins installed in the system. You can find the templates used [here](https://gist.github.com/stack72/bdef4126ae8b08214bd8). The important part to note is that variables are used both in the script **and** in the templates to setup the cluster to the required level.

My variables look as follows:

```
es_release: "1.6"
es_version: "{{ es_release }}.0"
es_home: /usr/share/elasticsearch
es_wait_for_listen: yes
es_etc:
  cluster_name: central_logging_cluster
  discovery.type: ec2
  discovery.ec2.groups: elasticsearch-sg
  cloud.aws.region: "{{ ansible_ec2_placement_region }}"
es_default_es_heap_size: 4g
es_plugins:
  - name: elasticsearch/elasticsearch-cloud-aws/2.6.0
  - name: elasticsearch/marvel/latest
  - name: mobz/elasticsearch-head
es_etc_index_number_of_replicas: 2
```

As I have specified `elasticsearch-sg` and installed the `elasticsearch-cloud-aws` plugin, my nodes can auto-discover each other in the aws region. I can build the packer image as follows:

```
#!/bin/bash

LATEST_UBUNTU_IMAGE=$(curl http://cloud-images.ubuntu.com/locator/ec2/releasesTable | grep eu-west-1 | grep trusty | grep amd64 | grep "\"hvm:ebs\"" | awk -F "[<>]" '{print $3}')

packer build \
  -var ami_id=$LATEST_UBUNTU_IMAGE \
  -var security_group_id=MYSGID\
  -var private_subnet_id=MYSUBNETID \
  -var packer_build_number=PACKERBUILDNUMBER \
  elasticsearch.json


```

We are now ready to build the infrastructure for the cluster

###Building an ElasticSearch Cluster with Terraform

The infrastructure of the ElasticSearch cluster is now pretty easy. I deploy my nodes into a [VPC](https://aws.amazon.com/vpc/) and onto private subnets so that they are not externally accessible. I have an [ELB](https://aws.amazon.com/elasticloadbalancing/) in place across the nodes so that I can easily get to the ElasticSearch plugins like [Marvel](https://www.elastic.co/guide/en/marvel/current/index.html) and [Head](https://mobz.github.io/elasticsearch-head/).

The Terraform configuration is as follows:  

```
resource "aws_security_group" "elasticsearch" {
  name = "elasticsearch-sg"
  description = "ElasticSearch Security Group"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 9200
    to_port   = 9400
    protocol  = "tcp"
    security_groups = ["${aws_security_group.elasticsearch_elb.id}"]
  }

  ingress {
    from_port = 9200
    to_port   = 9400
    protocol  = "tcp"
    security_groups = ["${aws_security_group.node.id}"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ElasticSearch Node"
  }
}


resource "aws_security_group" "elasticsearch_elb" {
  name = "elasticsearch-elb-sg"
  description = "ElasticSearch Elastic Load Balancer Security Group"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 9200
    to_port   = 9200
    protocol  = "tcp"
    security_groups = ["${aws_security_group.node.id}"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ElasticSearch Load Balancer"
  }
}

resource "aws_elb" "elasticsearch_elb" {
  name = "elasticsearch-elb"
  subnets = ["${aws_subnet.primary-private.id}","${aws_subnet.secondary-private.id}","${aws_subnet.tertiary-private.id}"]
  security_groups = ["${aws_security_group.elasticsearch_elb.id}"]
  cross_zone_load_balancing = true
  connection_draining = true
  internal = true

  listener {
    instance_port      = 9200
    instance_protocol  = "tcp"
    lb_port            = 9200
    lb_protocol        = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    target              = "TCP:9200"
    timeout             = 5
  }
}

resource "aws_autoscaling_group" "elasticsearch_autoscale_group" {
  name = "elasticsearch-autoscale-group"
  availability_zones = ["${aws_subnet.primary-private.availability_zone}","${aws_subnet.secondary-private.availability_zone}","${aws_subnet.tertiary-private.availability_zone}"]
  vpc_zone_identifier = ["${aws_subnet.primary-private.id}","${aws_subnet.secondary-private.id}","${aws_subnet.tertiary-private.id}"]
  launch_configuration = "${aws_launch_configuration.elasticsearch_launch_config.id}"
  min_size = 3
  max_size = 100
  desired = 3
  health_check_grace_period = "900"
  health_check_type = "EC2"
  load_balancers = ["${aws_elb.elasticsearch_elb.name}"]

  tag {
    key = "Name"
    value = "elasticsearch"
    propagate_at_launch = true
  }

  tag {
    key = "role"
    value = "elasticsearch"
    propagate_at_launch = true
  }

  tag {
    key = "elb_name"
    value = "${aws_elb.elasticsearch_elb.name}"
    propagate_at_launch = true
  }

  tag {
    key = "elb_region"
    value = "${var.aws_region}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "elasticsearch_launch_config" {
  image_id = "${var.elasticsearch_ami_id}"
  instance_type = "${var.elasticsearch_instance_type}"
  iam_instance_profile = "app-server"
  key_name = "${aws_key_pair.terraform.key_name}"
  security_groups = ["${aws_security_group.elasticsearch.id}","${aws_security_group.node.id}"]
  enable_monitoring = false

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = "${var.elasticsearch_volume_size}"
  }
}

```

This allows me to scale my system up or down just by changing the values in my Terraform configuration. When the instances are instantiatied, the ElasticSearch cloud plugin discovers the other members of the cluster and allows the node to join the cluster

