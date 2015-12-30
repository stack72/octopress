---
layout: post
title: "Autoscaling Group Notifications with Terraform and AWS Lambda"
date: 2015-12-30 13:51
comments: true
categories: [AWS,Terraform,automation,infrastructure]
---
I use Autoscaling Groups in AWS for all of my systems. The main benefit for me here was to make sure that when a node died in AWS, the Autoscaling Group policy made sure that the node was replaced. I wanted to get some visibility of when the Autoscaling Group was launching and terminating nodes and decided that posting notifications to [Slack](https://slack.com/) would be a good way of getting this. With [Terraform](https://terraform.io/) and [AWS Lambda](http://docs.aws.amazon.com/lambda/latest/dg/welcome.html), I was able to make this happen.

**This post assumes that you are already setup and running with Terraform**

Create an IAM Role that allows access to AWS Lambda:

```
resource "aws_iam_role" "slack_iam_lambda" {
    name = "slack-iam-lambda"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
```

Create a [lambda function](GIST GOES HERE) as follows:

```
resource "aws_lambda_function" "slack_notify" {
  filename = "slackNotify.zip"
  function_name = "slackNotify"
  role = "${aws_iam_role.slack_iam_lambda.arn}"
  handler = "slackNotify.handler"
}
```

We assume here, that you have already created a Slack Integration. The hook URL from that integration is required for the lambda contents. 

The filename `slackNotify.zip` is a zip of a file called `slackNotify.js`. The contents of that js file are [available](https://gist.github.com/stack72/ad97da2df376754e413a)

Terraform currently does not support hooking AWS Lambda up to SNS Event Sources. Therefore, unfortunately, there is a manual step required to configure the Lambda to talk to the SNS Topic. There is a PR in Terraform to allow this to be automated as well.

In the AWS Console, go to Lambda and then chose the Lambda function. 

![Image](/images/lambda_function.png)

Go to the `Event Sources` tab:

![Image](/images/lambda_function_event_sources.png)

Click on `Add Event Source` and then choose `SNS` from the dropdown and then make sure you chose the correct SNS Topic name:

![Image](/images/lambda_function_sns_topic.png)

We then use another Terraform resource to attach the Autoscale Groups to the Lambda as follows:

```
resource "aws_autoscaling_notification" "slack_notifications" {
  group_names = [
    "admin-api-autoscale-group",
    "rundeck-autoscale-group",
  ]
  notifications  = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
    "autoscaling:TEST_NOTIFICATION"
  ]
  topic_arn = "${aws_sns_topic.asg_slack_notifications.arn}"
}
```

As we have configured notifications for autoscaling:TEST_NOTIFICATION, when you apply this configuration with Terraform, you will see something similar to the following in Slack:

![Image](/images/slack_test_notification.png)

In the current infrastructure I manage, there are 27 Autoscale groups. I don't really want to add 27 hardcoded group_names in the aws_autoscaling_notifcation in Terraform. 

I wanted to take advantage of a [Terraform module](https://www.terraform.io/docs/modules/usage.html). In a nutshell, the module does a lookup of all the Autoscaling Groups in a region and then passes that list into the Terraform resource.

The output of the [module](https://github.com/stack72/tf_aws_autoscalegroup_names) looks as follows:

```
{
  "variable": {
    "autoscalegroup_names": {
      "description": "List of autoscalegroup names for a region",
      "default": {
        "eu-west-1": "admin-api-autoscale-group,dash-autoscale-group,demo-autoscale-group,docker-v2-autoscale-group,elasticsearch-autoscale-group,faces-autoscale-group,internal-api-autoscale-group,jenkins-master-autoscale-group,kafka-autoscale-group,landscapes-autoscale-group",
        "ap-southeast-1": "",
        "ap-southeast-2": "",
        "eu-central-1": "",
        "ap-northeast-1": "",
        "us-east-1": "",
        "sa-east-1": "",
        "us-west-1": "",
        "us-west-2": ""
      }
    }
  }
}
```

I then pass this into the Terraform resource as follows:

```
module "autoscalegroups" {
  source = "github.com/stack72/tf_aws_autoscalegroup_names"
  region = "${var.aws_region}"
}

resource "aws_autoscaling_notification" "slack_notifications" {
  group_names = [
    "${split(",", module.autoscalegroups.asg_names)}",
  ]
  notifications  = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
    "autoscaling:TEST_NOTIFICATION"
  ]
  topic_arn = "${aws_sns_topic.asg_slack_notifications.arn}"
}
```

When anything happens within an Autoscaling Group, I now get notifications as follows:

![Image](/images/termination_notification.png)
![Image](/images/launch_notification.png)
