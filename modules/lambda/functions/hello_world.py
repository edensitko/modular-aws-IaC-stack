import json

def lambda_handler(event, context):
    """
    Simple Lambda function that returns a greeting message
    """
    print("Event received:", event)
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Hello from Lambda!',
            'event': event
        })
    }
