#!/usr/bin/env python3
"""
AWS Bedrock Nova API 调用脚本
用法：python3 invoke_bedrock.py <model_id> <input.json> <output.json>
"""

import sys
import json
import boto3
from botocore.exceptions import ClientError

def invoke_bedrock(model_id, input_file, output_file):
    try:
        # 读取输入
        with open(input_file, 'r', encoding='utf-8') as f:
            request_body = json.load(f)

        # 创建 Bedrock 客户端
        bedrock = boto3.client(
            service_name='bedrock-runtime',
            region_name='ap-northeast-1'
        )

        # 调用模型
        response = bedrock.invoke_model(
            modelId=model_id,
            body=json.dumps(request_body)
        )

        # 读取响应
        response_body = json.loads(response['body'].read())

        # 写入输出
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(response_body, f, ensure_ascii=False, indent=2)

        print(json.dumps({"success": True, "message": "API call successful"}))
        return 0

    except ClientError as e:
        error_msg = {
            "success": False,
            "error": "AWS API Error",
            "details": str(e)
        }
        print(json.dumps(error_msg))
        return 1

    except Exception as e:
        error_msg = {
            "success": False,
            "error": "Unexpected Error",
            "details": str(e)
        }
        print(json.dumps(error_msg))
        return 1

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 invoke_bedrock.py <model_id> <input.json> <output.json>")
        sys.exit(1)

    model_id = sys.argv[1]
    input_file = sys.argv[2]
    output_file = sys.argv[3]

    sys.exit(invoke_bedrock(model_id, input_file, output_file))
