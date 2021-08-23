import boto3
import base64
import redis
import os
import json
from botocore.exceptions import ClientError

session = boto3.session.Session()

def get_secret():

    region_name = os.getenv('region')

    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=os.getenv('secret_id')
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
    
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
    
            raise e
    else:
        
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
            return json.loads(secret)
        else:
            decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])
            return json.loads(decoded_binary_secret)



def handler(event,context):
    redis_secret = get_secret()
    redis_host = os.getenv('redis_endpoint')
    redis_client = redis.Redis(
        host=redis_host,
        port=6379,
        username=redis_secret["redis_rbac_user"],
        password=redis_secret["redis_rbac_user_password"],
        ssl=True
    )
    try:
        redis_client.set('foo', 'bar',)
        # redis_client.get('foo')
        print("Added set bar to fool")
    except Exception as e:
        print(e)
