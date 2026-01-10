import json
import urllib.parse
import boto3

s3 = boto3.client('s3')

def lambda_handler(event, context):
    """
    Lambda function that processes S3 events
    """
    # Get the object from the event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    
    try:
        # Get the object
        response = s3.get_object(Bucket=bucket, Key=key)
        print(f"CONTENT TYPE: {response['ContentType']}")
        print(f"Processing file: {key} from bucket: {bucket}")
        
        # Add your processing logic here
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'File processed successfully',
                'bucket': bucket,
                'key': key
            })
        }
    except Exception as e:
        print(e)
        print(f"Error processing file {key} from bucket {bucket}")
        raise e
