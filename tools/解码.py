import re


def decode_lua_numbers(path_in: str, path_out: str):
    """
    只解码 Lua 源码中的 \ooo (八进制数字转义)，
    保留其它字符。
    """
    with open(path_in, "r", encoding="utf-8") as f:
        data = f.read()

    # 匹配 \ooo （1~3 位八进制数字）
    def oct_repl(match):
        return chr(int(match.group(1), 8))

    decoded = re.sub(r"\\([0-7]{1,3})", oct_repl, data)

    with open(path_out, "w", encoding="utf-8") as f:
        f.write(decoded)

    print(f"解码完成: {path_out}")


def decode_ascii_file(path_in: str, path_out: str):
    """
    将文件中的 \ooo 八进制 ASCII 序列解码成正常文本。
    """
    with open(path_in, "r", encoding="utf-8") as f:
        data = f.read()

    # 匹配并转换八进制转义
    decoded = re.sub(r"\\([0-7]{1,3})", lambda m: chr(int(m.group(1), 8)), data)

    with open(path_out, "w", encoding="utf-8") as f:
        f.write(decoded)

    print(f"解码完成: {path_out}")


def test(i, o):
    res = ""

    with open(i, "r") as f:
        data = f.read()

        data = data.split("\\")
        data = data[:-1]
        for each in data:
            if len(each) > 0:
                res += chr(int(each))
        print(res)

    with open(o, "w") as f:
        f.write(res)


# 示例用法
if __name__ == "__main__":
    i = r"W:\CPS\MyProject\projsect_persional\DST_MOD\dst-mod-lean\破解\菱镜\modmain.lua"
    o = r"./setp1.lua"

    test(i, o)
