from flask import Flask
import time
import boto3

REGION_NAME = 'us-east-1'



INSTANCE_ID = bo

app = Flask(_name_)

@app.route('/tags')
def get_instance_name(fid):
    instance_tags = []
    # When given an instance ID as str e.g. 'i-1234567', return the instance 'Name' from the name tag.
    ec2 = boto3.resource('ec2')
    ec2instance = ec2.Instance(fid)
    instancename = ''
    instance_owner = ''
    for tags in ec2instance.tags:
        if tags["Key"] == 'Name':
            instancename = tags["Value"]
            instance_tags.append("Name: %s", instancename)

    # return instancename
    for tags in ec2instance.tags:
        if tags["Key"] == 'Owner':
            instance_owner = tags["Value"]
            instance_tags.append("Owner: %s", instance_owner)

@app.route('/shutdown')
def stop_ec2():
    ec2 = boto3.client('ec2', region_name=REGION_NAME)
    ec2.stop_instances(InstanceIds=[INSTANCE_ID])

    while True:
        response = ec2.describe_instance_status(InstanceIds=[INSTANCE_ID], IncludeAllInstances=True)
        state = response['InstanceStatuses'][0]['InstanceState']

        print(f"Status: {state['Code']} - {state['Name']}")

        # If status is 80 ('stopped'), then proceed, else wait 5 seconds and try again
        if state['Code'] == 80:
            break
        else:
            time.sleep(5)