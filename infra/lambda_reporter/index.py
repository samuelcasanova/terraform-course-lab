import boto3
import json
import os
from datetime import datetime

def handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    users_table = dynamodb.Table(os.environ['USERS_TABLE'])
    sessions_table = dynamodb.Table(os.environ['SESSIONS_TABLE'])
    s3 = boto3.client('s3')
    bucket_name = os.environ['ASSETS_BUCKET']

    # 1. Get all sessions and count by email
    sessions_count = {}
    response = sessions_table.scan()
    items = response.get('Items', [])
    while 'LastEvaluatedKey' in response:
        response = sessions_table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
        items.extend(response.get('Items', []))
    
    for item in items:
        email = item.get('email')
        if email:
            sessions_count[email] = sessions_count.get(email, 0) + 1

    # 2. Get all users and build report
    report = []
    response = users_table.scan()
    users = response.get('Items', [])
    while 'LastEvaluatedKey' in response:
        response = users_table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
        users.extend(response.get('Items', []))

    for user in users:
        email = user.get('email')
        # Skip users without email if any
        if not email:
            continue
            
        ratings = user.get('ratings', [])
        num_ratings = len(ratings)
        num_sessions = sessions_count.get(email, 0)
        
        report.append({
            "email": email,
            "sessions_count": num_sessions,
            "ratings_count": num_ratings
        })

    # 3. Save to S3
    timestamp = datetime.now().strftime("%Y-%m-%d-%H%M%S")
    report_json = json.dumps(report, indent=2)
    filename = f"reports/user_report_{timestamp}.json"
    
    s3.put_object(
        Bucket=bucket_name,
        Key=filename,
        Body=report_json,
        ContentType='application/json'
    )

    print(f"Report generated and saved to {bucket_name}/{filename}")

    return {
        'statusCode': 200,
        'body': json.dumps(f'Report generated: {filename}')
    }
