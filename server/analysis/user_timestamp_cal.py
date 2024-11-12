

def cal_timestamp(word_intervals) :
    for i, item in enumerate(word_intervals):
    # 첫 번째 단어의 start는 변경하지 않음
        if i != 0 and item['start'] >= 0.01:
            item['start'] = round(item['start'] - 0.01, 3)
        item['end'] = round(item['end'] + 0.01, 3)

    return word_intervals
