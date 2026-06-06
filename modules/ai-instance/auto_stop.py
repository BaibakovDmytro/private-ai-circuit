import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    instance_id = os.environ["INSTANCE_ID"]
    region      = os.environ["REGION"]

    ec2 = boto3.client("ec2", region_name=region)

    resp = ec2.describe_instances(InstanceIds=[instance_id])
    state = resp["Reservations"][0]["Instances"][0]["State"]["Name"]

    if state != "running":
        logger.info(f"Instance {instance_id} is already {state}. Skipping.")
        return {"status": "skipped", "state": state}

    ec2.stop_instances(InstanceIds=[instance_id])
    logger.info(f"Stopped instance {instance_id} due to GPU idle alarm.")

    return {"status": "stopped", "instance_id": instance_id}
