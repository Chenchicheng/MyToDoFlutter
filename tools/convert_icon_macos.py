#!/usr/bin/env python3
"""
将 Windows ICO 图标转换为 macOS 图标集
需要安装 Pillow: pip3 install Pillow
"""

import sys
import os
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("错误: 需要安装 Pillow 库")
    print("请运行: pip3 install Pillow")
    sys.exit(1)

def convert_ico_to_macos_iconset(ico_path, output_dir):
    """将 ICO 文件转换为 macOS 图标集"""
    
    # 读取 ICO 文件
    try:
        ico = Image.open(ico_path)
    except Exception as e:
        print(f"错误: 无法打开 ICO 文件: {e}")
        return False
    
    # macOS 需要的图标尺寸
    sizes = {
        'app_icon_16.png': 16,
        'app_icon_32.png': 32,
        'app_icon_64.png': 64,
        'app_icon_128.png': 128,
        'app_icon_256.png': 256,
        'app_icon_512.png': 512,
        'app_icon_1024.png': 1024,
    }
    
    # 确保输出目录存在
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # 获取 ICO 中最大的图像作为源
    # ICO 文件可能包含多个尺寸
    max_size = 0
    best_image = None
    
    # 尝试获取所有帧（ICO 可能包含多个图像）
    try:
        frames = []
        frame_idx = 0
        while True:
            try:
                ico.seek(frame_idx)
                frames.append(ico.copy())
                frame_idx += 1
            except EOFError:
                break
        
        # 找到最大的图像
        for frame in frames:
            size = max(frame.size)
            if size > max_size:
                max_size = size
                best_image = frame
    except:
        # 如果无法读取多帧，使用当前图像
        best_image = ico.copy()
        max_size = max(best_image.size)
    
    if best_image is None:
        print("错误: 无法从 ICO 文件中提取图像")
        return False
    
    print(f"使用源图像尺寸: {best_image.size}")
    
    # 转换为 RGBA 模式（如果需要）
    if best_image.mode != 'RGBA':
        best_image = best_image.convert('RGBA')
    
    # 生成所有需要的尺寸
    success_count = 0
    for filename, size in sizes.items():
        output_path = output_dir / filename
        
        # 使用高质量重采样
        resized = best_image.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(output_path, 'PNG', optimize=True)
        print(f"✓ 生成 {filename} ({size}x{size})")
        success_count += 1
    
    print(f"\n成功生成 {success_count} 个图标文件到: {output_dir}")
    return True

if __name__ == '__main__':
    # 获取脚本所在目录
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    # 输入和输出路径
    ico_path = project_root / 'windows' / 'runner' / 'resources' / 'app_icon.ico'
    output_dir = project_root / 'macos' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset'
    
    if not ico_path.exists():
        print(f"错误: 找不到 ICO 文件: {ico_path}")
        sys.exit(1)
    
    print(f"输入文件: {ico_path}")
    print(f"输出目录: {output_dir}\n")
    
    if convert_ico_to_macos_iconset(ico_path, output_dir):
        print("\n✓ 图标转换完成！")
        print("现在可以重新构建 macOS 应用:")
        print("  flutter build macos --release")
    else:
        print("\n✗ 图标转换失败")
        sys.exit(1)




