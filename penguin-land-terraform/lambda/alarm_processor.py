import json
import boto3
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
cloudwatch = boto3.client('cloudwatch')

def calculate_risk_score(alarm_data):
    """
    알람 데이터를 기반으로 위험 점수를 계산 (0-100)
    """
    risk_score = 0
    alarm_name = alarm_data.get('AlarmName', '')
    
    # CPU 알람
    if 'cpu-critical' in alarm_name.lower():
        risk_score += 40
    elif 'cpu-warning' in alarm_name.lower():
        risk_score += 20
    
    # 에러율 알람
    if 'error-critical' in alarm_name.lower():
        risk_score += 35
    elif 'error-warning' in alarm_name.lower():
        risk_score += 15
    
    # 레이턴시 알람
    if 'latency-critical' in alarm_name.lower():
        risk_score += 25
    elif 'latency-warning' in alarm_name.lower():
        risk_score += 10
    
    return min(risk_score, 100)

def get_penguin_status(risk_score):
    """
    위험 점수에 따라 펭귄 상태 결정
    """
    if risk_score <= 30:
        return {
            'status': 'stable',
            'emoji': '😊',
            'color': 'green',
            'message': '👍 아주 안정적이에요!'
        }
    elif risk_score <= 70:
        return {
            'status': 'warning',
            'emoji': '😐',
            'color': 'yellow',
            'message': '⚠️ 조금 불안정해 보여요'
        }
    else:
        return {
            'status': 'critical',
            'emoji': '😢',
            'color': 'red',
            'message': '🚨 CPU가 과열되고 있어요!'
        }

def lambda_handler(event, context):
    """
    SNS에서 CloudWatch 알람을 받아 처리하는 Lambda 함수
    """
    print(f"Received event: {json.dumps(event)}")
    
    try:
        # SNS 메시지 파싱
        for record in event['Records']:
            sns_message = json.loads(record['Sns']['Message'])
            
            # 알람 정보 추출
            alarm_name = sns_message.get('AlarmName', 'Unknown')
            new_state = sns_message.get('NewStateValue', 'UNKNOWN')
            reason = sns_message.get('NewStateReason', '')
            timestamp = sns_message.get('StateChangeTime', datetime.utcnow().isoformat())
            
            print(f"Alarm: {alarm_name}, State: {new_state}")
            
            # 위험 점수 계산
            risk_score = calculate_risk_score(sns_message)
            penguin_status = get_penguin_status(risk_score)
            
            # DynamoDB에 저장
            table_name = os.environ.get('METRICS_TABLE_NAME')
            if table_name:
                table = dynamodb.Table(table_name)
                
                item = {
                    'metric_name': 'alarm_event',
                    'timestamp': int(datetime.utcnow().timestamp()),
                    'alarm_name': alarm_name,
                    'state': new_state,
                    'reason': reason,
                    'risk_score': risk_score,
                    'penguin_status': penguin_status['status'],
                    'penguin_emoji': penguin_status['emoji'],
                    'penguin_color': penguin_status['color'],
                    'penguin_message': penguin_status['message'],
                    'ttl': int(datetime.utcnow().timestamp()) + (7 * 24 * 60 * 60)  # 7일 후 삭제
                }
                
                table.put_item(Item=item)
                print(f"Saved to DynamoDB: {item}")
            
            # CloudWatch 커스텀 메트릭 발행
            namespace = os.environ.get('CLOUDWATCH_NAMESPACE', 'PenguinLand')
            cloudwatch.put_metric_data(
                Namespace=namespace,
                MetricData=[
                    {
                        'MetricName': 'RiskScore',
                        'Value': risk_score,
                        'Unit': 'None',
                        'Timestamp': datetime.utcnow(),
                        'Dimensions': [
                            {
                                'Name': 'SessionId',
                                'Value': os.environ.get('SESSION_ID', 'unknown')
                            }
                        ]
                    }
                ]
            )
            
            print(f"Published metric to CloudWatch: RiskScore={risk_score}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Alarm processed successfully',
                'risk_score': risk_score,
                'penguin_status': penguin_status
            })
        }
    
    except Exception as e:
        print(f"Error processing alarm: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error processing alarm',
                'error': str(e)
            })
        }
