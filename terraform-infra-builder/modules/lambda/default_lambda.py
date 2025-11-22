# modules/lambda/default_lambda.py

"""
기본 Lambda 함수 예제
프로젝트 구조에서 source_file이 지정되지 않았을 때 사용됩니다.
"""

import json
import logging

# 로깅 설정
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda 함수의 기본 핸들러
    
    Args:
        event: Lambda 이벤트 객체
        context: Lambda 컨텍스트 객체
    
    Returns:
        dict: HTTP 응답 형식의 딕셔너리
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    # 기본 응답
    response = {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': 'Hello from Default Lambda Function!',
            'event': event,
            'function_name': context.function_name,
            'request_id': context.request_id
        })
    }
    
    logger.info(f"Response: {json.dumps(response)}")
    return response