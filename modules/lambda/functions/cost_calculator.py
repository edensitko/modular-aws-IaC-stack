import json
import boto3
import os
import datetime
import requests
from decimal import Decimal

# Initialize AWS clients
ce_client = boto3.client('ce')  # Cost Explorer client
ec2_client = boto3.client('ec2')
rds_client = boto3.client('rds')
lambda_client = boto3.client('lambda')
s3_client = boto3.client('s3')
elb_client = boto3.client('elbv2')  # For ALB/NLB
autoscaling_client = boto3.client('autoscaling')  # For ASG
cloudwatch_client = boto3.client('cloudwatch')  # For CloudWatch
vpc_client = boto3.client('ec2')  # For VPC resources (using EC2 client)

# Helper class to handle Decimal serialization for JSON
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def get_cost_and_usage(start_date, end_date):
    """Get cost and usage data from AWS Cost Explorer"""
    try:
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date,
                'End': end_date
            },
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[
                {
                    'Type': 'DIMENSION',
                    'Key': 'SERVICE'
                }
            ]
        )
        return response
    except Exception as e:
        print(f"Error getting cost data: {str(e)}")
        return None

def get_ec2_resources():
    """Get EC2 instance information"""
    try:
        response = ec2_client.describe_instances()
        instances = []
        
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_type = instance['InstanceType']
                state = instance['State']['Name']
                instance_id = instance['InstanceId']
                
                # Get instance name if it exists
                name = "Unnamed"
                if 'Tags' in instance:
                    for tag in instance['Tags']:
                        if tag['Key'] == 'Name':
                            name = tag['Value']
                            break
                
                instances.append({
                    'id': instance_id,
                    'name': name,
                    'type': instance_type,
                    'state': state
                })
        
        return instances
    except Exception as e:
        print(f"Error getting EC2 resources: {str(e)}")
        return []

def get_rds_resources():
    """Get RDS instance information"""
    try:
        response = rds_client.describe_db_instances()
        instances = []
        
        for instance in response['DBInstances']:
            instances.append({
                'id': instance['DBInstanceIdentifier'],
                'engine': instance['Engine'],
                'class': instance['DBInstanceClass'],
                'storage': instance['AllocatedStorage']
            })
        
        return instances
    except Exception as e:
        print(f"Error getting RDS resources: {str(e)}")
        return []

def get_lambda_resources():
    """Get Lambda function information"""
    try:
        response = lambda_client.list_functions()
        functions = []
        
        for function in response['Functions']:
            functions.append({
                'name': function['FunctionName'],
                'runtime': function['Runtime'],
                'memory': function['MemorySize'],
                'timeout': function['Timeout']
            })
        
        return functions
    except Exception as e:
        print(f"Error getting Lambda resources: {str(e)}")
        return []

def get_s3_resources():
    """Get S3 bucket information"""
    try:
        response = s3_client.list_buckets()
        buckets = []
        
        for bucket in response['Buckets']:
            name = bucket['Name']
            # Get bucket size - this requires additional API calls
            try:
                size = 0
                objects = s3_client.list_objects_v2(Bucket=name)
                if 'Contents' in objects:
                    for obj in objects['Contents']:
                        size += obj['Size']
                
                buckets.append({
                    'name': name,
                    'size_bytes': size,
                    'size_mb': round(size / (1024 * 1024), 2)
                })
            except Exception as e:
                print(f"Error getting size for bucket {name}: {str(e)}")
                buckets.append({
                    'name': name,
                    'size_bytes': 0,
                    'size_mb': 0
                })
        
        return buckets
    except Exception as e:
        print(f"Error getting S3 resources: {str(e)}")
        return []

def get_vpc_resources():
    """Get VPC and related resources information"""
    try:
        # Get VPCs
        vpc_response = vpc_client.describe_vpcs()
        vpcs = []
        
        for vpc in vpc_response['Vpcs']:
            vpc_id = vpc['VpcId']
            vpc_name = "Unnamed"
            if 'Tags' in vpc:
                for tag in vpc['Tags']:
                    if tag['Key'] == 'Name':
                        vpc_name = tag['Value']
                        break
            
            # Get subnets for this VPC
            subnet_response = vpc_client.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
            subnets = []
            for subnet in subnet_response['Subnets']:
                subnet_name = "Unnamed"
                if 'Tags' in subnet:
                    for tag in subnet['Tags']:
                        if tag['Key'] == 'Name':
                            subnet_name = tag['Value']
                            break
                            
                subnets.append({
                    'id': subnet['SubnetId'],
                    'name': subnet_name,
                    'cidr': subnet['CidrBlock'],
                    'az': subnet['AvailabilityZone'],
                    'public': subnet.get('MapPublicIpOnLaunch', False)
                })
            
            # Get route tables for this VPC
            rt_response = vpc_client.describe_route_tables(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
            route_tables = []
            for rt in rt_response['RouteTables']:
                rt_name = "Unnamed"
                if 'Tags' in rt:
                    for tag in rt['Tags']:
                        if tag['Key'] == 'Name':
                            rt_name = tag['Value']
                            break
                            
                route_tables.append({
                    'id': rt['RouteTableId'],
                    'name': rt_name,
                    'routes_count': len(rt['Routes'])
                })
            
            vpcs.append({
                'id': vpc_id,
                'name': vpc_name,
                'cidr': vpc['CidrBlock'],
                'subnets': subnets,
                'route_tables': route_tables
            })
        
        return vpcs
    except Exception as e:
        print(f"Error getting VPC resources: {str(e)}")
        return []

def get_igw_resources():
    """Get Internet Gateway information"""
    try:
        response = vpc_client.describe_internet_gateways()
        igws = []
        
        for igw in response['InternetGateways']:
            igw_id = igw['InternetGatewayId']
            igw_name = "Unnamed"
            vpc_id = "Not attached"
            
            if 'Tags' in igw:
                for tag in igw['Tags']:
                    if tag['Key'] == 'Name':
                        igw_name = tag['Value']
                        break
            
            if 'Attachments' in igw and len(igw['Attachments']) > 0:
                vpc_id = igw['Attachments'][0]['VpcId']
            
            igws.append({
                'id': igw_id,
                'name': igw_name,
                'vpc_id': vpc_id
            })
        
        return igws
    except Exception as e:
        print(f"Error getting IGW resources: {str(e)}")
        return []

def get_security_group_resources():
    """Get Security Group information"""
    try:
        response = vpc_client.describe_security_groups()
        sgs = []
        
        for sg in response['SecurityGroups']:
            sg_id = sg['GroupId']
            sg_name = sg['GroupName']
            vpc_id = sg['VpcId']
            
            sgs.append({
                'id': sg_id,
                'name': sg_name,
                'vpc_id': vpc_id,
                'inbound_rules': len(sg['IpPermissions']),
                'outbound_rules': len(sg['IpPermissionsEgress'])
            })
        
        return sgs
    except Exception as e:
        print(f"Error getting Security Group resources: {str(e)}")
        return []

def get_alb_resources():
    """Get ALB/NLB information"""
    try:
        response = elb_client.describe_load_balancers()
        lbs = []
        
        for lb in response['LoadBalancers']:
            lb_arn = lb['LoadBalancerArn']
            lb_name = lb['LoadBalancerName']
            lb_type = lb['Type']  # 'application' or 'network'
            lb_dns = lb['DNSName']
            
            # Get tags
            tags_response = elb_client.describe_tags(ResourceArns=[lb_arn])
            tags = {}
            if 'TagDescriptions' in tags_response and len(tags_response['TagDescriptions']) > 0:
                for tag in tags_response['TagDescriptions'][0]['Tags']:
                    tags[tag['Key']] = tag['Value']
            
            # Get target groups
            tg_response = elb_client.describe_target_groups(LoadBalancerArn=lb_arn)
            target_groups = []
            for tg in tg_response['TargetGroups']:
                target_groups.append({
                    'name': tg['TargetGroupName'],
                    'protocol': tg['Protocol'],
                    'port': tg['Port'],
                    'target_type': tg['TargetType']
                })
            
            lbs.append({
                'name': lb_name,
                'arn': lb_arn,
                'type': lb_type,
                'dns_name': lb_dns,
                'vpc_id': lb['VpcId'],
                'scheme': lb['Scheme'],
                'tags': tags,
                'target_groups': target_groups
            })
        
        return lbs
    except Exception as e:
        print(f"Error getting ALB/NLB resources: {str(e)}")
        return []

def get_asg_resources():
    """Get Auto Scaling Group information"""
    try:
        response = autoscaling_client.describe_auto_scaling_groups()
        asgs = []
        
        for asg in response['AutoScalingGroups']:
            asg_name = asg['AutoScalingGroupName']
            
            # Get launch template or configuration
            launch_config = "None"
            launch_template = "None"
            if 'LaunchConfigurationName' in asg:
                launch_config = asg['LaunchConfigurationName']
            elif 'LaunchTemplate' in asg:
                launch_template = f"{asg['LaunchTemplate']['LaunchTemplateName']} (v{asg['LaunchTemplate']['Version']})"
            
            # Get instances
            instances = []
            for instance in asg['Instances']:
                instances.append({
                    'id': instance['InstanceId'],
                    'health': instance['HealthStatus'],
                    'lifecycle': instance['LifecycleState'],
                    'az': instance['AvailabilityZone']
                })
            
            asgs.append({
                'name': asg_name,
                'min_size': asg['MinSize'],
                'max_size': asg['MaxSize'],
                'desired_capacity': asg['DesiredCapacity'],
                'launch_config': launch_config,
                'launch_template': launch_template,
                'instances': instances,
                'instance_count': len(asg['Instances'])
            })
        
        return asgs
    except Exception as e:
        print(f"Error getting ASG resources: {str(e)}")
        return []

def get_cloudwatch_resources():
    """Get CloudWatch alarms and dashboards"""
    try:
        # Get alarms
        alarm_response = cloudwatch_client.describe_alarms()
        alarms = []
        
        for alarm in alarm_response['MetricAlarms']:
            alarms.append({
                'name': alarm['AlarmName'],
                'description': alarm.get('AlarmDescription', 'No description'),
                'state': alarm['StateValue'],
                'metric': alarm['MetricName'],
                'namespace': alarm['Namespace']
            })
        
        # Get dashboards
        dashboard_response = cloudwatch_client.list_dashboards()
        dashboards = []
        
        for dashboard in dashboard_response['DashboardEntries']:
            dashboards.append({
                'name': dashboard['DashboardName'],
                'arn': dashboard['DashboardArn']
            })
        
        return {
            'alarms': alarms,
            'dashboards': dashboards
        }
    except Exception as e:
        print(f"Error getting CloudWatch resources: {str(e)}")
        return {'alarms': [], 'dashboards': []}

def get_key_pair_resources():
    """Get EC2 Key Pair information"""
    try:
        response = ec2_client.describe_key_pairs()
        key_pairs = []
        
        for key in response['KeyPairs']:
            key_pairs.append({
                'name': key['KeyName'],
                'fingerprint': key['KeyFingerprint'],
                'type': key.get('KeyType', 'rsa')
            })
        
        return key_pairs
    except Exception as e:
        print(f"Error getting Key Pair resources: {str(e)}")
        return []

def estimate_monthly_cost(daily_cost):
    """Estimate monthly cost based on daily cost"""
    return daily_cost * 30

def send_notification(payload, webhook_url):
    """Send notification to webhook"""
    try:
        response = requests.post(
            webhook_url,
            headers={'Content-Type': 'application/json'},
            data=json.dumps(payload, cls=DecimalEncoder)
        )
        return response.status_code == 200
    except Exception as e:
        print(f"Error sending notification: {str(e)}")
        return False

def lambda_handler(event, context):
    """Lambda function handler"""
    try:
        # Get the current date and yesterday's date
        today = datetime.datetime.now()
        yesterday = today - datetime.timedelta(days=1)
        start_date = yesterday.strftime('%Y-%m-%d')
        
        # Get cost data from Cost Explorer
        cost_data = get_cost_and_usage(start_date, start_date)
        
        # Get resource information for all modules
        ec2_resources = get_ec2_resources()
        rds_resources = get_rds_resources()
        lambda_resources = get_lambda_resources()
        s3_resources = get_s3_resources()
        vpc_resources = get_vpc_resources()
        igw_resources = get_igw_resources()
        sg_resources = get_security_group_resources()
        alb_resources = get_alb_resources()
        asg_resources = get_asg_resources()
        cloudwatch_resources = get_cloudwatch_resources()
        key_pair_resources = get_key_pair_resources()
        
        # Calculate total cost
        total_cost = 0
        service_costs = {}
        
        if cost_data and 'ResultsByTime' in cost_data:
            for result in cost_data['ResultsByTime']:
                for group in result['Groups']:
                    service = group['Keys'][0]
                    amount = float(group['Metrics']['UnblendedCost']['Amount'])
                    service_costs[service] = amount
                    total_cost += amount
        
        # Estimate monthly cost
        estimated_monthly_cost = estimate_monthly_cost(total_cost)
        
        # Count resources by module
        module_resource_counts = {
            "vpc": len(vpc_resources),
            "security_groups": len(sg_resources),
            "igw": len(igw_resources),
            "alb": len(alb_resources),
            "asg": len(asg_resources),
            "ec2": len(ec2_resources),
            "rds": len(rds_resources),
            "lambda": len(lambda_resources),
            "s3": len(s3_resources),
            "key_pairs": len(key_pair_resources),
            "cloudwatch_alarms": len(cloudwatch_resources.get('alarms', [])),
            "cloudwatch_dashboards": len(cloudwatch_resources.get('dashboards', []))
        }
        
        # Get webhook URLs from environment variables or event
        discord_webhook_url = event.get('discord_webhook_url', os.environ.get('DISCORD_WEBHOOK_URL', ''))
        slack_webhook_url = event.get('slack_webhook_url', os.environ.get('SLACK_WEBHOOK_URL', ''))
        telegram_api_url = event.get('telegram_api_url', os.environ.get('TELEGRAM_API_URL', ''))
        
        # Additional metadata from event
        repo = event.get('repo', os.environ.get('REPO', 'Unknown'))
        env_name = event.get('env_name', os.environ.get('ENV_NAME', 'Unknown'))
        actor = event.get('actor', os.environ.get('ACTOR', 'Unknown'))
        server_dns = event.get('server_dns', os.environ.get('SERVER_DNS', 'Unknown'))
        current_time = event.get('time', datetime.datetime.now().isoformat())
        
        # Prepare notification payload with all module resources
        notification_payload = {
            "status": "success",
            "message": "resource-cost-analysis",
            "repo": repo,
            "env_name": env_name,
            "actor": actor,
            "server_dns": server_dns,
            "time": current_time,
            "cost_analysis": {
                "date": start_date,
                "total_daily_cost": total_cost,
                "estimated_monthly_cost": estimated_monthly_cost,
                "service_costs": service_costs,
                "module_resource_counts": module_resource_counts,
                "resources": {
                    "ec2": ec2_resources,
                    "rds": rds_resources,
                    "lambda": lambda_resources,
                    "s3": s3_resources,
                    "vpc": vpc_resources,
                    "internet_gateways": igw_resources,
                    "security_groups": sg_resources,
                    "load_balancers": alb_resources,
                    "auto_scaling_groups": asg_resources,
                    "cloudwatch": cloudwatch_resources,
                    "key_pairs": key_pair_resources
                }
            }
        }
        
        # Send notifications
        notification_results = {}
        
        if discord_webhook_url:
            notification_results['discord'] = send_notification(notification_payload, discord_webhook_url)
        
        if slack_webhook_url:
            notification_results['slack'] = send_notification(notification_payload, slack_webhook_url)
        
        if telegram_api_url:
            notification_results['telegram'] = send_notification(notification_payload, telegram_api_url)
        
        # Return the results
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Cost analysis completed',
                'date': start_date,
                'total_daily_cost': total_cost,
                'estimated_monthly_cost': estimated_monthly_cost,
                'notification_results': notification_results
            }, cls=DecimalEncoder)
        }
    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': f"Error: {str(e)}"
            })
        }