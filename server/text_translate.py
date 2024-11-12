from openai import OpenAI
from server.settings import GPT_KEY

gpt_key = GPT_KEY

def gpt_test (text):
    #print(f"gpt api text : {text}")
    #print(f"key : {GPT_KEY}")
    return text

def gpt_translate (region, text):
    client = OpenAI(api_key = gpt_key)
    completion = client.chat.completions.create(
    model="gpt-4o",
    max_tokens=200,
    messages=[
        { "role" : "system", "content" : region + " 사투리를 표준어로 번역해줘. 번역한 텍스트만을 답해줘."},
        { "role" : "user", "content" : text}
    ])

    print("text_translate.py print : "+ completion.choices[0].message.content)

    return completion.choices[0].message.content


