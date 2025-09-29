import re


def decode_lua_string_expression(expr):
    # 处理字符串表达式：转义序列、string.char、reverse
    parts = re.split(r"\.\.", expr)
    decoded_parts = []
    for part in parts:
        part = part.strip()
        # 处理双引号字符串中的转义序列
        if part.startswith('"') and part.endswith('"'):
            part = part[1:-1]
            part = re.sub(r"\\(\d{1,3})", lambda m: chr(int(m.group(1))), part)
            decoded_parts.append(part)
        # 处理string.char调用
        elif part.startswith("string.char("):
            char_args = re.search(r"string.char\((.*?)\)", part).group(1)
            chars = [chr(int(arg.strip())) for arg in char_args.split(",")]
            s = "".join(chars)
            # 处理可能的reverse
            if ":reverse()" in part:
                s = s[::-1]
            decoded_parts.append(s)
        # 处理已有字符串的reverse
        elif ":reverse()" in part and part.startswith("(") and part.endswith(")"):
            sub_expr = part[1:-10]  # 移除括号和:reverse()
            if sub_expr.startswith('"') and sub_expr.endswith('"'):
                s = sub_expr[1:-1]
                s = re.sub(r"\\(\d{1,3})", lambda m: chr(int(m.group(1))), s)
                s = s[::-1]
                decoded_parts.append(s)
    return "".join(decoded_parts)


# 从原始代码中提取 _L_E__GI_O__N_C0D_E_ 表的内容
original_code = """您的原始代码字符串"""
start = original_code.find("{") + 1
end = original_code.find("}", start)
table_content = original_code[start:end]

# 分割表元素（注意处理括号内的逗号）
elements = []
current = ""
paren_count = 0
for char in table_content:
    if char == "(":
        paren_count += 1
    elif char == ")":
        paren_count -= 1
    if char == "," and paren_count == 0:
        elements.append(current.strip())
        current = ""
    else:
        current += char
if current:
    elements.append(current.strip())

# 解码每个元素
decoded_strings = []
for element in elements:
    decoded_str = decode_lua_string_expression(element)
    decoded_strings.append(decoded_str)

# 替换代码中的索引访问
pattern = r"_L_E__GI_O__N_C0D_E_\[(\d+[^]]*)\]"


def replace_index(match):
    index_expr = match.group(1)
    try:
        index = eval(index_expr)
        return '"{}"'.format(decoded_strings[index])
    except:
        return match.group(0)


decoded_code = re.sub(pattern, replace_index, original_code)

# 保存解码后的代码
with open("format.lua", "w", encoding="utf-8") as f:
    f.write(decoded_code)
