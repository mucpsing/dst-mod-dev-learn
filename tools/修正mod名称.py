import os
import re
import shutil


def sanitize_windows_filename(name):
    """
    将名字中 Windows 不允许的字符替换掉
    Windows 不允许字符: \ / : * ? " < > |
    """
    return re.sub(r'[\\/:*?"<>|]', "_", name)


def rename_mod_folders(base_dir):
    """
    遍历 base_dir 的子目录，如果子目录存在 modinfo.lua，
    从中提取 name="xxx"，过滤非法字符，然后重命名子目录。
    """
    if not os.path.isdir(base_dir):
        print(f"{base_dir} 不是一个有效目录")
        return

    for entry in os.listdir(base_dir):
        full_path = os.path.join(base_dir, entry)
        if not os.path.isdir(full_path):
            continue  # 跳过非目录

        modinfo_path = os.path.join(full_path, "modinfo.lua")
        if not os.path.isfile(modinfo_path):
            continue  # 没有 modinfo.lua

        # 读取 modinfo.lua 并匹配 name="xxx"
        try:
            with open(modinfo_path, "r", encoding="utf-8") as f:
                content = f.read()
        except Exception as e:
            print(f"读取 {modinfo_path} 出错: {e}")
            continue

        match = re.search(r'name\s*=\s*"([^"]+)"', content)
        if not match:
            print(f"{modinfo_path} 中未找到 name=xxx")
            continue

        mod_name = match.group(1)
        safe_name = sanitize_windows_filename(mod_name)

        # 如果文件夹名已经是目标名就跳过
        if entry == safe_name:
            print(f"{entry} 已经是安全名，无需重命名")
            continue

        new_path = os.path.join(base_dir, safe_name)

        # 避免重名覆盖
        if os.path.exists(new_path):
            print(f"目标目录 {new_path} 已存在，跳过重命名 {entry}")
            continue

        try:
            shutil.move(full_path, new_path)
            print(f"已重命名 {entry} -> {safe_name}")
        except Exception as e:
            print(f"重命名 {entry} 出错: {e}")


if __name__ == "__main__":
    rename_mod_folders(r"W:\CPS\MyProject\projsect_persional\DST_MOD\dst-mod-lean\refs\mods")
