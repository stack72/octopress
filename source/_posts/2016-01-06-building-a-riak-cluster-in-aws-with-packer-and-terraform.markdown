---
layout: post
title: "Building a Riak Cluster in AWS with Packer and Terraform"
date: 2016-01-06 15:02
comments: true
categories: [aws,infrastructure,automation,riak,packer,terraform]
---
Following my [pattern](http://www.paulstack.co.uk/blog/2016/01/02/building-an-elasticsearch-cluster-in-aws-with-packer-and-terraform/) of building [AMIs](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) for applications, I create my [riak](http://basho.com/products/riak-kv/) cluster with [Packer](https://packer.io/) for my AMI and [Terraform](https://terraform.io/) for the infrastructure

###Building Riak AMIs with Packer 

{% raw %}
```json
{
  "variables": {
    "ami_id": "",
    "private_subnet_id": "",
    "security_group_id": "",
    "packer_build_number": "",
  },
  "description": "Riak Image",
  "builders": [
    {
      "ami_name": "riak-{{user `packer_build_number`}}",
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
        "Name": "riak-packer-image"
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
      "playbook_file": "riak.yml",
      "extra_arguments": [
        "--module-path=./modules"
      ],
      "playbook_dir": "../../"
    }
  ]
}
```
{% endraw %}

The install_dependencies.sh script is as described [previously](http://www.paulstack.co.uk/blog/2016/01/02/building-an-elasticsearch-cluster-in-aws-with-packer-and-terraform/)

The ansible playbook for Riak looks as follows:

{% raw %}
```yaml
- hosts: all
  sudo: yes

  pre_tasks:
    - ec2_tags:
    - ec2_facts:

  roles:
    - base
    - riak
```
{% endraw %}

The playbook installs a base role for all the base pieces of my system (e.g. Logstash, Sensu-client, prometheus node_exporter) and then proceeds to install riak.

The riak ansible role looks as follows:

{% raw %}
```yaml
- action: apt_key url={{ riak_key_url }} state=present

- action: apt_repository repo='{{ riak_deb_repo }}' state=present update_cache=yes

- apt: name=riak={{ riak_version }} state=present update_cache=yes

- name: set ulimit
  copy: src=etc-default-riak dest=/etc/default/riak owner=root group=root mode=0644

- name: template riak configuration
  template: src=riak.j2 dest=/etc/riak/riak.conf owner=riak mode=0644
  register: restart_riak

- name: restart riak
  service: name=riak state=started
```
{% endraw %}

The role itself is very simple. The riak cluster settings are all held in the [riak.j2](https://gist.github.com/stack72/e0df60305aff136cb81c) template file. Notice that the riak template has the following line in it:

```
riak_control = on
```

The variables for the riak playbook look as follows:

```
riak_key_url: "https://packagecloud.io/gpg.key"
riak_deb_repo: "deb https://packagecloud.io/basho/riak/ubuntu/ trusty main"
riak_version: 2.1.1-1
``` 

###Deploying Riak with Terraform

The infrastructure of the Riak cluster is pretty simple:

{% raw %}
```
resource "aws_elb" "riak_v2_elb" {
  name = "riak-elb-v2"
  subnets = ["${aws_subnet.primary-private.id}","${aws_subnet.secondary-private.id}","${aws_subnet.tertiary-private.id}"]
  security_groups = ["${aws_security_group.riak_elb.id}"]
  cross_zone_load_balancing = true
  connection_draining = true
  internal = true

  listener {
    instance_port      = 8098
    instance_protocol  = "tcp"
    lb_port            = 8098
    lb_protocol        = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    target              = "HTTP:8098/ping"
    timeout             = 5
  }
}

resource "aws_security_group" "riak" {
  name = "riak-sg"
  description = "Riak Security Group"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 8098
    to_port   = 8098
    protocol  = "tcp"
    security_groups = ["${aws_security_group.riak_elb.id}"]
  }

  ingress {
    from_port = 8098
    to_port   = 8098
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Riak Node"
  }
}

resource "aws_security_group_rule" "riak_all_tcp" {
    type = "ingress"
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_group_id = "${aws_security_group.riak.id}"
    source_security_group_id = "${aws_security_group.riak.id}"
}

resource "aws_security_group" "riak_elb" {
  name = "riak-elb-sg"
  description = "Riak Elastic Load Balancer Security Group"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 8098
    to_port   = 8098
    protocol  = "tcp"
    security_groups = ["${aws_security_group.node.id}"]
  }

  ingress {
    from_port = 8098
    to_port   = 8098
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Riak Load Balancer"
  }
}

resource "aws_autoscaling_group" "riak_v2_autoscale_group" {
  name = "riak-v2-autoscale-group"
  availability_zones = ["${aws_subnet.primary-private.availability_zone}","${aws_subnet.secondary-private.availability_zone}","${aws_subnet.tertiary-private.availability_zone}"]
  vpc_zone_identifier = ["${aws_subnet.primary-private.id}","${aws_subnet.secondary-private.id}","${aws_subnet.tertiary-private.id}"]
  launch_configuration = "${aws_launch_configuration.riak_launch_config.id}"
  min_size = 0
  max_size = 100
  health_check_type = "EC2"

  tag {
    key = "Name"
    value = "riak"
    propagate_at_launch = true
  }

  tag {
    key = "role"
    value = "riak"
    propagate_at_launch = true
  }

  tag {
    key = "elb_name"
    value = "${aws_elb.riak_v2_elb.name}"
    propagate_at_launch = true
  }

  tag {
    key = "elb_region"
    value = "${var.aws_region}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "riak_launch_config" {
  image_id = "${var.riak_ami_id}"
  instance_type = "${var.riak_instance_type}"
  iam_instance_profile = "app-server"
  key_name = "${aws_key_pair.terraform.key_name}"
  security_groups = ["${aws_security_group.riak.id}","${aws_security_group.node.id}"]
  enable_monitoring = false

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = "${var.driak_volume_size}"
  }
}

```
{% endraw %}
