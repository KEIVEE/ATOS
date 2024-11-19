from openai import OpenAI
from server.settings import GPT_KEY

import json

gpt_key = GPT_KEY

def ts_test (text_ts):
    #print(f"gpt api text : {text}")
    #print(f"key : {GPT_KEY}")
    return text_ts

def ts_cal (text_ts, ori_text):
    ts_list = []
    request = ''
    text_ts_str = json.dumps(text_ts, ensure_ascii=False)
    # for ts in text_ts:
    #     request += "단어 : " + ts['word'] + ", 시작 : " + str(ts['start']) + ", 끝 : " + str(ts['end']) + '\n'

    request = "\"" + ori_text + "\" 가 원래 텍스트일 때 타임스탬프 결과야. \n" + text_ts_str #+ "\n타임스탬프에 원래 텍스트와 다른 단어들과 띄어쓰기가 존재하는데 이것을 원래 텍스트와 일치하도록 바꾸고 타임스탬프로 만들어줘."
    # print("타임스탬프 gpt 요청 : " + request)

    client = OpenAI(api_key = gpt_key)
    try:
        completion = client.chat.completions.create(
            model="gpt-4",
            max_tokens=500,
            messages=[
                {
                    "role": "system",
                    "content": "You are a helpful assistant that formats timestamp data to match original text. Please make sure the timestamps match the original text and correct any spacing issues. The timestamps should be in the same format as the JSON I provided, with items containing the names 'word', 'start', and 'end'. Response only the timestamps in JSON format."
                },
                {
                    "role": "user", 
                    "content": request
                }
            ]
        )

        # JSON 응답 파싱
        json_response = json.loads(completion.choices[0].message.content)
        print(json_response)

        # JSON 데이터를 파싱하여 ts_list에 저장
        for item in json_response:
            if item is not None:
                cal_ts = {
                    "word": item.get("word"),
                    "start": item.get("start"),
                    "end": item.get("end")
                }
                #print(cal_ts)
                ts_list.append(cal_ts)
        print('\n\n===============================================================\n\n')
        print(ts_list)
        print('\n\n===============================================================\n\n')
        
    except json.JSONDecodeError:
        print("응답을 JSON으로 변환하는 데 실패했습니다.")
    except Exception as e:
        print(f"API 호출 중 오류 발생: {e}")

    return ts_list
    